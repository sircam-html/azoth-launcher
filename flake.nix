{
  description = "Azoth Launcher 1.0.30 (Windows build) running under Wine on NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        version = "1.0.30";

        # The 1.0.x line ships only a Windows installer (Electron app).
        # Swap the url for your own upload if you mirror the exe on GitHub,
        # and update the hash with: nix hash convert --to sri sha256 <file>
        src = pkgs.fetchurl {
          url = "https://github.com/KyzaBOY/azoth-launcher-releases/releases/download/v${version}/AzothLauncherSetup-${version}.exe";
          hash = "sha256-7FxJRAh48sYuBHzSZC6jmA68WcH0ncFGR3cG00G8E80=";
        };

        # An NSIS installer is not a runnable app: unpack the payload it
        # carries ($PLUGINSDIR/app-64.7z) instead of installing it.
        azoth = pkgs.stdenvNoCC.mkDerivation {
          pname = "azoth-launcher";
          inherit version src;

          nativeBuildInputs = [ pkgs.p7zip ];

          dontUnpack = true;

          installPhase = ''
            runHook preInstall
            mkdir -p "$out/share/azoth"
            tmp=$(mktemp -d)
            7z x -y -o"$tmp" "$src" >/dev/null
            payload=$(find "$tmp" -name 'app-64.7z' -print -quit)
            [ -n "$payload" ] || { echo "app-64.7z not found inside the installer"; exit 1; }
            7z x -y -o"$out/share/azoth" "$payload" >/dev/null
            chmod -R u+w "$out/share/azoth"
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Azoth Launcher (Windows build, runs under Wine)";
            platforms = [ "x86_64-linux" ];
          };
        };

        # Wine needs a writable prefix, so the app is copied there on first
        # run (also lets the launcher's own updater write to its folder).
        runner = pkgs.writeShellApplication {
          name = "azoth-launcher";
          runtimeInputs = [ pkgs.wineWow64Packages.stable pkgs.coreutils ];

          text = ''
            export WINEPREFIX="''${WINEPREFIX:-''${XDG_DATA_HOME:-$HOME/.local/share}/azoth-launcher-wine}"
            export WINEDEBUG="''${WINEDEBUG:--all}"
            export WINEDLLOVERRIDES="mscoree,mshtml="

            appdir="$WINEPREFIX/drive_c/AzothLauncher"
            if [ "$(cat "$appdir/.version" 2>/dev/null || true)" != "${version}" ]; then
              [ -d "$appdir" ] && chmod -R u+w "$appdir" || true
              rm -rf "$appdir"
              mkdir -p "$appdir"
              cp -a "${azoth}/share/azoth/." "$appdir/"
              chmod -R u+w "$appdir"
              printf '%s\n' "${version}" > "$appdir/.version"
            fi

            exec wine "$appdir/Azoth Launcher.exe" --no-sandbox --disable-gpu "$@"
          '';
        };
      in
      {
        packages.default = azoth;

        apps.default = {
          type = "app";
          program = "${runner}/bin/azoth-launcher";
        };
      });
}
