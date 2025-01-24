{ self
, common
, ports
, ...
}:
{ config, pkgs, lib, ... }:

{
  services.borgbackup.jobs.duplo = {
    paths = "/backup";
    preHook = "${import ../../../common/utility.nix}/bin/backups.js aubergine";
    repo = "backup-hsnl-aubergine@duplo:.";
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat /persist/secrets/borg";
    };
    prune.keep = {
      within = "2d";
      daily = 7;
      weekly = 3;
      monthly = 2;
      yearly = 2;
    };
    doInit = true;
    compression = "zstd";
    startAt = "*-*-* 4:00:00";
    extraCreateArgs = "--stats --list --filter=AMEC --info --exclude-if-present .nobackup --keep-exclude-tags --exclude backup-status";
    environment = {
      BORG_BASE_DIR = "/persist/root";
      BORG_RSH = toString
        (pkgs.writeScript "ssh-opts" ''
          #!${pkgs.bash}/bin/bash
          ${pkgs.openssh}/bin/ssh -o ServerAliveInterval=10 -o ServerAliveCountMax=30 "$@"
        '')
        };
    };
  }
