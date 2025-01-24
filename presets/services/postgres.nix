{ pkgs, lib, config, ... }:
let
  cfg = config.presets.postgres;
in
{
  options.presets.postgres = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.postgresql_15;
    };
    databases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf (builtins.length cfg.databases > 0) {
    services.postgresql = {
      enable = true;
      package = cfg.package;
      dataDir = "/persist/postgres";
      ensureDatabases = cfg.databases;
      ensureUsers = (map
        (name: {
          inherit name;
          ensureDBOwnership = true;
        })
        cfg.databases);
    };
  };
}
