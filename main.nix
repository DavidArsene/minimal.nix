{ lib, ... }:
let

  bil = lib.extend (
    final: prev: {

      TRUE = final.mkForce true;
      FALSE = final.mkForce false;
      yeah = final.mkDefault true;
      nah = final.mkDefault false;

      #? Prevent accidental changes.
      DISABLE = {
        enable = final.FALSE;
      };

      #? _disable_ just suggests something be off by default,
      #? but doesn't get in your way otherwise.
      disable = {
        enable = final.nah;
      };
    }
  );
in
{

  # FIXME: importing imports meh
  imports = [
    (import ./minify/everything.nix bil)
    (import ./minify/minimal-defaults.nix bil)
    (import ./minify/no-accessibility.nix bil)
    (import ./minify/no-docs.nix bil)
    (import ./minify/no-32bit-graphics.nix bil)
    (import ./minify/no-installer-tools.nix bil)
    (import ./minify/experimental.nix bil)
  ];
}
