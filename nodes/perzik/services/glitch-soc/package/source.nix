# This file was generated by pkgs.mastodon.updateScript.
{ fetchgit, applyPatches }: let
  src = fetchgit {
    url = "https://github.com/glitch-soc/mastodon.git";
    rev = "43dbc6256854a9832c7255fc62a8fa8df7244dd6";
    sha256 = "11mfjbv6gn61g3ivny7cjc3plfhk2ypz9l0729v0zsla22ci1jf0";
  };
in applyPatches {
  inherit src;
  patches = [];
}
