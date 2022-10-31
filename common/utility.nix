with import <nixpkgs> {};

stdenv.mkDerivation rec {
	pname = "f0x-utility";
	version = "0.0.4";
	src = pkgs.fetchgit {
		url = "https://git.pixie.town/f0x/utility";
		rev = "f0c9b425f62871a63244c4790ae7885e5dd7a2e8";
		sha256 = "tDzHzIiW+OU1+e+BWUdgi/TH8AdgRPLL2fpW6lmVUG4=";
	};

	buildInputs = [nodejs];

	dontConfigure = true;
	dontBuild = true;

	installPhase = ''
		mkdir -p $out/bin
		mv * $out/bin/
	'';
}