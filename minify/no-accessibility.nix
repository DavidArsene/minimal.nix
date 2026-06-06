bil:
with bil;
{ config, ... }:
{
  options.nixos.minify.noAccessibility = mkEnableOption "For the 99%" // {
    default = true;
  };

  config = mkIf config.nixos.minify.noAccessibility {
    services = {
      orca = DISABLE; # ? Screen reader
      speechd = DISABLE; # ? TTS
    };

    programs = {
      firefox.wrapperConfig = {
        speechSynthesisSupport = false;
      };
    };

    #? For "virtual keyboard"s,
    #? like those used by CJK
    #? or typing-booster.
    i18n.inputMethod = disable;
  };
}
