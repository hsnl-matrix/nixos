let
  nixpkgs = import <nixpkgs> { };
  nixpkgsVersions = import ./versions.nix;
  versionedNixpkgs = import ./lib/versioned-nixpkgs.nix { lib = nixpkgs.lib; inherit nixpkgsVersions; };

  allNodes = (import ./lib/read-nodes.nix) { lib = nixpkgs.lib; };
  nodesWithVersions = versionedNixpkgs allNodes;
in
{
  meta = {
    inherit nixpkgs; # default
    nodeNixpkgs = nodesWithVersions;
  };

  defaults = { pkgs, lib, name, nodes, ... }:
    let _info = allNodes."${name}"; in {
      imports = [
        ./presets/all.nix
        (./nodes/. + "/${name}/configuration.nix")
      ];

      deployment = {
        targetHost = _info.endpoint;
        keys = import (./secrets/. + "/${name}.nix");
      };

      _module.args = {
        _info = _info;
        _nodes = builtins.mapAttrs (hostName: node: (node // { config = nodes."${name}".config; })) allNodes;
      };
    };

  aubergine = { };
}
