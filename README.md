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
      nixos-minimal.nixosModules.default
  
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

Reading source code strongly recommended.
