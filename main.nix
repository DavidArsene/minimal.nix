{ lib, ... }:
let

  bil = rec {
    inherit (lib)
      mkDefault
      mkForce
      mkEnableOption
      mkIf
      ;

    TRUE = mkForce true;
    FALSE = mkForce false;
    yeah = mkDefault true;
    nah = mkDefault false;

    #? Prevent accidental changes.
    DISABLE = {
      enable = FALSE;
    };

    #? _disable_ just suggests something be off by default,
    #? but doesn't get in your way otherwise.
    disable = {
      enable = nah;
    };
  };
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
