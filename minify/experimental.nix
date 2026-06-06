bil:
with bil;
{ config, pkgs, ... }:

{
  options.nixos.minify.experimental = mkEnableOption "Works on my machine";

  config = mkIf config.nixos.minify.experimental {

    #? "vconsole" is the one with Ctrl+Alt+F1
    #? doesn't seem to have side effects
    console = disable;

    #* I meeeaaaaaan....
    networking.firewall = DISABLE;

    #* Not entirely sure about this,
    #* maybe I'll regret it some time.
    #! systemd.coredump.extraConfig = "Storage=none";

    # TODO?: fonts.enableDefaultFonts = FALSE;

    # TODO: replacement
    # https://github.com/NixOS/nixpkgs/pull/341717
    # environment.noXlibs = true;

    # TODO: custom top-level

    system = {
      #? modules/system/activation/top-level.nix
      systemBuilderArgs = {
        # `Legacy environment variables. These were used by the activation script,
        # but some other script might still depend on them, although unlikely.`
        localeArchive = mkForce null;
        perl = mkForce null;
      };

      activationScripts = {
        hashes = mkForce "";
        no-nix-channel = mkForce "";
      };

      replaceDependencies.replacements = [
        /*
          {
            oldDependency = pkgs.openssl;
            newDependency = pkgs.callPackage /path/to/openssl { };
          }
          {
            oldDependency = pkgs.glibc;
            newDependency = pkgs.callPackage /path/to/glibc { };
          }
        */
      ];
    };

    #? An attempt to reduce eval time similar to what allowAliases
    #? does for packages, by not parsing all these options found
    #? all throughout nixpkgs.
    /*
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
    */
    # FIXME: extend THIS WAS A MISTAKE! - move to wrapper extend

    #* causes mass rebuild
    # replaceStdenv = { pkgs }: pkgs.fastStdenv;

    #! ?
    # assertions = NOTHING;
    # warnings = NOTHING;
    # system.checks = NOTHING;

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
    boot.initrd = {
      includeDefaultModules = false;
      availableKernelModules = mkDefault [ ];

      #? This also means that initrd can be removed entirely by
      #? compiling a custom kernel with the old availableKernelModules.
      enable = yeah;
    };

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
  };
}
