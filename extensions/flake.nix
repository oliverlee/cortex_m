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
            qemu
            nixd
            nixfmt-tree
            ;
          nixfmt = pkgs.nixfmt-rfc-style;
        }
      );
    };
}
