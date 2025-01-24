{ lib, nixpkgsVersions }: allNodes:
let
  versionedNodes = (
    builtins.listToAttrs (builtins.concatLists (
      lib.attrsets.mapAttrsToList
        (version: details: (
          builtins.map
            (node: {
              name = node;
              # value = versionedImport version { ref = details.ref; sha256 = details.sha256 ? "none"; };
              value = import
                (
                  if (details ? "sha256") then
                    (
                      builtins.fetchTarball {
                        name = version;
                        sha256 = details.sha256;
                        url = "https://github.com/NixOS/nixpkgs/tarball/${details.ref}";
                      }
                    ) else
                    (
                      builtins.fetchTarball {
                        name = version;
                        url = "https://github.com/NixOS/nixpkgs/tarball/${details.ref}";
                      }
                    )
                )
                { };
            })
            (details.nodes or [ ])
        ))
        nixpkgsVersions
    )));
  warnUnconfiguredNodes = builtins.filter (node: if (builtins.hasAttr node versionedNodes) then true else (lib.trivial.warn "Node ${node} has no nixpkgs version configured" false)) (builtins.attrNames allNodes);
in
builtins.listToAttrs (builtins.map (node: (lib.nameValuePair node (versionedNodes."${node}"))) warnUnconfiguredNodes)
