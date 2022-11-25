{
	self,
	common,
	ports,
	...
}:
{config, pkgs, lib, ...}:
{
	services.nginx = {
		enable = true;
		virtualHosts = {
			"element.hsnl.im" = {
				enableACME = true;
				forceSSL = true;
				root = pkgs.element-web.override {
					conf = {
						default_server_config."m.homeserver" = {
							"base_url" = "https://matrix-test.hsnl.im";
							"server_name" = "HSNL";
						};
						showLabsSettings = true;
						branding = {
						brand = "👾💬";
								welcomeBackgroundUrl = "/powerlines-dark.png";
								# authfooterLinks = [{text = "pixie.town"; url = "https://pixie.town";}];
							};
							default_theme = "dark";
						};
					};

				locations."/powerlines-dark.png" = {
					root = "/persist/nginx/";
				};
			};
		};
	};
}