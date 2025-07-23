#!/usr/bin/env bash

VERSION="nixos-${1:-25.05}"
REPO="https://github.com/NixOS/nixpkgs"

DATE=$(date +%Y-%m-%d_%H-%M-%S)

echo "updating <$VERSION>"
REF=$(git ls-remote $REPO $VERSION | cut -f1)

echo "latest commit: $REF"
if [ -f ./nixpkgs.nix ]; then
	OLD_REF=$(sed -n '2p' ./nixpkgs.nix | cut -d" " -f2)
	if [ "$REF" = "$OLD_REF" ]; then 
		echo "nothing newer than $REF, exiting."
		exit 1
	fi
fi

TAR_URL="$REPO/archive/$REF.tar.gz"

VERSION_STR="$(echo $VERSION | cut -c 7-)-$(echo $REF | cut -c -6)"

HASH=$(nix-prefetch-url --unpack $TAR_URL --name $VERSION_STR)

echo "hash: $HASH"

cat << EOF

  "$VERSION_STR" = {
	  # $DATE
    ref = "$REF";
    sha256 = "$HASH";
		nodes = [ ];
  };
EOF
