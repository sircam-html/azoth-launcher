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

          src = pkgs.fetchurl {
            url = "https://github.com";
            hash = "sha256-hzk/sRRsECdWLA69hDhFx8X5O9JYZVR80XXMVTV4cag="; # Updated to the correct hash
          };

          buildInputs = with pkgs; [ webkitgtk_4_1 gtk3 glib umu-launcher ];

          dontStrip = true;
          dontBuild = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            
            # Copy everything extracted out of the tarball to our output bin directory
            cp -r * $out/bin/ 2>/dev/null || cp * $out/bin/
            
            # Normalize the binary name if it exists inside the release structure
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
