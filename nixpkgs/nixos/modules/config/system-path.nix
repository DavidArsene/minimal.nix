# This module defines the packages that appear in
# /run/current-system/sw.
{
  config,
  lib,
  pkgs,
  ...
}:
let

  corePackageNames = [
    "acl"
    "attr"
    "bashInteractive" # bash with ncurses support
    "bzip2"
    "coreutils-full"
    "cpio"
    "curl"
    "diffutils"
    "findutils"
    "gawk"
    "getent"
    "getconf"
    "gnugrep"
    "gnupatch"
    "gnused"
    "gnutar"
    "gzip"
    "xz"
    "less"
    "libcap"
    "ncurses"
    "netcat"
    "mkpasswd"
    "procps"
    "su"
    "time"
    "util-linux"
    "which"
    "zstd"
  ];
  corePackages =
    (map (
      n:
      let
        pkg = pkgs.${n};
      in
      lib.setPrio ((pkg.meta.priority or lib.meta.defaultPriority) + 3) pkg
    ) corePackageNames)
    ++ [ pkgs.stdenv.cc.libc ];
  corePackagesText = "[ ${lib.concatMapStringsSep " " (n: "pkgs.${n}") corePackageNames} ]";

in

{
  options = {

    environment = {

      systemPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        example = lib.literalExpression "[ pkgs.firefox pkgs.thunderbird ]";
        description = ''
          The set of packages that appear in
          /run/current-system/sw.  These packages are
          automatically available to all users, and are
          automatically updated every time you rebuild the system
          configuration.  (The latter is the main difference with
          installing them in the default profile,
          {file}`/nix/var/nix/profiles/default`.
        '';
      };

      corePackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        defaultText = lib.literalMD ''
          these packages, with their `meta.priority` numerically increased
          (thus lowering their installation priority):

              ${corePackagesText}
        '';
        example = [ ];
        description = ''
          Set of core packages for a normal interactive system.

          Only change this if you know what you're doing!

          Like with systemPackages, packages are installed to
          {file}`/run/current-system/sw`. They are
          automatically available to all users, and are
          automatically updated every time you rebuild the system
          configuration.
        '';
      };

      pathsToLink = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        # Note: We need `/lib' to be among `pathsToLink' for NSS modules
        # to work.
        default = [ ];
        example = [ "/" ];
        description = "List of directories to be symlinked in {file}`/run/current-system/sw`.";
      };

      extraSetup = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Shell fragments to be run after the system environment has been created. This should only be used for things that need to modify the internals of the environment, e.g. generating MIME caches. The environment being built can be accessed at $out.";
      };

    };

    system = {

      path = lib.mkOption {
        internal = true;
        description = ''
          The packages you want in the boot environment.
        '';
      };

    };

  };

  disabledModules = [ "config/system-path.nix" ];

  config = {

    # Set this here so that it has the right priority and allows ergonomic
    # merging.
    environment.corePackages = corePackages;

    environment.systemPackages = config.environment.corePackages; # ++ config.environment.defaultPackages;

    environment.pathsToLink = [
      "/bin"
      "/etc/xdg"
      "/lib" # FIXME: remove and update debug-info.nix
      "/sbin"
      "/share/emacs"
      "/share/hunspell"
      "/share/org"
      "/share/themes"
      "/share/vulkan"
      "/share/systemd"
      "/share/thumbnailers"
    ];

    system.path =
      let
        paths = config.environment.systemPackages;

        pathsFinal = map (
          pkg:
          with lib;

          if pkg.meta ? outputsToInstall then
            pkg.overrideAttrs (prev: {
              meta =
                let
                  oldMeta = prev.meta or (warn "[unmanned] ${pkg.name}\t has no prev.meta" pkg.meta);

                  newMeta = oldMeta // {
                    # overrideAttrs doesn't include everything, use pkg instead
                    outputsToInstall = remove "man" pkg.meta.outputsToInstall;
                  };
                in
                newMeta;
            })
          else
            warn "[unmanned] ${pkg.name}\t has no meta.outputsToInstall" pkg
        ) paths;

        # +------------------------------------------------------------+
        # ! Or just change the original check-meta.nix with rw-store.  !
        # ! If it complains about nixpkgs' narHash, then just          !
        # ! manually edit flake.lock to set it to the suggested value. !
        # +------------------------------------------------------------+

      in
      pkgs.buildEnv {
        name = "system-path-woke";
        paths = lib.trace "[unmanned] Constructing path..." pathsFinal;
        inherit (config.environment) pathsToLink;
        ignoreCollisions = true;
        # !!! Hacky, should modularise.
        # outputs TODO: note that the tools will often not be linked by default
        postBuild = ''
          # Remove wrapped binaries, they shouldn't be accessible via PATH.
          find $out/bin -maxdepth 1 -name ".*-wrapped" -type l -delete

          if [ -x $out/bin/glib-compile-schemas -a -w $out/share/glib-2.0/schemas ]; then
              $out/bin/glib-compile-schemas $out/share/glib-2.0/schemas
          fi

          ${config.environment.extraSetup}
        '';
      };

  };
}
