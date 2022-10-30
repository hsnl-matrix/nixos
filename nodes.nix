let
	secrets = (import ./secrets/secrets.nix);
in {
	"perzik" = {config, pkgs, ...}: {
		imports = [
      ./common/all.nix
			nodes/perzik/configuration.nix
		];

		deployment = {
			secrets = secrets.perzik;
			substituteOnDestination = true;
		};
	};
}