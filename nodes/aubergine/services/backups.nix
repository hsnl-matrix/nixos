{ config, pkgs, lib, ... }:

let
  makeBackupScript = server: pkgs.resholve.writeScript "backup-${server}-preHook"
    {
      inputs = with pkgs; [ coreutils util-linux zfs gnugrep gnused ];
      interpreter = "${pkgs.bash}/bin/bash";
      fix = {
        mount = true;
        umount = true;
      };
      execer = [ "cannot:${pkgs.zfs}/bin/zfs" ];
    } ''
    set -e

    echo "preparing for backup to '${server}'"

    mkdir -p /backup/${server}
    umount -R /backup/${server}/* || true

    zfs list -H -o name -t filesystem | grep safe/ | while read FS; do
      echo "renewing snapshot for $FS"
      zfs destroy "$FS@backup-${server}" || true
      zfs snapshot "$FS@backup-${server}"
    
      NAME=$(echo "$FS" | sed "s/\//_/g")
      echo "mounting $FS to /backup/${server}/$NAME"
      mkdir -p "/backup/${server}/$NAME"
      mount -t zfs "$FS@backup-${server}" "/backup/${server}/$NAME"
    done
  '';
in
{
  services.postgresqlBackup = {
    enable = true;
    startAt = "*-*-* 02:15:00";
    location = "/backup/postgres";
    compression = "none";
  };

  services.borgbackup.jobs.duplo = {
    preHook = toString (makeBackupScript "duplo");
    repo = "backup-hsnl-aubergine@duplo.pixie.town:.";
    paths = [ "/backup/duplo" "/backup/postgres" ];
    readWritePaths = [ "/backup/duplo" ];
    exclude = [
      "/backup/duplo/pool_safe_persist/postgres" # backed up as postgresqlBackup export instead
    ];
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
        (pkgs.writeShellScript "ssh-opts" ''
          ${pkgs.openssh}/bin/ssh -o ServerAliveInterval=10 -o ServerAliveCountMax=30 "$@"
        '');
    };
  };
}
