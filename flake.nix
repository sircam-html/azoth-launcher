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

          vendorHash = "sha256-ARz+96Uflh1rym7Qpa0BCWd1HIoGKeBwwjHyKWMmjY8=";

          nativeBuildInputs = with pkgs; [ pkg-config gcc gnumake ];
          # Added umu-launcher to build dependencies
          buildInputs = with pkgs; [ webkitgtk_4_1 gtk3 glib umu-launcher ];

          doCheck = false;

          # release-linux.sh bakes the sha256 of azoth-patcher.exe into the
          # launcher. The stdenv strip hook rewrites every file in bin/,
          # including the Windows PE helper, which changes its bytes and makes
          # the launcher reject it at runtime ("azoth-patcher.exe does not
          # match this launcher"). Both Go binaries are already built with
          # -s -w, so skipping strip costs nothing.
          dontStrip = true;

          buildPhase = ''
            chmod +x scripts/release-linux.sh
            
            # Inject the release.env file required by their build system
            echo "GATEWAY_HOST=127.0.0.1" > release.env
            echo "GATEWAY_PORT=6000" >> release.env
            
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
            # We explicitly inject umu-launcher into the execution PATH inside the FHS sandbox
            export PATH="${pkgs.umu-launcher}/bin:$PATH"
            exec ${pkgs.steam-run}/bin/steam-run ${self.packages.${system}.default}/bin/azoth-launcher "$@"
          ''}/bin/azoth-launcher-fhs";
        };
      }
    );
}
