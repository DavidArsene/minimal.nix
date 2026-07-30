bil: with bil; { config, ... }: {
  options.nixos.minify.no32BitGraphics = mkEnableOption "Disable 32-bit graphics support";

  config = mkIf config.nixos.minify.no32BitGraphics {
    hardware.nvidia.package =
      let
        nvPkg = config.boot.kernelPackages.nvidiaPackages.bleeding_edge;
      in
      mkForce (nvPkg.override { disable32Bit = true; });

    hardware.graphics = {
      enable32Bit = FALSE;
      extraPackages32 = mkForce [ ];
      # TODO: error message package
      package32 = mkForce pkgs.emptyFile;
    };
  };
}
