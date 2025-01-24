{ config, lib, ... }:
let
  cfg = config.presets.erase-your-darlings;
in
{
  options.presets.erase-your-darlings = {
    enable = lib.mkEnableOption "Erase your darlings";
    rootPool = lib.mkOption
      {
        type = lib.types.str;
        default = "pool/volatile";
      };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      initrd.postDeviceCommands = lib.mkAfter ''
        zfs rollback -r ${cfg.rootPool}/root@blank
      '';

      # the backup systemd unit won't start without it
      postBootCommands = lib.mkAfter ''
        mkdir /backup
      '';
    };
  };
}
