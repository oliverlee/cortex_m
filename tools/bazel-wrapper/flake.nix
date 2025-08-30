{
  description = "flake defining the repo dev shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          tools =
            with pkgs;
            [
              bash
              bazelisk
              coreutils
              findutils
              gnugrep
              gnused
              nix
            ]
            ++ lib.optionals stdenv.isDarwin [
              darwin.cctools
            ];
        in
        {
          default = pkgs.writeShellApplication {
            name = "bazel-wrapper";
            runtimeInputs = tools;
            inheritPath = false;
            text = ''
              exec bazelisk "$@"
            '';
          };
        }
      );
    };
}
