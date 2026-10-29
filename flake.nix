{
  description = "Nix Flake to package and run Azoth Launcher on NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    azoth-src = {
      url = "github:KyzaBOY/azoth-launcher";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, azoth-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.buildGoModule {
          pname = "azoth-launcher";
          version = "unstable";

          src = azoth-src;

          # Your verified Nix Go modules vendor hash
          vendorHash = "sha256-ARz+96Uflh1rym7Qpa0BCWd1HIoGKeBwwjHyKWMmjY8=";

          nativeBuildInputs = with pkgs; [ pkg-config gcc gnumake ];
          buildInputs = with pkgs; [ webkitgtk_4_1 gtk3 ];

          doCheck = false;

          # We override the flags during the native Go build step to bake in the server data natively
          buildPhase = ''
            chmod +x scripts/release-linux.sh
            
            # 1. Run the base release preparation script
            PATCH_ONLY=1 scripts/release-linux.sh --no-server
            
            # 2. Re-compile the final main binary manually to override the variables via linker flags
            # NOTE: If you have your community's active game server IP, replace "127.0.0.1" with it below.
            echo "Baking custom server configuration directly into the compiled executable..."
            go build -tags="production" -ldflags "
              -X main.gatewayHost=127.0.0.1
              -X main.gatewayPort=6000
              -s -w
            " -o build/bin/AzothLauncher main.go app.go flow.go options_linux.go launch_linux.go

            # 3. Re-pack the tarball with our updated server-enabled binary
            cd build/bin
            tar -czf AzothLauncher-linux-x86_64.tar.gz AzothLauncher
            cd ../..
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
            exec ${pkgs.steam-run}/bin/steam-run ${self.packages.${system}.default}/bin/azoth-launcher "$@"
          ''}/bin/azoth-launcher-fhs";
        };
      }
    );
}
