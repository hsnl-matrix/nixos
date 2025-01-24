{ lib, ... }:
let
  listDirectory = dir: (lib.attrsets.mapAttrsToList (name: type: { inherit name type; }) (builtins.readDir dir));
  filterType = type: l: builtins.catAttrs "name" (builtins.filter (a: a.type == type) l);
in
(builtins.listToAttrs (builtins.filter (a: (a.value ? "hostId")) (
  map
    (dir: lib.nameValuePair "${dir}" (
      let path = (../nodes + "/${dir}/info.nix"); in
      if (builtins.pathExists path) then
        (
          let
            info = import path;
          in
          (info) // {
            hostName = dir;
            endpoint = if (info ? "endpoint") then info.endpoint else builtins.throw "Node ${dir} has no endpoint defined in info.nix";
          }
        )
      else { }
    ))
    (filterType "directory" (listDirectory ../nodes))
)))
