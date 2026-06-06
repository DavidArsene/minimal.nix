bil:
with bil;
{ config, pkgs, ... }:
{
  options.nixos.minify.noInstallerTools = mkEnableOption "Remove most NixOS installer tools for building VMs, installing new systems, etc.; nixos-rebuild is always kept.";

  config = mkIf config.nixos.minify.noInstallerTools {

    system.disableInstallerTools = true;

    #? This is about all the ^ option does.
    environment.systemPackages = with pkgs; [
      # nixos-build-vms
      # nixos-enter
      # nixos-generate-config
      # nixos-install
      # nixos-option
      # nixos-version

      #! Keep this one
      nixos-rebuild-ng
    ];
  };
}
