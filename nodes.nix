let
	secrets = (import ./secrets/secrets.nix);
in {
	"aubergine" = {config, pkgs, ...}: {
		imports = [
			./common/all.nix
			nodes/aubergine/configuration.nix
		];

		deployment = {
			secrets = secrets.aubergine;
			substituteOnDestination = true;
		};
	};

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