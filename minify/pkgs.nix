bil:
with bil;
{ config, pkgs, ... }:
let

  #! TODO: use
  mkEmptyReplacementFor =
    pkg:
    let
      name = pkg.pname or pkg.name;
      suffix = "...-null";

      trimLen = stringLength name - (stringLength suffix);
    in
    assert trimLen > 0;
    pkgs.stdenvNoCC.mkDerivation {
      name = (substring 0 trimLen name) + suffix;

      phases = [ "installPhase" ];
      installPhase = "echo 'Empty replacement for ${name}' > $out";
    };

in
{
  options.nixos.minify.pkgs = mkEnableOption "Package-related changes";
  options.nixos.minify.depsToReplace = mkOption {
    description = "Dependencies to replace using IFD (only when 'minify.pkgs' is enabled).";
    # type = types.;

    default = {
      nix = config.nix.package;

      #! NOTE: pname is still "ibus", unlike git and "git-minimal".
      #! They need to be the same length!
      ibus = pkgs.ibusMinimal;
    };
  };

  config = mkIf config.nixos.minify.pkgs {
    #! NOTE: Uses IFD! Will build the whole system as a dependency of
    #! the packages it affects, then it will "rebuild" them by just
    #! replacing the store paths.
    #! It will not save you from downloading the original package tho,
    #! but rather affect the resulting closure (or disk size after gc)

    # with lib; attrNames pkgs |> filter (hasSuffix "Minimal")
    system.replaceDependencies.replacements =

      config.nixos.minify.depsToReplace
      |> mapAttrsToList (
        k: v: {
          oldDependency = pkgs.${k};
          newDependency = v;
        }
      )
      |> builtins.trace "IFD-based dependency replacements enabled."
      |> mkIf (builtins.getEnv "NIXOS_MINIFY_REPLACE_DEPS" == "1");

    # TODO: native!!
    comment.programs.systemd.package = pkgs.systemd.override rec {
      withAcl = true;
      withAnalyze = true;
      withApparmor = false;
      withAudit = false;
      # compiles systemd-boot, assumes EFI is available.
      withBootloader = withEfi;
      # adds bzip2, lz4, xz and zstd
      withCompression = true;
      withCoredump = true;
      withCryptsetup = true;
      withRepart = true;
      withDocumentation = false;
      withEfi = stdenv.hostPlatform.isEfi;
      withFido2 = true;
      withFirstboot = true;
      withGcrypt = true;
      withHomed = true;
      withHostnamed = true;
      withHwdb = true;
      withImportd = true;
      withImds = true;
      withKmod = true;
      withLibBPF =
        lib.versionAtLeast buildPackages.llvmPackages.clang.version "10.0"
        # buildPackages.targetPackages.llvmPackages is the same as llvmPackages;
        # but we do it this way to avoid taking llvmPackages as an input, and
        # risking making it too easy to ignore the above comment about llvmPackages.
        && lib.meta.availableOn stdenv.hostPlatform buildPackages.targetPackages.llvmPackages.compiler-rt;
      withLibidn2 = true;
      withLocaled = true;
      withLogind = true;
      withMachined = true;
      withNetworkd = true;
      withNspawn = true;
      withNss = true;
      withOomd = true;
      withOpenSSL = true;
      withPam = true;
      withPasswordQuality = true;
      withPCRE2 = true;
      withPolkit = true;
      withPortabled = true;
      withQrencode = true;
      withRemote = true;
      withResolved = true;
      withShellCompletions = true;
      withSysinstall = true;
      withSysusers = true;
      withSysupdate = true;
      withTimedated = true;
      withTimesyncd = true;
      withTpm2Tss = true;
      # adds python to closure which is too much by default
      withUkify = false;
      withUserDb = true;
      withUtmp = true;
      withVmspawn = true;
      # kernel-install shouldn't usually be used on NixOS, but can be useful, e.g. for
      # building disk images for non-NixOS systems. To save users from trying to use it
      # on their live NixOS system, we disable it by default.
      withKernelInstall = false;
      withLibarchive = true;
      withVConsole = true;
    };
  };
}
