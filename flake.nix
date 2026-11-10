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
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "azoth-launcher";
          version = "1.0.29";

          # 1. Directly fetch the release asset archive.
          # Nix requires an explicit hash for fixed-output network fetches.
          src = pkgs.fetchurl {
            url = "https://github.com";
            hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Dummy hash to trigger Nix to give you the real one
          };

          buildInputs = with pkgs; [ webkitgtk_4_1 gtk3 glib umu-launcher ];

          dontStrip = true;
          dontBuild = true;

          # 2. Since it's a tar.gz, Nix unpacks it automatically into the build directory.
          # We just need to check what files came out of it and move them to $out/bin.
          unpackPhase = ''
            runHook preUnpack
            mkdir source
            tar -xzf $src -C source/
            cd source
            runHook postUnpack
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            
            # Copy everything extracted to our output bin directory
            cp -r * $out/bin/ 2>/dev/null || cp * $out/bin/
            
            # Normalize the binary name if needed
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
