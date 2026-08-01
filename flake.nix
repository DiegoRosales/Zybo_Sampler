{
  description = "HLS Examples";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, pyproject-nix, ... }:
    let
      # Xilinx tools only ship for x86_64-linux
      system = "x86_64-linux";
      lz4Overlay = final: prev: {
        lz4 = prev.lz4.overrideAttrs (old: {
          postInstall = (old.postInstall or "") + ''
            ln -s $out/bin/lz4 $out/bin/lz4c
          '';
        });
      };
      pkgs = import nixpkgs { inherit system; overlays = [ lz4Overlay ]; };
      ccSalt = pkgs.stdenv.cc.suffixSalt;

      # Pin the host/native compiler to GCC 14. nixpkgs-unstable now ships
      # GCC 15, which defaults to C23 where `bool`/`true`/`false` are keywords;
      # that breaks older-style build-host helper tools in poky scarthgap
      # (e.g. ghostscript's `typedef int bool;`). wrapCCMulti keeps multilib and
      # the cc-wrapper glibc/crt injection that host-tool builds rely on.
      # (suffixSalt is platform-derived, so ccSalt above is unchanged.)
      gccMulti14 = pkgs.wrapCCMulti pkgs.gcc14;

      # Parse requirements.txt and render into a Python environment.
      # validateVersionConstraints is skipped because requirements.txt uses
      # exact pins (==) that are unlikely to match nixpkgs versions exactly.
      project = pyproject-nix.lib.project.loadRequirementsTxt { projectRoot = ./.; };
      # packageOverrides = pkgs.callPackage ./python-packages.nix {};
      # python = pkgs.python312.override { inherit packageOverrides; };
      python = pkgs.python313;
      pythonEnv = python.withPackages (
        project.renderers.withPackages { inherit python; }
      );
    in {
      devShells.${system} = {

        # FHS sandbox for running Xilinx tools (Vivado, Vitis HLS, etc.)
        # Xilinx installers and binaries expect a conventional /usr/lib layout
        # that NixOS does not provide natively; buildFHSEnv creates that layout.
        # Usage: nix develop .#xilinx
        default = (pkgs.buildFHSEnv {
          name = "xilinx-env";
          targetPkgs = pkgs: with pkgs; [
            ncurses5
            ncurses
            libxcrypt-legacy
            libpng
            libusb1
            systemd
            pixman
            zlib
            libuuid
            bash
            coreutils
            xorg.libXext
            xorg.libX11
            xorg.libXrender
            xorg.libXtst
            xorg.libXi
            xorg.libXft
            xorg.libxcb
            freetype
            fontconfig
            glib
            gtk2
            gtk3
            graphviz
            # Use the *wrapped* toolchain (gcc_multi and binutils are
            # cc-wrapper / binutils-wrapper scripts). The wrappers inject the
            # -B<glibc>/lib, crt paths (Scrt1.o, crti.o), -lgcc_s and
            # dynamic-linker flags by reading the NIX_* env vars set in
            # `profile`. The raw, unwrapped compiler (stdenv.cc.cc) ignores
            # those vars and cannot locate the Nix-store glibc startup files,
            # which breaks host-tool builds like u-boot's fixdep. stdenv.cc.cc
            # is deliberately NOT listed so it doesn't shadow the wrapper at
            # /usr/bin/gcc; stdenv.cc.cc.lib (runtime libs only) is kept.
            gccMulti14
            binutils
            glibc
            glibc.dev
            stdenv.cc.cc.lib
            zstd
            unzip
            nettools
            verilator
            pythonEnv
            gitRepo
            chrpath
            diffstat
            lz4
            rpcsvc-proto
            parted
            git
            clang-tools
            # openssl: used by the Makefile 'root-password' stage to hash the
            # LINUX_EDF_PASSWORD. Having it on PATH here avoids an ad-hoc
            # `nix-shell -p openssl`, whose first-run progress bar can corrupt
            # the terminal.
            openssl
            # curl: used to fetch PyPI sdists when authoring python recipes
            # (checksums/license files for meta-hls-pynq's Stage 2 recipes).
            curl
            # perl: OE's rpm packaging runs the host's /usr/bin/perl (perl.prov
            # shebang) to compute Perl provides for packages shipping .pl files.
            # Without it, do_package fails with "Couldn't exec .../perl.prov: No
            # such file or directory" (really the missing shebang interpreter).
            perl
            # wic cp toolchain: the Makefile copy-boot-bin target runs `wic cp`
            # from the sourced build env (not a bitbake task), so it needs these
            # host tools on PATH. e2fsprogs provides `debugfs` for writing into
            # the ext4 rootfs partition (:3); mtools/dosfstools handle the vfat
            # boot partition (:1). Without debugfs: "Can't find executable
            # 'debugfs'". nixpkgs e2fsprogs (1.47.4) >= the image's (1.47.0), so
            # it understands the image's ext4 features.
            e2fsprogs
            mtools
            dosfstools
           # Extra stuff for Vitis IDE
            # For future reference, when it silently fails to launch, run:
            # RDI_VERBOSE=True vitis
            nss
            nspr
            dbus
            atk
            cups
            libdrm
            pango
            cairo
            libxcomposite
            libxdamage
            libxfixes
            libxrandr
            libgbm
            expat
            libxkbcommon
            libxkbfile
            alsa-lib
            libGL
           ];
          profile = ''
            export LD_LIBRARY_PATH=/usr/lib:/usr/lib64:$LD_LIBRARY_PATH

            # BitBake strips unknown env vars before forking subprocesses.
            # The NixOS gcc wrapper needs these to locate glibc startup files
            # (Scrt1.o, crti.o) and libgcc_s in the Nix store — without them
            # host-tool compilation (e.g. u-boot fixdep) fails.
            export NIX_DONT_SET_RPATH_${ccSalt}=1
            export NIX_DYNAMIC_LINKER_${ccSalt}=/lib/ld-linux-x86-64.so.2
            export BB_ENV_PASSTHROUGH_ADDITIONS="NIX_LDFLAGS NIX_CFLAGS_COMPILE NIX_CFLAGS_LINK NIX_CC_WRAPPER_TARGET_HOST_${ccSalt} NIX_DONT_SET_RPATH_${ccSalt} NIX_DYNAMIC_LINKER_${ccSalt}"
          '';
          runScript = ''
            env LIBRARY_PATH=/usr/lib \
                CMAKE_LIBRARY_PATH=/usr/lib \
                CMAKE_INCLUDE_PATH=/usr/include \
                bash
          '';
        }).env;

      };
    };
}
