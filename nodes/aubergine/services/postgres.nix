{
	self,
	ports,
	semiSecrets,
	...
}:
{config, pkgs, lib, ...}: 

let
	usersWithDatabases = ["glitch-soc" "dex"];
in {
	services.postgresql = {
		enable = true;
		dataDir = "/persist/postgres";
		initialScript = pkgs.writeText "synapse-init.sql" ''
				CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
				CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
					TEMPLATE template0
					LC_COLLATE = "C"
					LC_CTYPE = "C";
			'';

		ensureDatabases = usersWithDatabases;
		ensureUsers = (let 
			userWithPermissions = user: {
				name = user;
				ensurePermissions = {
					"DATABASE \"${user}\"" = "ALL PRIVILEGES";
				};
			};
		in (map userWithPermissions usersWithDatabases));
	};
}
