{
  description = "Minify your NixOS system!";

  inputs.nixpkgs.url = "nixpkgs";

  outputs =
    { self, nixpkgs, ... }:
    {
      nixosModules.default = ./combined.nix;
    };
}
