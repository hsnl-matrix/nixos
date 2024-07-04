{
	self,
	common,
	ports,
	semiSecrets,
	...
}:
{config, pkgs, lib, ...}:

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
			# package = pkgs.mastodon;
			package = pkgs.callPackage ./package/package.nix {};
			# package = pkgs.mastodon.override {
			# 	pname = "glitch-soc";
			# 	version = "v4.5.7";
			# 	srcOverride = pkgs.callPackage ./package/source.nix {};
			# 	yarnHash = "sha256-qoLesubmSvRsXhKwMEWHHXcpcqRszqcdZgHQqnTpNPE=";
			# 	gemset = ./package/gemset.nix;
			# };
			# package = pkgs.mastodon.override {
			# 	pname = "glitch-soc";
			# 	version = "v4.5.2";
			# 	srcOverride = pkgs.callPackage ./package/source.nix {};
			# 	yarnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
			# 	gemset = ./package/gemset.nix;
			# };

			webPort = ports.mastodon-web;
			# streamingPort = ports.mastodon-streaming;
			streamingProcesses = 3;
			enableUnixSocket = false;
			localDomain = "hsnl.social";

			configureNginx = false;

			elasticsearch = {
				host = "127.0.0.1";
			};

			redis = {
				createLocally = false;
				port = ports.mastodon-redis;
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
			} // semiSecrets.mastodon.active_record_encryption;
		};

		redis.servers.mastodon = {
			enable = true;
			port = ports.mastodon-redis;
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
						proxyPass = "http://127.0.0.1:${toString(ports.mastodon-web)}";
						proxyWebsockets = true;
						extraConfig = ''
							proxy_set_header X-Forwarded-Proto https;
						'';
					};

					locations."/api/v1/streaming" = {
						proxyPass = "http://mastodon-streaming";
          	proxyWebsockets = true;
						# proxyPass = "http://127.0.0.1:${toString(ports.mastodon-streaming)}";
						# proxyWebsockets = true;
						# extraConfig = ''
						# 	proxy_set_header X-Forwarded-Proto https;
						# '';
					};
				};
			};
			upstreams.mastodon-streaming = {
        extraConfig = ''
          least_conn;
        '';
        servers = builtins.listToAttrs
          (map (i: {
            name = "unix:/run/mastodon-streaming/streaming-${toString i}.socket";
            value = { };
          }) (lib.range 1 services.mastodon.streamingProcesses));
      };
		};
	};

	systemd.services = let
		serviceOverride = {
			StateDirectoryMode = lib.mkOverride 10 "755";
			ReadWritePaths = ["/persist/mastodon-public"];
		};
	in {
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
