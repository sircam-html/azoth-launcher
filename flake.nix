{
  description = "Nix Flake to package and run Azoth Launcher on NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # This keeps a clean, read-only copy of the raw unpacked files in the nix store
        azoth-unpacked = pkgs.stdenv.mkDerivation {
          pname = "azoth-launcher-base";
          version = "1.0.29";

          src = pkgs.fetchurl {
            url = "https://github.com";
            hash = "sha256-sQekjE132mwVpPwUoObttl1hSJvYo29EQm401idQWP4=";
          };

          dontStrip = true;
          dontBuild = true;

          installPhase = ''
            mkdir -p $out/share/azoth
            cp -r * $out/share/azoth/
          '';
        };
      in
      {
        packages.default = azoth-unpacked;

        apps.default = {
          type = "app";
          program = "${pkgs.writeShellScriptBin "azoth-launcher-fhs" ''
            # Create a dedicated, writeable workspace for the launcher installer in your home folder
            DATA_DIR="$HOME/.local/share/azoth-launcher"
            mkdir -p "$DATA_DIR"

            # Sync the fresh files from the Nix Store into the writeable home folder 
            # (skip overriding user configuration logs or downloaded components)
            echo "Syncing Azoth Launcher 1.0.29 environment to $DATA_DIR..."
            cp -rn ${azoth-unpacked}/share/azoth/* "$DATA_DIR/"
            chmod -R u+w "$DATA_DIR"

            # Point to the binary target in the writeable directory
            TARGET_BIN="$DATA_DIR/AzothLauncher"
            if [ ! -f "$TARGET_BIN" ] && [ -f "$DATA_DIR/azoth-launcher" ]; then
              TARGET_BIN="$DATA_DIR/azoth-launcher"
            fi

            # Export the path configurations for execution context
            export PATH="${pkgs.umu-launcher}/bin:$PATH"
            
            # Change directory to the writeable workspace so the installer can unpack files locally
            cd "$DATA_DIR"
            
            echo "Launching via steam-run FHS context..."
            exec ${pkgs.steam-run}/bin/steam-run "$TARGET_BIN" "$@"
          ''}/bin/azoth-launcher-fhs";
        };
      }
    );
}
