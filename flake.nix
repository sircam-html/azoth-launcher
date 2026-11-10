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
      in
      {
        packages.default = pkgs.writeShellScriptBin "azoth-launcher" ''
          echo "Checking launcher status..."
        '';

        apps.default = {
          type = "app";
          program = "${pkgs.writeShellScriptBin "azoth-launcher-fhs" ''
            DATA_DIR="$HOME/.local/share/azoth-launcher"
            mkdir -p "$DATA_DIR"

            INSTALLER_SCRIPT="$DATA_DIR/azoth-installer.sh"

            # Download the installer script directly if it isn't there
            if [ ! -f "$INSTALLER_SCRIPT" ]; then
              echo "Downloading Azoth Launcher v1.0.29 installation script..."
              ${pkgs.curl}/bin/curl -L "https://github.com" -o "$INSTALLER_SCRIPT"
            fi

            chmod +x "$INSTALLER_SCRIPT"

            export PATH="${pkgs.umu-launcher}/bin:$PATH"
            cd "$DATA_DIR"
            
            echo "Executing installer within steam-run FHS sandbox..."
            # We run it with 'sh' explicitly so Linux treats it as a script
            exec ${pkgs.steam-run}/bin/steam-run sh "$INSTALLER_SCRIPT" "$@"
          ''}/bin/azoth-launcher-fhs";
        };
      }
    );
}
