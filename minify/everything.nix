bil:
with bil;
{ config, ... }:
{
  options.nixos.minify.everything = mkEnableOption "Maximum minimalism!";

  config = mkIf config.nixos.minify.everything {

    nixos.minify = {
      experimental = yeah;
      no32BitGraphics = yeah;
      noAccessibility = yeah;
      noDocs = yeah;
      noInstallerTools = yeah;
      pkgs = yeah;
    };

  };
}
