{
  description = "flake defining apps run in garnix ci";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      apps = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          bazel-fhs = pkgs.buildFHSEnv {
            name = "bazel-fhs";
            targetPkgs =
              pkgs: with pkgs; [
                bash
                bazelisk
                coreutils
                nix
                libz # needed by bazel binaries
              ];
            runScript = "bash";
            profile = ''
              # /etc/os-release needed for toolchains_llvm
              # https://github.com/bazel-contrib/toolchains_llvm/blob/master/toolchain/internal/common.bzl#L90-L112
              mkdir -p /etc
              cat > /etc/os-release << EOF
              NAME="NixOS"
              ID="nixos"
              ID_LIKE="nixos"
              PRETTY_NAME="NixOS"
              EOF
            '';
          };

          bazel-app =
            name: command:
            let
              src = pkgs.lib.fileset.toSource {
                root = ./.;
                fileset = pkgs.lib.fileset.gitTracked ./.;
              };
            in
            {
              type = "app";
              program = "${
                pkgs.writeShellApplication {
                  name = "${name}";
                  runtimeInputs = [ bazel-fhs ];
                  text = ''
                    cp -r --no-preserve=mode,ownership "${src}/." cortex_m/
                    cd cortex_m
                    cp .github/workflows/ci.bazelrc ~/.bazelrc

                    cat >> ~/.bazelrc << EOF
                    # https://github.com/bazelbuild/bazel/issues/23522
                    common --curses=yes
                    build --build_metadata=REPO_URL=https://github.com/oliverlee/cortex_m
                    build --build_metadata=BRANCH_NAME=$GARNIX_BRANCH
                    build --build_metadata=COMMIT_SHA=$GARNIX_COMMIT_SHA
                    EOF

                    exec "${bazel-fhs}/bin/bazel-fhs" -c "env && bazelisk ${command}"
                  '';
                }
              }/bin/${name}";
            };
        in
        {
          fhs-env = {
            type = "app";
            program = "${bazel-fhs}/bin/bazel-fhs";
          };
          test = bazel-app "test" "test //...";
          format = bazel-app "format" "run //tools:format.check";
        }
      );
    };
}
