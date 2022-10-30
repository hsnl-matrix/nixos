{ config, pkgs, lib, ...}:
{
	time.timeZone = "Europe/Amsterdam";

	i18n.defaultLocale = "en_US.UTF-8";
	console = {
		font = "Lat2-Terminus16";
		keyMap = "us";
	};

	documentation.nixos.enable = false;

  networking = {
		usePredictableInterfaceNames = false;
  };

	security = {
		acme = {
			defaults.email = "acme@cthu.lu";
			acceptTerms = true;
		};
	};

	environment.systemPackages = with pkgs; [ vim ];

	services.openssh.enable = true;
	users.extraUsers.root.openssh.authorizedKeys.keys = [
		"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP5ut6TySQ5gfZppuvYlLGlTtIWH3cSBlEGMY97mnq2F f0x@ouroboros"
	];
}