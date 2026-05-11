{ lib, pkgs, ... }:
with pkgs.kdePackages;
{
  #* Special mention to KDE

  #? Minimal edits to enable more minimalisation
  disabledModules = [ "services/desktop-managers/plasma6.nix" ];
  imports = [ ./impl/plasma6.nix ];

  environment.plasma6.excludePackages = [ ];

  #? Exclude xdg-desktop-portal-gtk
  # TODO: exclude not override
  xdg.portal.extraPortals = lib.mkForce [
    kwallet
    xdg-desktop-portal-kde
  ];

  services = {
    desktopManager.plasma6 = {
      enableQt5Integration = false;

      #? Smaller font package without CJK
      #! notoPackage = pkgs.noto-fonts-lgc-plus;
    };

    geoclue2.enable = false;
  };

  programs.kde-pim.enable = false;

  #* Not yet, but waiting patiently
  # programs.xwayland = DISABLE;
}
