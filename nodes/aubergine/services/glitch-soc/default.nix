{ config, pkgs, lib, _info, ... }:

rec {
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "elasticsearch"
  ];

  services = {
    elasticsearch = {
      enable = true;
      package = pkgs.elasticsearch7;
    };

    mastodon = {
      enable = true;
      package = pkgs.callPackage ./package { };
      # package = pkgs.callPackage ./package/package.nix { };
      # package = (pkgs.mastodon.override {
      #   yarnHash = "sha256-IC4d/skIHEzJPuKlq4rMAqV+ydqquA6toq4WWCfuDxo=";
      # }).overrideAttrs
      #   (final: prev: rec {
      #     pname = "glitch-soc";
      #     version = "v4.4.1";
      #     src = pkgs.callPackage ./package/source.nix { };
      #     gemset = ./package/gemset.nix;

      #     mastodonGems = pkgs.bundlerEnv
      #       {
      #         name = "${pname}-gems-${version}";
      #         inherit version gemset;
      #         ruby = pkgs.ruby;
      #         gemdir = src;

      #         gemConfig = pkgs.defaultGemConfig // {
      #           hiredis-client = attrs: {
      #             buildInputs = [ pkgs.openssl ];
      #           };
      #         };
      #       };
      #   });

      localDomain = "hsnl.social";
      webPort = _info.ports.mastodon-web;
      streamingProcesses = 3;
      enableUnixSocket = false;

      configureNginx = false;

      elasticsearch = {
        host = "127.0.0.1";
      };

      redis = {
        createLocally = false;
        port = _info.ports.mastodon-redis;
      };

      database = {
        createLocally = false;
        user = "glitch-soc";
        name = "glitch-soc";
        host = "/var/run/postgresql";
        passwordFile = "/dev/null";
      };

      user = "glitch-soc";
      group = "glitch-soc";

      smtp = {
        createLocally = false;
        fromAddress = "no-reply@hsnl.social";
        host = "smtp.migadu.com";
        # host = "127.0.0.1";
        port = 465;
        user = "no-reply@hsnl.social";
        authenticate = true;
        passwordFile = "/persist/secrets/migadu";
      };

      webProcesses = 8;
      sidekiqThreads = 42;

      extraConfig = {
        AUTHORIZED_FETCH = "true";
        BIND = "127.0.0.1";
        SINGLE_USER_MODE = "false";
        DEFAULT_LOCALE = "en";
        SMTP_SSL = "true";

        MAX_TOOT_CHARS = "4096";
        MAX_BIO_CHARS = "2048";
        MAX_PINNED_TOOTS = "8";
        MAX_POLL_OPTIONS = "16";
        MAX_POLL_OPTION_CHARS = "512";
        MAX_MEDIA_DESC_CHARS = "4096";
      };

      extraEnvFiles = [
        # active record encryption key/salt
        "/persist/secrets/mastodon-env"
      ];
    };

    redis.servers.mastodon = {
      enable = true;
      port = _info.ports.mastodon-redis;
      appendOnly = true;
    };

    nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts = {
        "hsnl.social" = {
          enableACME = true;
          forceSSL = true;

          extraConfig = "client_max_body_size 40m;";

          root = "${services.mastodon.package}/public/";

          locations."/system/".alias = "/persist/mastodon-public/";

          locations."/" = {
            tryFiles = "$uri @proxy";
          };

          locations."@proxy" = {
            proxyPass = "http://127.0.0.1:${toString(_info.ports.mastodon-web)}";
            proxyWebsockets = true;
            extraConfig = ''
              							proxy_set_header X-Forwarded-Proto https;
              						'';
          };

          locations."/api/v1/streaming" = {
            proxyPass = "http://mastodon-streaming";
            proxyWebsockets = true;
          };
        };
      };
      upstreams.mastodon-streaming = {
        extraConfig = ''
          least_conn;
        '';
        servers = builtins.listToAttrs
          (map
            (i: {
              name = "unix:/run/mastodon-streaming/streaming-${toString i}.socket";
              value = { };
            })
            (lib.range 1 services.mastodon.streamingProcesses));
      };
    };
  };

  systemd.services =
    let
      serviceOverride = {
        StateDirectoryMode = lib.mkOverride 10 "755";
        ReadWritePaths = [ "/persist/mastodon-public" "/persist/mastodon" ];
      };
    in
    {
      mastodon-init-dirs.serviceConfig = serviceOverride;
      mastodon-init-db.serviceConfig = serviceOverride;
      # mastodon-streaming.serviceConfig = serviceOverride;
      mastodon-web.serviceConfig = serviceOverride;
      mastodon-sidekiq-all.serviceConfig = serviceOverride;
    };

  users = {
    users.glitch-soc = {
      isNormalUser = lib.mkOverride 10 true;
      home = "/persist/mastodon";
      group = "glitch-soc";
    };
    groups.glitch-soc.members = [
      config.services.nginx.user
    ];
  };

  fileSystems."/var/lib/mastodon" = {
    device = "/persist/mastodon";
    options = [ "bind" ];
  };

  fileSystems."/var/lib/redis-mastodon" = {
    device = "/persist/mastodon/redis";
    options = [ "bind" ];
  };

  fileSystems."/var/lib/elasticsearch" = {
    device = "/persist/mastodon/elasticsearch";
    options = [ "bind" ];
  };
}
