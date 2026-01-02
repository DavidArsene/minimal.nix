{
  description = "Minify your NixOS system!";

  outputs =
    { ... }:
    {
      #? The main entry point for this flake.
      #? Just import as NixOS module, no nixpkgs required.
      nixosModules.default = ./combined.nix;

      #? Pass a stock nixpkgs input to get a custom one with:
      #?  - pre-configured allowUnfree
      #?  - readOnlyPkgs module
      #?  - nixosSystem that uses legacyPackages
      #?  - possibly more in the future
      wrapNixpkgs = lowerpkgs: import ./nixpkgs lowerpkgs;
    };
}
