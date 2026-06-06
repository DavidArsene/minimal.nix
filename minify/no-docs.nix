bil:
with bil;
{ config, ... }:
{
  options.nixos.minify.noDocs = mkEnableOption "Disable documentation";

  config = mkIf config.nixos.minify.noDocs {
    documentation = DISABLE // {
      man = DISABLE;
      info = DISABLE;
      doc = DISABLE;
      nixos = DISABLE;
    };
  };
}
