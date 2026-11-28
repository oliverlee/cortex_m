rec {
  # The hash recorded with the pins of the flake in directory `dir`.
  hash =
    dir:
    builtins.hashString "sha1" (
      builtins.readFile "${dir}/flake.lock" + builtins.readFile "${dir}/flake.nix"
    );

  # The pinned store path of flake output `output` for this system. Throws if
  # the pins of `group` in `pinsFile` don't match the flake in `dir`.
  path =
    {
      pinsFile,
      group,
      dir,
      output,
    }:
    let
      pins = (builtins.fromJSON (builtins.readFile pinsFile)).${group};
    in
    if pins.hash != hash dir then
      throw "ignoring stale ${pinsFile}"
    else
      pins.paths.${builtins.currentSystem}.${output};
}
