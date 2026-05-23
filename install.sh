#!/bin/sh
# Install pi (fork: wtaisto/pi-mono) from GitHub Releases.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/wtaisto/pi-mono/main/install.sh | sh
#
# Environment overrides:
#   PI_VERSION       Release tag to install (e.g. v0.72.1). Default: latest.
#   PI_INSTALL_DIR   Where the pi distribution is unpacked. Default: $HOME/.local/share/pi
#   PI_BIN_DIR       Where the `pi` symlink lives. Default: $HOME/.local/bin
#   PI_REPO          GitHub repo (owner/name). Default: wtaisto/pi-mono

set -eu

REPO="${PI_REPO:-wtaisto/pi-mono}"
VERSION="${PI_VERSION:-latest}"
INSTALL_DIR="${PI_INSTALL_DIR:-$HOME/.local/share/pi}"
BIN_DIR="${PI_BIN_DIR:-$HOME/.local/bin}"

uname_s="$(uname -s)"
uname_m="$(uname -m)"
case "$uname_s" in
    Darwin)
        case "$uname_m" in
            arm64|aarch64) platform=darwin-arm64 ;;
            x86_64) platform=darwin-x64 ;;
            *) echo "Unsupported macOS arch: $uname_m" >&2; exit 1 ;;
        esac
        ;;
    Linux)
        case "$uname_m" in
            x86_64) platform=linux-x64 ;;
            aarch64|arm64) platform=linux-arm64 ;;
            *) echo "Unsupported Linux arch: $uname_m" >&2; exit 1 ;;
        esac
        ;;
    *)
        echo "Unsupported OS: $uname_s. Use install.ps1 on Windows." >&2
        exit 1
        ;;
esac

archive="pi-${platform}.tar.gz"
if [ "$VERSION" = "latest" ]; then
    url="https://github.com/${REPO}/releases/latest/download/${archive}"
else
    url="https://github.com/${REPO}/releases/download/${VERSION}/${archive}"
fi

echo "==> Downloading ${url}"

tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t pi-install)"
trap 'rm -rf "$tmpdir"' EXIT INT TERM

if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$tmpdir/$archive"
elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$tmpdir/$archive" "$url"
else
    echo "Need curl or wget on PATH." >&2
    exit 1
fi

echo "==> Extracting"
tar -xzf "$tmpdir/$archive" -C "$tmpdir"
# build-binaries.sh wraps the payload in a top-level `pi/` directory.
if [ ! -d "$tmpdir/pi" ]; then
    echo "Unexpected archive layout (no pi/ directory inside ${archive})." >&2
    exit 1
fi

mkdir -p "$(dirname "$INSTALL_DIR")"
rm -rf "$INSTALL_DIR"
mv "$tmpdir/pi" "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/pi"

mkdir -p "$BIN_DIR"
ln -sf "$INSTALL_DIR/pi" "$BIN_DIR/pi"

echo "==> Installed pi to $INSTALL_DIR"
echo "==> Linked $BIN_DIR/pi -> $INSTALL_DIR/pi"

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        echo ""
        echo "NOTE: $BIN_DIR is not on your PATH. Add to your shell rc:"
        echo "  export PATH=\"$BIN_DIR:\$PATH\""
        ;;
esac

echo ""
"$INSTALL_DIR/pi" --version 2>/dev/null || true
