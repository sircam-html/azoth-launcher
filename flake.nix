{
  description = "Nix Flake to package and run Azoth Launcher on NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # 1. Pointed to the releases repository and explicitly locked to v1.0.29
    azoth-src = {
      url = "github:KyzaBOY/azoth-launcher-releases/v1.0.29";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, azoth-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Gateway baked into the launcher at build time by release-linux.sh.
        # Override it for a playtest without editing this file (the runner
        # needs --impure for getEnv to see the variables):
        #   AZOTH_GATEWAY_HOST=1.2.3.4 AZOTH_GATEWAY_PORT=6000 nix run ... --impure
        envOr = name: fallback:
          let value = builtins.getEnv name;
          in if value == "" then fallback else value;
        gatewayHost = envOr "AZOTH_GATEWAY_HOST" "127.0.0.1";
        gatewayPort = envOr "AZOTH_GATEWAY_PORT" "6000";
      in
      {
        packages.default = pkgs.buildGoModule {
          pname = "azoth-launcher";
          version = "1.0.29"; # 2. Updated version string

          src = azoth-src;

          # 3. Reset vendorHash so Nix automatically fetches the new module dependencies
          vendorHash = pkgs.lib.fakeHash; 

          nativeBuildInputs = with pkgs; [ pkg-config gcc gnumake ];
          buildInputs = with pkgs; [ webkitgtk_4_1 gtk3 glib umu-launcher ];

          doCheck = false;

          # Skipping strip since binaries are built with -s -w
          dontStrip = true;

          buildPhase = ''
            chmod +x scripts/release-linux.sh
            
            # Inject the release.env file required by their build system.
            echo "GATEWAY_HOST=${gatewayHost}" > release.env
            echo "GATEWAY_PORT=${gatewayPort}" >> release.env
            
            PATCH_ONLY=1 scripts/release-linux.sh
          '';

          installPhase = ''
            mkdir -p $out/bin
            mkdir temp_extract
            tar -xzf build/bin/AzothLauncher-linux-x86_64.tar.gz -C temp_extract/
            cp -r temp_extract/*/* $out/bin/ 2>/dev/null || cp -r temp_extract/* $out/bin/
            
            if [ -f $out/bin/AzothLauncher ]; then
              mv $out/bin/AzothLauncher $out/bin/azoth-launcher
            fi
            chmod +x $out/bin/azoth-launcher
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
