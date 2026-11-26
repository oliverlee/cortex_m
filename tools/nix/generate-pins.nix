# The store path of each flake output for each system, and a hash of each flake
# that consumers compare to detect stale pins.
{
  # A directory with tools/nix/flake.nix and the bazel-wrapper flake.
  nixDir,
}:
let
  pins =
    dir:
    let
      flake = builtins.getFlake "path:${dir}";
    in
    {
      hash = (import ./pins.nix).hash dir;
      paths = builtins.mapAttrs (
        _system: builtins.mapAttrs (_output: package: package.outPath)
      ) flake.packages;
    };
in
{
  bazel-wrapper = pins "${nixDir}/bazel-wrapper";
  packages = pins nixDir;
}
