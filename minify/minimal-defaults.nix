bil:
with bil;
{ config, pkgs, ... }:
{
  options.nixos.minify.minimalDefaults = mkEnableOption "Opinionated sensible defaults" // {
    default = true;
  };

  config = mkIf config.nixos.minify.minimalDefaults {
    #? Enabled by desktop environments when needed
    xdg = {
      autostart = disable;
      icons = disable;
      mime = disable;
      sounds = disable;
    };

    environment = {
      stub-ld = disable;

      # TODO: gst-plugins-*
    };

    programs = {
      #* meh default or not
      fish.generateCompletions = nah;

      #! use github:nix-community/nix-index-database
      command-not-found = DISABLE;

      #* Other packages depend on normal git
      #* anyway, so this is kinda useless.
      git.package = pkgs.gitMinimal;
    };

    #? No mobile data around here
    networking.modemmanager = DISABLE;

    nix.settings = {
      auto-optimise-store = true;
      build-dir = /tmp/nixbld; # FIXME: chmod /tmp 0775
      builders-use-substitutes = true;
    };
    nix.channel = disable;

    boot = {
      bcache = disable;
      kexec = disable;

      #? Not related but has the same vibe
      tmp = {
        useTmpfs = yeah;
        tmpfsHugeMemoryPages = "within_size";
      };
    };

    services = {
      logrotate = disable;
      udisks2 = disable;
      printing = disable;

      dbus.implementation = "broker";
    };

    #? something something reducing dependencies on X libs
    security.pam.services.su.forwardXAuth = FALSE;

    users.manageLingering = nah;
  };
}
