{config, pkgs, lib, ...}:
{
	boot = {
		initrd.postDeviceCommands = lib.mkAfter ''
			zfs rollback -r pool/local/root@blank
		'';

		# the backup systemd unit won't be allowed to start without it
		postBootCommands = lib.mkAfter ''
			mkdir /backup
		'';
	};
}