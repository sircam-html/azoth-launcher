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
        
        azoth-unpacked = pkgs.stdenv.mkDerivation {
          pname = "azoth-launcher-base";
          version = "1.0.29";

          src = pkgs.fetchurl {
            url = "https://github.com";
            hash = "sha256-asm8c3wTY7wqQvN7v/UUy+U1AQSeJI81ejdxv5RwL08="; # Swapped with the correct hash
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
            DATA_DIR="$HOME/.local/share/azoth-launcher"
            mkdir -p "$DATA_DIR"

            echo "Syncing Azoth Launcher 1.0.29 environment to $DATA_DIR..."
            cp -rn ${azoth-unpacked}/share/azoth/* "$DATA_DIR/"
            chmod -R u+w "$DATA_DIR"

            TARGET_BIN="$DATA_DIR/AzothLauncher"
            if [ ! -f "$TARGET_BIN" ] && [ -f "$DATA_DIR/azoth-launcher" ]; then
              TARGET_BIN="$DATA_DIR/azoth-launcher"
            fi

            export PATH="${pkgs.umu-launcher}/bin:$PATH"
            
            cd "$DATA_DIR"
            
            echo "Launching via steam-run FHS context..."
            exec ${pkgs.steam-run}/bin/steam-run "$TARGET_BIN" "$@"
          ''}/bin/azoth-launcher-fhs";
        };
      }
    );
}
