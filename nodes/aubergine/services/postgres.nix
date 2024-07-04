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
				ensureDBOwnership = true;
			};
		in (map userWithPermissions usersWithDatabases));

		settings = {
			"shared_preload_libraries" = "pg_stat_statements";
			"pg_stat_statements.track" = "all";

			# pgtune
			"max_connections" = "200";
			"shared_buffers" = "2GB";
			"effective_cache_size" = "6GB";
			"maintenance_work_mem" = "512MB";
			"checkpoint_completion_target" = "0.9";
			"wal_buffers" = "16MB";
			"default_statistics_target" = "100";
			"random_page_cost" = "1.1";
			"effective_io_concurrency" = "200";
			"work_mem" = "5242kB";
			"min_wal_size" = "1GB";
			"max_wal_size" = "4GB";
			"max_worker_processes" = "4";
			"max_parallel_workers_per_gather" = "2";
			"max_parallel_workers" = "4";
			"max_parallel_maintenance_workers" = "2";
		};
	};
}
