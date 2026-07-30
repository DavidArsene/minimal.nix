bil: with bil; { config, ... }: {

  options.nixos.minify.systemd = mkEnableOption "WIP" // {
    default = true;
    internal = true;
  };

  config = mkIf config.nixos.minify.systemd {

    systemd = {

      settings.Manager = {
        DefaultMemoryAccounting = false;
        DefaultTasksAccounting = false;
        DefaultIOAccounting = false;
        DefaultIPAccounting = false;
      };

      # coredump.settings.Coredump = { Storage = "journal"; };

    };
    # services.journald.storage = "volatile";
  };
}
