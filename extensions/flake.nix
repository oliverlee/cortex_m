{
  description = "flake containing packages used by repo extensions";

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
            nixfmt-tree
            qemu
            ;

          nixfmt = pkgs.nixfmt-rfc-style;

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
