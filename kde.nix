{ lib, pkgs, ... }:
with pkgs.kdePackages;
{
  # Special mention to KDE

  # Minimal edits to enable more minimalisation
  disabledModules = [ "services/desktop-managers/plasma6.nix" ];
  imports = [ ./nixpkgs/nixos/modules/services/desktop-managers/plasma6.nix ];

  environment.plasma6.excludePackages = [

    # Frameworks with globally loadable bits
    # frameworkintegration # provides Qt plugin
    # kauth # provides helper service
    # kcoreaddons # provides extra mime type info
    # kded # provides helper service
    kfilemetadata # provides Qt plugins
    # kguiaddons # provides geo URL handlers
    # kiconthemes # provides Qt plugins
    # kimageformats # provides Qt plugins
    # qtimageformats # provides optional image formats such as .webp and .avif
    # kio # provides helper service + a bunch of other stuff
    # kio-admin # managing files as admin
    # kio-extras # stuff for MTP, AFC, etc
    # kio-fuse # fuse interface for KIO
    # knighttime # night mode switching daemon
    # kpackage # provides kpackagetool tool
    # kservice # provides kbuildsycoca6 tool
    # kunifiedpush # provides a background service and a KCM
    # kwallet # provides helper service
    # kwallet-pam # provides helper service
    # kwalletmanager # provides KCMs and stuff
    # plasma-activities # provides plasma-activities-cli tool
    # solid # provides solid-hardware6 tool
    phonon-vlc # provides Phonon plugin

    # Core Plasma parts
    # kwin
    # kscreen
    # libkscreen
    # kscreenlocker
    # kactivitymanagerd # cannot be removed
    # kde-cli-tools
    # kglobalacceld # keyboard shortcut daemon
    # kwrited # wall message proxy, not to be confused with kwrite
    # baloo # system indexer
    # milou # search engine atop baloo
    # kdegraphics-thumbnailers # pdf etc thumbnailer
    # polkit-kde-agent-1 # polkit auth ui
    # plasma-desktop
    # plasma-workspace
    drkonqi # crash handler
    kde-inotify-survey # warns the user on low inotifywatch limits

    # Application integration
    # libplasma # provides Kirigami platform theme
    # plasma-integration # provides Qt platform theme
    # kde-gtk-config # syncs KDE settings to GTK

    # Artwork + themes
    # breeze
    # breeze-icons
    # breeze-gtk
    # ocean-sound-theme
    # pkgs.hicolor-icon-theme # fallback icons
    # qqc2-breeze-style
    # qqc2-desktop-style

    # misc Plasma extras
    # kdeplasma-addons
    # pkgs.xdg-user-dirs # recommended upstream

    # Plasma utilities
    # kmenuedit
    # kinfocenter
    # plasma-systemmonitor
    # ksystemstats
    # libksysguard
    # systemsettings
    # kcmutils

    #! optionalPackages =
    # aurorae
    # plasma-browser-integration
    plasma-workspace-wallpapers
    # konsole
    kwin-x11
    # (lib.getBin qttools) # Expose qdbus in PATH
    # ark
    elisa
    # gwenview
    okular
    # kate
    # ktexteditor # provides elevated actions for kate
    khelpcenter
    # dolphin
    # baloo-widgets # baloo information in Dolphin
    # dolphin-plugins
    # spectacle
    ffmpegthumbs
    # krdp
  ];

  # Exclude xdg-desktop-portal-gtk
  # TODO: exclude not override
  xdg.portal.extraPortals = lib.mkForce [
    kwallet
    xdg-desktop-portal-kde
  ];

  services = {
    desktopManager.plasma6 = {
      enableQt5Integration = false;
      notoPackage = pkgs.noto-fonts-lgc-plus;
    };

    geoclue2.enable = false;
  };

  # Causes `sddm-unwrapped` to rebuild :(
  comment.services.displayManager.sddm.extraPackages = lib.mkForce [
    breeze-icons
    kirigami
    libplasma
    # plasma5support
    qtsvg
    # qtvirtualkeyboard
  ];

  programs.kde-pim.enable = false;

  #> Not yet, but waiting patiently
  # programs.xwayland = disableForce;
}
