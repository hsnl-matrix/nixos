{ pkgs, ... }: with pkgs; stdenv.mkDerivation rec {
  pname = "f0x-utility";
  version = "0.0.4-1";
  src = fetchgit {
    url = "https://git.pixie.town/f0x/utility";
    rev = "22f5df95490e070d5fcb56545747c0bc78bfc6b5";
    sha256 = "sha256-LIdpag6GboPxuOBWDKmM5i1bzoPwXSESfJbBuigNKVM=";
  };

  buildInputs = [ nodejs ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    mv * $out/bin/
  '';
}
