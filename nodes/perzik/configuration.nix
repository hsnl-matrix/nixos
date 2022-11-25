{ config, pkgs, lib, ... }:

let
	self = import ./info.nix;
	semiSecrets = import ../../semi-secrets.nix;
in {
	imports = [
		./hardware-configuration.nix
		../../common/erase-your-darlings.nix
	] ++ (map (path: (import path) {
		inherit self;
		inherit semiSecrets;
		common = import ../../common;
		ports = self.ports;
	}) [
		../../common/networking/hetzner.nix

		# ./services/glitch-soc

		# ./services/backups.nix
		./services/nginx.nix
		# ./services/synapse.nix
		# ./services/postgres.nix
	]);

	boot = {
		kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
		loader.grub = {
			device = "/dev/sda";
			enable = true;
			version = 2;
		};
	};

	# networking.firewall.enable = false;
	networking.firewall.allowedTCPPorts = [ 80 443 ];

	# This value determines the NixOS release from which the default
	# settings for stateful data, like file locations and database versions
	# on your system were taken. It‘s perfectly fine and recommended to leave
	# this value at the release version of the first install of this system.
	# Before changing this value read the documentation for this option
	# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
	system.stateVersion = "22.05"; # Did you read the comment?
}