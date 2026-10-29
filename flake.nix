{
  description = "Nix Flake to package and run Azoth Launcher on NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # Pointing directly to the upstream original source repository
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

          # Nix requires a hash for Go modules.
          vendorHash = "sha256-ARz+96Uflh1rym7Qpa0BCWd1HIoGKeBwwjHyKWMmjY8=";

          nativeBuildInputs = with pkgs; [ pkg-config gcc gnumake ];
          buildInputs = with pkgs; [ webkitgtk_4_1 gtk3 ];

          # Disable internal Nix Go testing since we are using a custom release script
          doCheck = false;

          # Replicating the behavior of the original release script
          buildPhase = ''
            chmod +x scripts/release-linux.sh
            PATCH_ONLY=1 scripts/release-linux.sh --no-server
          '';

          # Bypassing the tarball extraction issues by moving compiled assets straight from build/bin
          installPhase = ''
            mkdir -p $out/bin
            
            # Extract the native tarball built during the buildPhase to see what's inside
            mkdir temp_extract
            tar -xzf build/bin/AzothLauncher-linux-x86_64.tar.gz -C temp_extract/
            
            # Copy absolutely everything found inside the extraction folder directly into the outputs
            cp -r temp_extract/*/* $out/bin/ 2>/dev/null || cp -r temp_extract/* $out/bin/
            
            # Rename the binary uniformly to lower-case 'azoth-launcher' to avoid naming or casing conflicts
            if [ -f $out/bin/AzothLauncher ]; then
              mv $out/bin/AzothLauncher $out/bin/azoth-launcher
            fi
            
            # Ensure proper execution permissions are set
            chmod +x $out/bin/azoth-launcher
          '';
        };

        # Defining the executable app by automatically wrapping it inside a steam-run FHS environment
        apps.default = {
          type = "app";
          program = "${pkgs.writeShellScriptBin "azoth-launcher-fhs" ''
            # Execute the uniformly named lower-case binary directly under steam-run FHS
            exec ${pkgs.steam-run}/bin/steam-run ${self.packages.${system}.default}/bin/azoth-launcher "$@"
          ''}/bin/azoth-launcher-fhs";
        };
      }
    );
}
