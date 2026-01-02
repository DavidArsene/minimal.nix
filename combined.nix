{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault mkForce mkEnableOption;

  TRUE = mkForce true;
  FALSE = mkForce false;
  yeah = mkDefault true;
  nah = mkDefault false;

  NOTHING = mkForce [ ];

  #? Prevent accidental changes.
  DISABLE = {
    enable = FALSE;
  };

  #? _disable_ just suggests something be off by default,
  #? but doesn't get in your way otherwise.
  disable = {
    enable = nah;
  };

  cfg = config.nixos.minify;
  mkIfEnabled = opt: lib.mkIf (opt || cfg.everything);

in
{
  options.comment = lib.mkOption { type = lib.types.anything; };

  options.nixos.minify = {

    #! TODO: Check these for updates in profiles
    #! https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles
    minimalDefaults = mkEnableOption "Opinionated sensible defaults" // {
      default = true;
    };

    everything = mkEnableOption "Maximum minimalism!";
    experimental = mkEnableOption "Works on my machine";

    noDocs = mkEnableOption "Disable documentation";

    # plasma6 = mkEnableOption "Exclude a few things bundled with KDE Plasma 6. Not configurable yet.";

    # TODO: better description
    noInstallerTools = mkEnableOption "Remove most NixOS installer tools for building VMs, installing new systems, etc.; nixos-rebuild is always kept.";

    noAccessibility = mkEnableOption "For those part of the 99%" // {
      default = true;
    };

  };

  # TODO: Fix conditional import
  imports = [
    #! Make sure you add everything you want back!
    #! The exclude list contains anything I thought
    #! could be considered non-essential.
    ./kde.nix
    # ./nixpkgs/nixos/modules/config/system-path.nix
  ];

  config = lib.mkMerge [
    (mkIfEnabled cfg.minimalDefaults {

      #? Enabled by desktop environments when needed
      xdg = {
        autostart = disable;
        icons = disable;
        mime = disable;
        sounds = disable;
      };

      environment = {
        defaultPackages =
          # [ perl rsync strace ]
          NOTHING;

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
        build-dir = "/tmp/nixbld"; # FIXME: chmod /tmp 0775
        builders-use-substitutes = true;
      };
      nix.channel = disable;

      #? Covered by nixpkgs/flake.nix now
      comment.nixpkgs.config = {
        #? Allowing aliases means nixpkgs will import a module
        #? called aliases.nix, in which old versions of packages
        #? get either aliased to new ones, or given an error
        #? with the required changes. May require updating configs.
        allowAliases = false;

        #? Variants are instances of the current nixpkgs instance
        #? with different stdenvs or other applied options.
        #? This allows for using different toolchains, libcs, or
        #? global build changes across nixpkgs. Disabling can ensure
        #? nixpkgs is only building for the platform which you specified.
        #*
        #* I don't exactly (care to) understand what that means,
        #* but maybe has some effect.
        allowVariants = false;
      };

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

        #* Saving the planet, one paper at a time
        printing = DISABLE;

        dbus.implementation = "broker";
      };

      #? something something reducing dependencies on X libs
      security.pam.services.su.forwardXAuth = FALSE;

      users.manageLingering = nah;

    })
    (mkIfEnabled cfg.noAccessibility {

      services = {
        orca = DISABLE; # ? Screen reader
        speechd = DISABLE; # ? TTS
      };

      programs = {
        firefox.wrapperConfig = {
          speechSynthesisSupport = false;
        };
      };

      #* Keyboard still works so /shrug
      #? Maybe on-screen-keyboard / CJK something
      i18n.inputMethod = DISABLE;

    })
    (mkIfEnabled cfg.noDocs {

      documentation = DISABLE // {
        man = DISABLE;
        info = DISABLE;
        doc = DISABLE;
        nixos = DISABLE;
      };

    })
    {

      # TODO: custom top-level

      # FIXME: The NixOS installer tools depend on a specific version of nix.
      system.disableInstallerTools = mkIfEnabled cfg.noInstallerTools TRUE;

      #? This is about all the old ^ option does.
      environment.systemPackages = with pkgs; [
        # nixos-build-vms
        # nixos-enter
        # nixos-generate-config
        # nixos-install
        # nixos-option
        (nixos-rebuild-ng.override { nix = config.nix.package; }) # ! Keep this one
        # nixos-version
      ];

    }
    (mkIfEnabled cfg.experimental {

      #? "vconsole" is the one with Ctrl+Alt+F1
      #? doesn't seem to have side effects
      console.enable = false;

      #* I meeeaaaaaan....
      networking.firewall = DISABLE;

      #* Not entirely sure about this,
      #* maybe I'll regret it some time.
      ###! systemd.coredump.extraConfig = "Storage=none";

      hardware.graphics = {
        enable32Bit = FALSE;
        extraPackages = mkForce [ ];
        extraPackages32 = mkForce [ ];
      };

      #? modules/system/activation/top-level.nix
      system.systemBuilderArgs = {
        # Legacy environment variables. These were used by the activation script,
        # but some other script might still depend on them, although unlikely.
        localeArchive = mkForce null;
        perl = mkForce null;
      };

      #? An attempt to reduce eval time similar to what allowAliases
      #? does for packages, by not parsing all these options found
      #? all throughout nixpkgs.
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
        }; # FIXME: lib.extend THIS WAS A MISTAKE!

      #* causes mass rebuild :(
      # replaceStdenv = { pkgs }: pkgs.fastStdenv;

      #! ?
      # assertions = NOTHING;
      # warnings = NOTHING;
      # system.checks = NOTHING;

      # system.activationScripts = {
      #   hashes = null;
      #   no-nix-channel = null;
      # };

      #? Similar to hardware.firmware, make sure you
      #? include all required modules manually.
      #? These are the default modules:
      #? https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/kernel.nix#L333
      #? Try removing everything (also from hardware-configuration.nix)
      #? and see what reason it gives for not being able to mount the root fs.
      #? This is basically what initrd does: UEFI can only read (V)FAT,
      #? so only the initrd and kernel are placed in the ESP.
      #? After the real root fs is mounted by initrd, the kernel
      #? can load all other modules from there.
      boot.initrd.includeDefaultModules = false;
      boot.initrd.availableKernelModules = mkDefault [ ];

      #? This also means that initrd can be removed entirely by
      #? compiling a custom kernel with the old availableKernelModules.
      boot.initrd.enable = mkDefault true;

      #* Ooh this is a good one
      hardware = {
        firmware = with pkgs; [

          #? The firmware package is huge, and contains firmware
          #? for all devices that Linux has ever supported.
          #?
          #? Until someone bothers to find a method to detect
          #? only the required firmware for a given device,
          #? the only method is to disable it and see what breaks.
          #?
          #? sudo journalctl -b -1 | rg "Direct firmware load for"
          #?
          #? Use this to find what's missing. "-b -1" for the
          #? previous boot if it fails, "-b" otherwise.
          #*
          #* Update: use firmware-minimal from my other repo
          #* for selectively including firmware.
          #! linux-firmware

          #? The following firmware packages are redistributable and
          #? considered useful enough to install by (almost) default.

          # intel2200BGFirmware
          # rtl8192su-firmware
          # rt5677-firmware
          # rtl8761b-firmware
          # zd1211fw
          # alsa-firmware
          # sof-firmware
          # libreelec-dvb-firmware

          #? And those are for the people who thought "enable"
          #? means "allow", not "install something else".
          #* FaceTime camera calibration‽ come on.

          # broadcom-bt-firmware
          # b43Firmware_5_1_138
          # b43Firmware_6_30_163_46
          # xow_dongle-firmware
          # facetimehd-calibration
          # facetimehd-firmware

          #* Keep this one. Or don't, I'm not your father.
          wireless-regdb
        ];

        #? Don't add them back.
        enableAllFirmware = FALSE;
        enableRedistributableFirmware = FALSE;
      };
    })
  ];
}
