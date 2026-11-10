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

            TARGET_BIN="$DATA_DIR/azoth-launcher"

            # Download the binary directly if it doesn't exist
            if [ ! -f "$TARGET_BIN" ]; then
              echo "Downloading Azoth Launcher v1.0.29 executable directly to your home directory..."
              ${pkgs.curl}/bin/curl -L "https://github.com" -o "$TARGET_BIN"
            fi

            # Ensure it has execution permissions
            chmod +x "$TARGET_BIN"

            export PATH="${pkgs.umu-launcher}/bin:$PATH"
            cd "$DATA_DIR"
            
            echo "Launching via steam-run FHS layout..."
            exec ${pkgs.steam-run}/bin/steam-run "$TARGET_BIN" "$@"
          ''}/bin/azoth-launcher-fhs";
        };
      }
    );
}
