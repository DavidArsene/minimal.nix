{
  description = "Ensmallen your NixOS system!";

  inputs = {
    nixpkgs.url = "nixpkgs";
  };

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";

      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;
    in
    {
      # TODO: automatic parameters
      nixosModules.default = import ./combined.nix { inherit pkgs lib; };
    };
}
