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

	fileSystems."/var/lib/acme" = {
		device = "/persist/ssl";
		options = [ "bind" ];
	};

	services.openssh.hostKeys = [
		{
			path = "/persist/ssh/ed25519_key";
			type = "ed25519";
		}
		{
			path = "/persist/ssh/rsa_key";
			type = "rsa";
			bits = 4096;
		}
	];

	users.extraUsers.root.home = lib.mkOverride 10 "/persist/root";
}