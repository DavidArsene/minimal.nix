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

      #? Pass a stock nixpkgs input to get a custom one with:
      #?  - pre-configured allowUnfree
      #?  - readOnlyPkgs module
      #?  - nixosSystem that uses legacyPackages
      #?  - possibly more in the future
      wrapNixpkgs = lowerpkgs: import ./nixpkgs.nix lowerpkgs;
    };
}
