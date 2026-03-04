{
  description = "Minify your NixOS system!";

  outputs =
    { ... }:
    {
      #? The main entry point for this flake.
      #? Just import as NixOS module, no nixpkgs required.
      nixosModules = {
        main = ./main.nix;
        kde = ./kde.nix;
        systemPath = ./system-path.nix;
      };
    };
}
