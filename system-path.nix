{
  config,
  lib,
  pkgs,
  ...
}:
let
  man-eater =
    pkg:

    if !(pkg.meta ? outputsToInstall) then
      lib.warn "[man-eater] ${pkg.name} has no meta.outputsToInstall" pkg

    else if !(lib.elem "man" pkg.meta.outputsToInstall) then
      pkg

    else
      pkg.overrideAttrs (prev: {
        meta = prev.meta // {
          # prev.meta sometimes doesn't include outputsToInstall !?
          outputsToInstall = lib.remove "man" pkg.meta.outputsToInstall;
        };
      });
in
{
  environment.defaultPackages = lib.mkForce [ ];

  system.path = builtins.trace "Running man-eater..." lib.mkForce (
    pkgs.buildEnv {
      name = "system-path-woke";

      paths = map man-eater config.environment.systemPackages;

      inherit (config.environment) pathsToLink extraOutputsToInstall;
      ignoreCollisions = true;

      # !!! Hacky, should modularise.
      # outputs TODO: note that the tools will often not be linked by default
      postBuild = ''
        # Remove wrapped binaries, they shouldn't be accessible via PATH.
        find $out/bin -maxdepth 1 -name ".*-wrapped" -type l -delete

        if [ -x $out/bin/glib-compile-schemas -a -w $out/share/glib-2.0/schemas ]; then
            $out/bin/glib-compile-schemas $out/share/glib-2.0/schemas
        fi

        ${config.environment.extraSetup}
      '';
    }
  );
}
