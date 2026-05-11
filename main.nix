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

    # TODO: better description
    noInstallerTools = mkEnableOption "Remove most NixOS installer tools for building VMs, installing new systems, etc.; nixos-rebuild is always kept.";

    noAccessibility = mkEnableOption "For the 99%" // {
      default = true;
    };
  };

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

      #? For "virtual keyboard"s,
      #? like those used by CJK
      #? or typing-booster.
      i18n.inputMethod = disable;

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

      system.disableInstallerTools = mkIfEnabled cfg.noInstallerTools TRUE;

      #? This is about all the old ^ option does.
      environment.systemPackages = with pkgs; [
        # nixos-build-vms
        # nixos-enter
        # nixos-generate-config
        # nixos-install
        # nixos-option
        # nixos-version

        #! Keep this one
        (nixos-rebuild-ng.override {
          #? Use the system's nix package.
          #? It's just a python script anyway
          nix = config.nix.package;
        })
      ];

    }
    (mkIfEnabled cfg.experimental {

      #? "vconsole" is the one with Ctrl+Alt+F1
      #? doesn't seem to have side effects
      console = disable;

      #* I meeeaaaaaan....
      networking.firewall = DISABLE;

      #* Not entirely sure about this,
      #* maybe I'll regret it some time.
      #! systemd.coredump.extraConfig = "Storage=none";

      hardware.graphics = {
        # enable32Bit = FALSE;
        # extraPackages = NOTHING;
        # extraPackages32 = NOTHING;
      };

      #? modules/system/activation/top-level.nix
      system.systemBuilderArgs = {
        # `Legacy environment variables. These were used by the activation script,
        # but some other script might still depend on them, although unlikely.`
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

      #* causes mass rebuild
      # replaceStdenv = { pkgs }: pkgs.fastStdenv;

      #! ?
      # assertions = NOTHING;
      # warnings = NOTHING;
      # system.checks = NOTHING;

      system.activationScripts = {
        hashes = mkForce "";
        no-nix-channel = mkForce "";
      };

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
