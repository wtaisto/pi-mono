# Install (fork: wtaisto/pi-mono)

This fork ships prebuilt `pi` binaries via GitHub Releases. The `build-binaries.yml` workflow runs on every `v*` tag push and uploads archives for darwin-arm64, darwin-x64, linux-x64, linux-arm64, and windows-x64.

## One-liner

**macOS / Linux**

```sh
curl -fsSL https://raw.githubusercontent.com/wtaisto/pi-mono/main/install.sh | sh
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/wtaisto/pi-mono/main/install.ps1 | iex
```

After install, open a new shell so `pi` is on PATH, then `pi --version`.

## Pin a specific version

Both installers accept a `PI_VERSION` env var (a release tag, e.g. `v0.72.1`):

```sh
PI_VERSION=v0.72.1 curl -fsSL https://raw.githubusercontent.com/wtaisto/pi-mono/main/install.sh | sh
```

```powershell
$env:PI_VERSION = 'v0.72.1'; irm https://raw.githubusercontent.com/wtaisto/pi-mono/main/install.ps1 | iex
```

## Custom install location

| Variable          | Default (Unix)            | Default (Windows)                       |
|-------------------|---------------------------|-----------------------------------------|
| `PI_INSTALL_DIR`  | `$HOME/.local/share/pi`   | `%LOCALAPPDATA%\Programs\pi`            |
| `PI_BIN_DIR`      | `$HOME/.local/bin`        | (same as `PI_INSTALL_DIR`, added to PATH) |
| `PI_REPO`         | `wtaisto/pi-mono`         | `wtaisto/pi-mono`                       |

## Manual install

If you'd rather not pipe a script to a shell:

1. Grab the archive for your platform from <https://github.com/wtaisto/pi-mono/releases/latest>.
   - Unix: `pi-<platform>.tar.gz` extracts to a `pi/` directory containing the `pi` binary and assets.
   - Windows: `pi-windows-x64.zip` extracts `pi.exe` and assets at the zip root.
2. Move that directory anywhere on disk.
3. Put the `pi` (or `pi.exe`) binary on your PATH — either symlink it into a bin dir or add the install directory to PATH.

## Upgrade

Re-run the one-liner. The installer wipes the previous install directory before extracting the new archive, so it's safe to re-run.

## Uninstall

```sh
rm -rf "$HOME/.local/share/pi" "$HOME/.local/bin/pi"
```

```powershell
Remove-Item -Recurse -Force (Join-Path $env:LOCALAPPDATA 'Programs\pi')
# Then remove that path from your user PATH via System Properties or:
#   [Environment]::SetEnvironmentVariable('Path', (([Environment]::GetEnvironmentVariable('Path','User') -split ';') -ne (Join-Path $env:LOCALAPPDATA 'Programs\pi') -join ';'), 'User')
```
