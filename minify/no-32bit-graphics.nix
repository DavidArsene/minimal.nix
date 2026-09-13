bil: with bil; { config, pkgs, ... }: {
  options.nixos.minify.no32BitGraphics = mkEnableOption "Disable 32-bit graphics support";

  config = mkIf config.nixos.minify.no32BitGraphics {
    #? Intentionally not using mkForce to prevent
    #? silently overriding the user's package
    hardware.nvidia.package =
      let
        inherit (config.boot.kernelPackages) nvidiaPackages;
        inherit (config.hardware.nvidia) branch;
      in
      nvidiaPackages.${branch}.override { disable32Bit = true; };

    hardware.graphics = {
      enable32Bit = FALSE;
      extraPackages32 = mkForce [ ];
      # TODO: error message package
      package32 = mkForce pkgs.emptyDirectory;
    };
  };
}
