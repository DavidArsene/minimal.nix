bil:
with bil;
{ config, ... }:
{
  options.nixos.minify.everything = mkEnableOption "Maximum minimalism!";

  config = mkIf config.nixos.minify.everything {

    nixos.minify = {
      experimental = yeah;
      noDocs = yeah;
      no32BitGraphics = yeah;
      noInstallerTools = yeah;
      noAccessibility = yeah;
    };

  };
}
