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
  # NOTE: lib.pipe doesn't work
  imports = builtins.readDir ./minify |> builtins.attrNames |> map (mod: import ./minify/${mod} bil);
}
