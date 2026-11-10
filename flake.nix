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

        envOr = name: fallback:
          let value = builtins.getEnv name;
          in if value == "" then fallback else value;
        gatewayHost = envOr "AZOTH_GATEWAY_HOST" "127.0.0.1";
        gatewayPort = envOr "AZOTH_GATEWAY_PORT" "6000";
      in
      {
        # Changed from pkgs.buildGoModule to pkgs.stdenv.mkDerivation
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "azoth-launcher";
          version = "1.0.29";

          src = azoth-src;

          # We only need native build tools for the release script inside the repo
          nativeBuildInputs = with pkgs; [ pkg-config gcc gnumake ];
          buildInputs = with pkgs; [ webkitgtk_4_1 gtk3 glib umu-launcher ];

          # Go specific flags removed since we aren't compiling anymore
          dontStrip = true;

          buildPhase = ''
            runHook preBuild
            
            chmod +x scripts/release-linux.sh
            
            echo "GATEWAY_HOST=${gatewayHost}" > release.env
            echo "GATEWAY_PORT=${gatewayPort}" >> release.env
            
            PATCH_ONLY=1 scripts/release-linux.sh
            
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            mkdir temp_extract
            tar -xzf build/bin/AzothLauncher-linux-x86_64.tar.gz -C temp_extract/
            cp -r temp_extract/*/* $out/bin/ 2>/dev/null || cp -r temp_extract/* $out/bin/
            
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
