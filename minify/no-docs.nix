bil:
with bil;
{ config, pkgs, ... }@args:
let

  prev-module = pkgs.path + /nixos/modules/config/system-path.nix;
  prev-system-path = (import prev-module args).config.system.path;

  man-eater =
    pkg:

    #? Ignore packages without manpages
    #! a few qt libraries don't have pkg.meta.outputsToInstall !?
    # (builtins.trace "no oTI in ${pkg.name}" [ ])
    if !(elem "man" pkg.meta.outputsToInstall or [ ]) then
      pkg

    else
      pkg.overrideAttrs {
        #* meta can be changed without causing rebuild
        meta = pkg.meta // {
          #? prev.meta sometimes doesn't include outputsToInstall !?
          outputsToInstall = remove "man" pkg.meta.outputsToInstall;
        };
      };
in

{
  options.nixos.minify.noDocs = mkEnableOption "Disable documentation (++ man-eater)";

  config = mkIf config.nixos.minify.noDocs {
    documentation = DISABLE // {
      man = DISABLE;
      info = DISABLE;
      doc = DISABLE;
      nixos = DISABLE;
    };

    #? Ridiculous workaround for infinite recursion
    system.path =
      prev-system-path.override (prev: {
        name = "system-path-woke";

        paths = map man-eater prev.paths;
      })
      |> mkForce
      |> builtins.trace "Running man-eater...";
  };
}
