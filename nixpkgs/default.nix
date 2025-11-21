nixpkgs:
let
  # libVersionInfoOverlay = import ./lib/flake-version-info.nix self;
  lib = import (nixpkgs + /lib); # .extend libVersionInfoOverlay;

  forAllSystems = lib.genAttrs lib.systems.flakeExposed;

  betterDefaultConfig = {
    allowAliases = false;
    allowUnfree = true;
    allowVariants = false;
    warnUndeclaredOptions = true;
  };

in
rec {

  # TODO: docs
  nixosSystem =
    { modules, system, ... }@args:

    let
      finalModules = modules ++ [

        nixpkgs.nixosModules.readOnlyPkgs

        {
          config.nixpkgs = {
            flake.source = nixpkgs;

            # Locked by readOnlyPkgs
            # hostPlatform = system;

            # Usually, lib.nixosSystem doesn't go through legacyPackages,
            # relying on modules/misc/nixpkgs.nix instead. This is the root
            # cause of why nixpkgs.config is not applied for other nixpkgs
            # instances. Change it here to use one unified config, and then
            # pass any nixpkgs to this flake's inputs.
            pkgs = lib.mkDefault legacyPackages.${system};
          };
        }
      ];

      config = import (nixpkgs + /nixos/lib/eval-config.nix) (

        # If args comes first, before //, then `modules` from below
        # overrides its own, removing the need for removeAttrs.
        # Why isn't this used elsewhere?
        args
        // {

          inherit lib;
          system = null;
          modules = finalModules;

          #! TODO: minimal module-list is perfectly functional,
          #! just that modules are interconnected :(
          # baseModules = import ./nixos/modules/module-list.nix {
          #   inherit nixpkgs excludes includes;
          # };
          baseModules = import (nixpkgs + /nixos/modules/module-list.nix);
        }
      );
    in
    config;

  /**
    A nested structure of [packages](https://nix.dev/manual/nix/latest/glossary#package) and other values.

    When the Nix CLI sees a `legacyPackages` attribute it displays `omitted`
    instead of evaluating all packages, which keeps `nix flake show`
    on Nixpkgs reasonably fast, though less information rich.
  */
  legacyPackages = forAllSystems (
    system:
    (import (nixpkgs + /pkgs/top-level) {
      localSystem = { inherit system; }; # no builtins.currentSystem

      config =
        let
          date = nixpkgs.lastModifiedDate;
          substr = s: l: lib.substring s l date;
          pretty = "${substr 0 4}/${substr 4 2}/${substr 6 2}";
        in
        builtins.trace "minimal.nix: new pkgs instance for ${system} from ${nixpkgs} on ${pretty}." betterDefaultConfig;

      # overlays =
      # Unneeded in pure evaluation mode
      # import ./pkgs/top-level/impure-overlays.nix ++
      # [ (final: prev: { lib = prev.lib.extend libVersionInfoOverlay; }) ];
    })
  );
}
