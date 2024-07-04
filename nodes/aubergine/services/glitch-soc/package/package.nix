{pkgs, ...}:
with pkgs;
let 
	pname = "glitch-soc";
	version = import ./version.nix;
	dependenciesDir = ./.;
  semiSecrets = import ../../../../../semi-secrets.nix;
in stdenv.mkDerivation rec {
  inherit pname version;

  # Using overrideAttrs on src does not build the gems and modules with the overridden src.
  # Putting the callPackage up in the arguments list also does not work.
  src = callPackage ./source.nix {};

  mastodonGems = bundlerEnv {
    name = "${pname}-gems-${version}";
    inherit version;
    ruby = ruby_3_3;
    gemdir = src;
    gemset = dependenciesDir + "/gemset.nix";
    # This fix (copied from https://github.com/NixOS/nixpkgs/pull/76765) replaces the gem
    # symlinks with directories, resolving this error when running rake:
    #   /nix/store/451rhxkggw53h7253izpbq55nrhs7iv0-mastodon-gems-3.0.1/lib/ruby/gems/2.6.0/gems/bundler-1.17.3/lib/bundler/settings.rb:6:in `<module:Bundler>': uninitialized constant Bundler::Settings (NameError)
    postBuild = ''
      for gem in "$out"/lib/ruby/gems/*/gems/*; do
        cp -a "$gem/" "$gem.new"
        rm "$gem"
        # needed on macOS, otherwise the mv yields permission denied
        chmod +w "$gem.new"
        mv "$gem.new" "$gem"
      done
    '';
  };

  mastodonModules = stdenv.mkDerivation ({
    pname = "${pname}-modules";
    inherit src version;

    # use the fixed yarn berry offline cache thingy
    yarnOfflineCache = callPackage ./yarn.nix {
      inherit src;
      hash = "sha256-U/0A1lIgUjkDjHgxr7x4+XBN4Ndpf2AEC6nenpqv90k=";
    };

    nativeBuildInputs = [ nodejs-slim yarn-berry mastodonGems mastodonGems.wrappedRuby brotli ];

    RAILS_ENV = "production";
    NODE_ENV = "production";

    buildPhase = ''
      runHook preBuild

      export HOME=$PWD
      # This option is needed for openssl-3 compatibility
      # Otherwise we encounter this upstream issue: https://github.com/mastodon/mastodon/issues/17924
      export NODE_OPTIONS=--openssl-legacy-provider

      export YARN_ENABLE_TELEMETRY=0
      mkdir -p ~/.yarn/berry
      ln -sf $yarnOfflineCache ~/.yarn/berry/cache

      yarn install --immutable --immutable-cache

      patchShebangs ~/bin
      patchShebangs ~/node_modules

      # skip running yarn install
      rm -rf ~/bin/yarn

      OTP_SECRET=precompile_placeholder SECRET_KEY_BASE=precompile_placeholder \
        rails assets:precompile
      yarn cache clean
      rm -rf ~/node_modules/.cache

      # Create missing static gzip and brotli files
      gzip --best --keep ~/public/assets/500.html
      gzip --best --keep ~/public/packs/report.html
      find ~/public/assets -maxdepth 1 -type f -name '.*.json' \
        -exec gzip --best --keep --force {} ';'
      brotli --best --keep ~/public/packs/report.html
      find ~/public/assets -type f -regextype posix-extended -iregex '.*\.(css|js|json|html)' \
        -exec brotli --best --keep {} ';'

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/public
      cp -r node_modules $out/node_modules
      cp -r public/assets $out/public
      cp -r public/packs $out/public

      runHook postInstall
    '';
  }  // semiSecrets.mastodon.active_record_encryption);

  propagatedBuildInputs = [ imagemagick ffmpeg file mastodonGems.wrappedRuby ];
  buildInputs = [ mastodonGems nodejs-slim ];

  buildPhase = ''
    ln -s ${mastodonModules}/node_modules node_modules
    ln -s ${mastodonModules}/public/assets public/assets
    ln -s ${mastodonModules}/public/packs public/packs
    patchShebangs bin/
    for b in $(ls ${mastodonGems}/bin/)
    do
      if [ ! -f bin/$b ]; then
        ln -s ${mastodonGems}/bin/$b bin/$b
      fi
    done
    rm -rf log
    ln -s /var/log/mastodon log
    ln -s /tmp tmp
  '';

  installPhase = let
    run-streaming = writeShellScript "run-streaming.sh" ''
      # NixOS helper script to consistently use the same NodeJS version the package was built with.
      ${nodejs-slim}/bin/node ./streaming
    '';
  in ''
    mkdir -p $out
    cp -r * $out/
    ln -s ${run-streaming} $out/run-streaming.sh
  '';

  passthru = {
    tests.mastodon = nixosTests.mastodon;
    updateScript = callPackage ./update.nix {};
  };

  meta = with lib; {
    description = "Self-hosted, globally interconnected microblogging software based on ActivityPub";
    homepage = "https://joinmastodon.org";
    license = licenses.agpl3Plus;
    platforms = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
    maintainers = with maintainers; [ petabyteboy happy-river erictapen izorkin ];
  };
}
