{
	self,
	common,
	ports,
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
			package = import ./package/package.nix;

			webPort = ports.mastodon-web;
			streamingPort = ports.mastodon-streaming;
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
			};
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

					locations."~ ^/api/v1/streaming" = {
						proxyPass = "http://127.0.0.1:${toString(ports.mastodon-streaming)}";
						proxyWebsockets = true;
						extraConfig = ''
							proxy_set_header X-Forwarded-Proto https;
						'';
					};
				};
			};
		};
	};

	systemd.services.mastodon-init-dirs.serviceConfig.StateDirectoryMode = lib.mkOverride 10 "755";
	systemd.services.mastodon-init-db.serviceConfig.StateDirectoryMode = lib.mkOverride 10 "755";
	systemd.services.mastodon-streaming.serviceConfig.StateDirectoryMode = lib.mkOverride 10 "755";
	systemd.services.mastodon-web.serviceConfig.StateDirectoryMode = lib.mkOverride 10 "755";
	systemd.services.mastodon-sidekiq.serviceConfig.StateDirectoryMode = lib.mkOverride 10 "755";

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