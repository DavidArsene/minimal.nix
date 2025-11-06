{
  pkgs,
  lib,
  config,
}:
let
  inherit (lib) mkDefault mkForce mkEnableOption;

  cfg = config.nixos.ensmallen;

  TRUE = mkForce true;
  FALSE = mkForce false;
  yeah = mkDefault true;
  nah = mkDefault false;

  NOTHING = mkForce [ ];

  # Prevent accidental changes.
  DISABLE = {
    enable = FALSE;
  };

  # disable in lowercase is more of a chill guy,
  # he just suggests something be off by default,
  # but doesn't get in your way otherwise.
  disable = {
    enable = nah;
  };

  mkIfEnabled = opt: lib.mkIf (opt || cfg.everything);
in
{
  options.nixos.ensmallen = {

    # TODO: Check these for updates in profiles
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles
    minimalDefaults = mkEnableOption "Opinionated sensible defaults" // {
      default = true;
    };

    everything = mkEnableOption "Maximum minimalism!";
    experimental = mkEnableOption "Works on my machine";

    noDocs = mkEnableOption "Disable documentation";

    plasma6 = mkEnableOption "Exclude a few things bundled with KDE Plasma 6. Not configurable yet.";

    # TODO: better description
    noInstallerTools = mkEnableOption "Remove most NixOS installer tools for building VMs, installing new systems, etc.; nixos-rebuild is always kept.";

    noAccessibility = mkEnableOption "For those part of the 99%" // {
      default = true;
    };
  };

  imports = [ (mkIfEnabled cfg.plasma6 ./kde.nix) ];

  config =
    mkIfEnabled cfg.minimalDefaults {
      # Enabled by desktop environments when needed
      xdg = {
        autostart = disable;
        icons = disable;
        mime = disable;
        sounds = disable;
      };

      environment = {
        # [ perl rsync strace ]
        defaultPackages = NOTHING;

        stub-ld = disable;

        # TODO: gst-plugins-*
      };

      programs = {
        # meh default or not
        fish.generateCompletions = nah;

        # use github:nix-community/nix-index-database
        command-not-found = DISABLE;

        # Other packages depend on normal git
        # anyway, so this is kinda useless.
        git.package = pkgs.gitMinimal;
      };

      # No mobile data around here
      networking.modemmanager = DISABLE;

      nixpkgs.config = {
        # Allowing aliases means nixpkgs will import a module
        # called aliases.nix, in which old versions of packages
        # get either aliased to new ones, or given an error
        # with the required changes. May require updating configs.
        allowAliases = false;

        # > Variants are instances of the current nixpkgs instance
        # > with different stdenvs or other applied options.
        # > This allows for using different toolchains, libcs, or
        # > global build changes across nixpkgs. Disabling can ensure
        # > nixpkgs is only building for the platform which you specified.
        #
        # I don't exactly (care to) understand what that means,
        # but maybe has some effect.
        allowVariants = false;

        # Good to have
        cudaSupport = false;
      };

      boot = {
        bcache = disable;
        kexec = disable;

        # Not related but has the same vibe
        tmp = {
          useTmpfs = yeah;
          tmpfsHugeMemoryPages = "within_size";
        };
      };

      services = {
        logrotate = disable;
        udisks2 = disable;

        # Saving the planet, one paper at a time
        printing = DISABLE;
      };

      # something something reducing dependencies on X libs
      security.pam.services.su.forwardXAuth = FALSE;
    }

    // mkIfEnabled cfg.noAccessibility {

      services = {
        orca = DISABLE; # Screen reader
        speechd = DISABLE; # TTS
      };

      programs = {
        firefox.wrapperConfig = {
          speechSynthesisSupport = false;
        };
      };

      # Keyboard still works so /shrug
      # Maybe on-screen-keyboard / CJK something
      i18n.inputMethod = DISABLE;

    }

    // {
      documentation = mkIfEnabled cfg.noDocs DISABLE;
      # TODO: custom top-level

      # The NixOS installer tools depend on a specific version of nix.
      system.disableInstallerTools = mkIfEnabled cfg.noInstallerTools TRUE;

      # This is about all the ^ option does.
      environment.systemPackages = with pkgs; [
        # nixos-build-vms
        # nixos-enter
        # nixos-generate-config
        # nixos-install
        # nixos-option
        nixos-rebuild # Keep this one
        # nixos-version
      ];

    }

    // mkIfEnabled cfg.experimental {

      # "vconsole" is the one with Ctrl+Alt+F1
      # doesn't seem to have side effects
      console = DISABLE;

      # I meeeaaaaaan....
      networking.firewall = DISABLE;

      # Not entirely sure about this,
      # maybe I'll regret it some time.
      systemd.coredump.extraConfig = "Storage=none";

      # An attempt to reduce eval time similar to what allowAliases
      # does for packages, by not parsing all these options found
      # all throughout nixpkgs.
      lib =
        let
          nullFn = lib.const null;
        in
        lib
        // {
          mkAliasOptionModule = nullFn;
          mkMergedOptionModule = nullFn;
          mkChangedOptionModule = nullFn;
          mkRemovedOptionModule = nullFn;
          mkRenamedOptionModule = nullFn;
        };

      # causes mass rebuild :(
      # replaceStdenv = { pkgs }: pkgs.fastStdenv;

      # !?
      # assertions = NOTHING;
      # warnings = NOTHING;
      # system.checks = NOTHING;

      # Ooh this is a good one
      hardware = {
        firmware = with pkgs; [

          # The firmware package is huge, and contains firmware
          # for all devices that Linux has ever supported.
          #
          # Until I bother to find a method to detect and separate
          # only the required firmware for a given device,
          # the only method is to disable it and see what breaks.
          #
          # sudo journalctl -b -1 | rg "Direct firmware load for"
          #
          # Use this to find what's missing. "-b -1" for the
          # previous boot if it fails, "-b" otherwise.
          #
          # Update: use linux-firmware-minimal from my other repo
          # for selectively including firmware.
          linux-firmware

          # The following firmware packages are redistributable and
          # considered useful enough to install by (almost) default.

          # intel2200BGFirmware
          # rtl8192su-firmware
          # rt5677-firmware
          # rtl8761b-firmware
          # zd1211fw
          # alsa-firmware
          # sof-firmware
          # libreelec-dvb-firmware

          # And those are for the people who thought "enable"
          # means enable, not "install something else".
          # FaceTime camera calibration‽ come on.

          # broadcom-bt-firmware
          # b43Firmware_5_1_138
          # b43Firmware_6_30_163_46
          # xow_dongle-firmware
          # facetimehd-calibration
          # facetimehd-firmware

          # Keep this one. Or don't, I'm not your father.
          wireless-regdb
        ];

        # Don't conflict with above
        enableAllFirmware = FALSE;
        enableRedistributableFirmware = FALSE;
      };

      nixpkgs.overlays = [
        (
          # TODO: so experimental it doesn't even work
          final: prev:
          let
            wrapStdenv =
              theStdenv:
              theStdenv
              // {
                mkDerivation =
                  args:
                  let
                    drv = theStdenv.mkDerivation args;

                    meta = drv.meta // {
                      outputsToInstall = lib.remove "man" drv.meta.outputsToInstall;
                    };

                  in
                  drv // { inherit meta; };
              };

          in
          {
            stdenv = wrapStdenv prev.stdenv;
            stdenvNoCC = wrapStdenv prev.stdenvNoCC;
            # nix = prev.nix.override { withAWS = false; };
          }
        )
      ];

    };
}
