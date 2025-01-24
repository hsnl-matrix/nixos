{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../presets/network/procolix.nix
    ../../presets/network/firewall.nix

    ./services/backups.nix
    ./services/glitch-soc
  ];

  boot = {
    loader.grub = {
      device = "/dev/xvda";
      enable = true;
    };

    zfs.devNodes = "/dev/disk/by-partuuid";
  };

  presets = {
    erase-your-darlings = {
      enable = true;
      rootPool = "pool/volatile";
    };

    postgres = {
      package = pkgs.postgresql_14;
      databases = [ "glitch-soc" ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  services.postgresql.settings = {
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

  services.xe-guest-utilities.enable = true;

  system.stateVersion = "22.05";
}
