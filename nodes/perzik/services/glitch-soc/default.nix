{
	self,
	common,
	ports,
	...
}:
{config, pkgs, lib, ...}:
let
	package = import ./package.nix;
in rec {
	nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "elasticsearch"
  ];

	services = {
		elasticsearch.enable = false; # too much memory

		mastodon = {
			enable = true;
			inherit package;

			webPort = ports.mastodon-web;
			streamingPort = ports.mastodon-streaming;
			enableUnixSocket = false;
			localDomain = "hsnl.social";

			configureNginx = false;

			# elasticsearch = {
			# 	host = "127.0.0.1";
			# };

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
				fromAddress = "hsnl@pixie.town";
				host = "smtp.migadu.com";
				user = "hsnl@pixie.town";
				authenticate = true;
				port = 465;
				passwordFile = "/persist/secrets/migadu";
			};

			extraConfig = {
				AUTHORIZED_FETCH = "true";
				BIND = "127.0.0.1";
				SINGLE_USER_MODE = "false";
				DEFAULT_LOCALE = "en";

				SMTP_SSL = "true";

				# TODO: Don't?
				# RAILS_SERVE_STATIC_FILES = "true";
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

					root = "${services.mastodon.package}/public/";

					locations."/system/".alias = "/persist/mastodon/public-system/";

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

					locations."/api/v1/streaming/" = {
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