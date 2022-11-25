{
	self,
	common,
	ports,
	...
}:
{config, pkgs, lib, ...}:

{
	services.borgbackup.jobs.copia = {
		paths = "/backup";
		readWritePaths = ["/backup"];
		preHook = "${import ../../../common/utility.nix}/bin/backups.js aubergine";
		repo = "hsnl-aubergine-backup@copia.pixie.town:.";
		encryption = {
			mode = "repokey-blake2";
			passCommand = "cat /persist/secrets/borg";
		};
		doInit = true;
		compression = "zstd";
		startAt = "*-*-* 4:00:00";
		extraCreateArgs = "--stats --list --info --exclude-if-present .nobackup --keep-exclude-tags --exclude backup-status";
	};
}