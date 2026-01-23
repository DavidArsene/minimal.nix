# NixOS Minimal

Minify your NixOS system!

### Usage

You know the drill

```nix
{
  inputs.nixos-minimal.url = "github:me/this";
  
  # ...
  outputs = lib.nixosSystem {
    # ...
    modules = [
    
      # Change NixOS option defaults towards minimalism
      nixos-minimal.nixosModules.main
      
      # Make all KDE components optional
      # Cannot be used as-is, add back required packages
      nixos-minimal.nixosModules.kde
      
      # Custom environment.systemPackages that does not
      # install the "man" output for all packages, and
      # removes it when it is installed by default.
      nixos-minimal.nixosModules.systemPath
  
      {
        nixos.minify = {
          noAccessibility = true;
          everything = true;
          # ...
        };
      }

    ];
  };
}
```
