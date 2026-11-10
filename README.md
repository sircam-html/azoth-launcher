# Nix Flake for Azoth Launcher

Nix flake that runs the official [Azoth Launcher](https://github.com/KyzaBOY/azoth-launcher-releases) for New World on NixOS.

The launcher is a Windows program, so this flake downloads the official installer, unpacks the app it carries, and runs it under Wine. Nothing is installed into your system: `nix run` fetches everything it needs, including its own Wine.

## Run it

```bash
nix run github:sircam-html/azoth-launcher
```

The same command works in `fish` and `bash`. No cloning required.

### Requirements

- `x86_64-linux`.
- Flakes enabled.
- A few GB of free disk space (Wine and its libraries, plus the launcher itself).
- An internet connection on the first run.
- A New World install; the launcher looks for `NewWorld.exe` inside `Bin64`.

### First run

Nix downloads Wine and the launcher, then the window opens. Choose your New World folder in Settings, log in with Discord, and press Play.

The first run also creates a Wine prefix in `~/.local/share/azoth-launcher-wine`, and the launcher copies itself there so its own updater can write to its folder. Your settings and Discord session live in that folder. To start from scratch, delete it.

Note that the game starts **inside that same Wine prefix**, not through umu/Proton as the old native build did. The first Play may take a while while the prefix is set up.

### Updating the launcher

Upstream publishes new versions as Windows installers. To bump:

1. Change `version = "1.0.29";` in `flake.nix` to the new version.
2. Change the `hash` for the new installer. If you leave the old one, the build fails and prints the correct hash; or compute it yourself:

   ```bash
   nix hash convert --to sri sha256 AzothLauncherSetup-<version>.exe
   ```

Everything else stays the same. The URL follows the version.

## Package

The default package is the unpacked Windows app, not a native binary:

```bash
nix build github:sircam-html/azoth-launcher
ls result/share/azoth
```

To run it, use `nix run` (it sets up Wine and the prefix for you):

```bash
nix run github:sircam-html/azoth-launcher
```

## Notes

- The 1.0.x line is a Windows-only Electron app: upstream ships no Linux build and no updated Linux source. This flake runs the official Windows build instead of compiling from source.
- The flake brings its own `wineWow64Packages.stable`. A 32-bit Wine cannot start the 64-bit launcher (`Bad EXE format`), so don't rely on a Wine from your profile.
- The installer is never executed: the flake extracts the `app-64.7z` payload from the NSIS installer at build time. If upstream ever changes the installer format, that step is the one to adjust.
- The launcher's server (gateway) is baked in by upstream, so this flake does not control it. The flake is meant for the project's live playtests.
- The launcher runs with `--no-sandbox --disable-gpu` under Wine. They are harmless for a launcher window and avoid Chromium/Wine graphics issues.
