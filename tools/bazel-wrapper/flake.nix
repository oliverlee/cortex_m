{
  description = "flake defining files needed to bootstrap bazelisk";

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
              diffutils
              findutils
              gnugrep
              gnused
              nix
            ]
            ++ lib.optionals stdenv.isDarwin [
              darwin.cctools
            ];
          rc_line = ''
            common --shell_executable ${pkgs.lib.getExe pkgs.bash}
          '';
        in
        {
          nixos-bazelrc = pkgs.writeText "nixos-${system}.bazelrc" "${rc_line}";

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
