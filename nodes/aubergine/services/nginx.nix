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
			# "matrix-test.hsnl.im" = {
			#  	enableACME = true;
			# 	forceSSL = true;

			#  	locations."/" = {
			# 		proxyPass = "http://127.0.0.1:8008";
			# 		proxyWebsockets = true;
			# 		extraConfig = ''
			# 			proxy_set_header Host $host;
			# 		'';
			# 	};

			# 	locations."= /.well-known/matrix/server".extraConfig = ''
			# 		add_header Content-Type application/json;
			# 		return 200 '{\"m.server\": \"matrix-test.hsnl.im:443\"}';
			# 	'';

			# 	locations."= /.well-known/matrix/client".extraConfig = ''
			# 		add_header Content-Type application/json;
			# 		add_header Access-Control-Allow-Origin *;
			# 		return 200 '{\"m.homeserver\": {\"base_url\": \"https://matrix-test.hsnl.im\"}}';
			# 	'';
			# };
		};
	};
}