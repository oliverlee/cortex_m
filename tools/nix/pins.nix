rec {
  # The hash recorded with the pins of the flake in directory `dir`.
  hash =
    dir:
    builtins.hashString "sha1" (
      builtins.readFile "${dir}/flake.lock" + builtins.readFile "${dir}/flake.nix"
    );

  # The pinned store path of each output of the flake in directory `dir` for
  # this system. Throws if the pins of `group` in `pinsFile` don't match the
  # flake.
  paths =
    {
      pinsFile,
      group,
      dir,
    }:
    let
      pins = (builtins.fromJSON (builtins.readFile pinsFile)).${group};
    in
    if pins.hash != hash dir then
      throw "ignoring stale ${pinsFile}"
    else
      pins.paths.${builtins.currentSystem};

  # The pinned store path of flake output `output` for this system.
  path =
    {
      pinsFile,
      group,
      dir,
      output,
    }:
    (paths { inherit pinsFile group dir; }).${output};
}
