{
  description = "flake defining files needed to bootstrap bazelisk";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          libs = with pkgs; [
            libxml2
            libz
          ];
          tools =
            with pkgs;
            [
              bash
              bazelisk
              coreutils
              findutils
              gawk
              gnugrep
              gnused
              nix
            ]
            ++ lib.optionals stdenv.isDarwin [
              darwin.cctools
            ];
        in
        {
          host-bazelrc = pkgs.writeText "host-${system}.bazelrc" ''
            common --shell_executable ${pkgs.lib.getExe pkgs.bash}
          '';

          default = pkgs.writeShellApplication {
            name = "bazel-wrapper";
            runtimeInputs = tools;
            inheritPath = false;
            text = ''
              export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath libs}"
              exec bazelisk "$@"
            '';
          };
        }
      );
    };
}
