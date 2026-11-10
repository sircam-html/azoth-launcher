{
  description = "Nix Flake to package and run Azoth Launcher on NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    azoth-src = {
      url = "github:KyzaBOY/azoth-launcher-releases/v1.0.29";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, azoth-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "azoth-launcher";
          version = "1.0.29";

          src = azoth-src;

          # Runtime framework dependencies needed by the launcher's UI
          buildInputs = with pkgs; [ webkitgtk_4_1 gtk3 glib umu-launcher ];

          # Precompiled release archives are already optimized and must not be stripped
          dontStrip = true;

          # Removed buildPhase because the binaries are already built by upstream
          dontBuild = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            mkdir temp_extract
            
            # Find the Linux tarball inside the release repository bundle and unpack it
            tar -xzf build/bin/AzothLauncher-linux-x86_64.tar.gz -C temp_extract/
            cp -r temp_extract/*/* $out/bin/ 2>/dev/null || cp -r temp_extract/* $out/bin/
            
            # Rename the binary matching the rest of your app wrapper environment
            if [ -f $out/bin/AzothLauncher ]; then
              mv $out/bin/AzothLauncher $out/bin/azoth-launcher
            fi
            chmod +x $out/bin/azoth-launcher

            runHook postInstall
          '';
        };

        apps.default = {
          type = "app";
          program = "${pkgs.writeShellScriptBin "azoth-launcher-fhs" ''
            export PATH="${pkgs.umu-launcher}/bin:$PATH"
            exec ${pkgs.steam-run}/bin/steam-run ${self.packages.${system}.default}/bin/azoth-launcher "$@"
          ''}/bin/azoth-launcher-fhs";
        };
      }
    );
}
