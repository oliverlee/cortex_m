{
  description = "flake containing packages used by repo extensions";

  inputs = {
    # tools/bazel evaluates the bazel-wrapper flake on its own. The
    # bazel-wrapper flake owns the nixpkgs pin.
    bazel-wrapper.url = "path:./bazel-wrapper";
    nixpkgs.follows = "bazel-wrapper/nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
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
        in
        {
          inherit (pkgs)
            gdb
            nixd
            nixfmt
            nixfmt-tree
            ;

          diff = pkgs.diffutils;

          qemu-system-arm = pkgs.qemu.override {
            hostCpuTargets = [ "arm-softmmu" ];
            minimal = true;
          };
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
          glibc =
            let
              sysroot-base = pkgs.symlinkJoin {
                name = "sysroot-base";
                paths = with pkgs; [
                  glibc
                  glibc.dev
                ];
              };
            in
            pkgs.runCommand "sysroot" { } ''
              cp -r ${sysroot-base} $out
              chmod -R +w $out

              # these are linker scripts and not libraries
              rm $out/lib/libc.so
              rm $out/lib/libm.so
            '';
        }
      );
    };
}
