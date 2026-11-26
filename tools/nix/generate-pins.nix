# The store path of each output of the bazel-wrapper flake for each system, and
# a hash of the flake that consumers compare to detect stale pins.
{
  # A directory with the bazel-wrapper flake.
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
}
