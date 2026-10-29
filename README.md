# azoth-launcher

Nix flake that packages and runs the [Azoth Launcher](https://github.com/KyzaBOY/azoth-launcher) for New World on NixOS.

## Run it

```bash
NIXPKGS_ALLOW_UNFREE=1 nix run github:sircam-html/azoth-launcher --impure
```

The same command works in `fish` and `bash`. No cloning required: Nix fetches the flake, builds the launcher, and runs it.

### Requirements

- `x86_64-linux` (the flake only defines that system).
- Flakes enabled.
- About 2 GB of free disk space (build dependencies, umu runtime and Proton prefix).
- An internet connection on the first run.
- A New World install; the launcher looks for `NewWorld.exe` inside `Bin64`.

### First run

The first run builds the Wails launcher, so it takes a few minutes. Once the window opens, choose your New World folder in Settings, log in with Discord, and press Play.

The first Play shows `Setting up Proton (first time only)…` while umu-launcher creates the Wine prefix and downloads the Proton runtime. This is expected and can take a few minutes; later runs start much faster.

## Package

The launcher is available as the default package:

```bash
nix build github:sircam-html/azoth-launcher
./result/bin/azoth-launcher
```

The output contains `azoth-launcher`, `azoth-patcher.exe`, the `.desktop` file and the icon.

## Notes

- The game server (gateway) is baked into the launcher at build time by upstream's `scripts/release-linux.sh`, so it cannot be changed from the launcher's settings. The current build points at `127.0.0.1:6000`; edit `GATEWAY_HOST` / `GATEWAY_PORT` in `flake.nix` to target another server.
- `dontStrip = true` is intentional: Nix's strip hook rewrites `azoth-patcher.exe`, which would no longer match the sha256 baked into the launcher and Play would refuse to start the game.
- The launcher runs inside an FHS environment (`steam-run`) with `umu-launcher` on `PATH`, because it needs both WebKitGTK and Wine/Proton at runtime.
