#!/bin/bash
# Set up FL Studio on ARM64 Linux using Steam's "Proton 11.0 (ARM64)" wine.
#
#   ./install.sh [path/to/flstudio_win64_<version>.exe]
#
# Without an installer argument it only prepares Wine, the prefix and the launchers.
# Environment overrides: FLBASE (default ~/.local/share/flstudio), PROTON_SRC,
# BIN_DIR (default ~/.local/bin), APP_DIR (default ~/.local/share/applications).
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
export FLBASE="${FLBASE:-$HOME/.local/share/flstudio}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
APP_DIR="${APP_DIR:-$HOME/.local/share/applications}"
INSTALLER="${1:-}"

[ "$(uname -m)" = aarch64 ] || { echo "This setup is for aarch64 hosts (found $(uname -m))." >&2; exit 1; }

# 1. A private copy of Steam's ARM64 Proton (Steam is not needed afterwards).
if [ ! -d "$FLBASE/proton-arm64" ]; then
  if [ -z "${PROTON_SRC:-}" ]; then
    for d in "$HOME/snap/steam/common/.local/share/Steam" "$HOME/.local/share/Steam" "$HOME/.steam/steam"; do
      [ -d "$d/steamapps/common/Proton 11.0 (ARM64)" ] && PROTON_SRC="$d/steamapps/common/Proton 11.0 (ARM64)" && break
    done
  fi
  [ -n "${PROTON_SRC:-}" ] && [ -x "$PROTON_SRC/files/bin-arm64/wine" ] || {
    echo "Could not find 'Proton 11.0 (ARM64)'. Install it from Steam (Library > Tools)," >&2
    echo "or set PROTON_SRC to its directory." >&2; exit 1; }
  echo "Copying Proton from $PROTON_SRC"
  mkdir -p "$FLBASE"
  cp -a "$PROTON_SRC" "$FLBASE/proton-arm64"
fi

# 2. Environment file, launchers, desktop entries.
mkdir -p "$BIN_DIR" "$APP_DIR" "$FLBASE/installer"
[ -e "$FLBASE/env.sh" ] || install -m 644 "$HERE/share/env.sh" "$FLBASE/env.sh"
install -m 755 "$HERE/bin/flstudio" "$HERE/bin/flstudio-url" "$BIN_DIR/"
for f in flstudio flstudio-url-handler; do
  sed "s|@BIN@|$BIN_DIR|" "$HERE/share/$f.desktop.in" > "$APP_DIR/$f.desktop"
done
update-desktop-database "$APP_DIR" 2>/dev/null || true
xdg-mime default flstudio-url-handler.desktop x-scheme-handler/flstudio 2>/dev/null || true

# 3. Wine prefix, with the home directory mapped as drive H:.
. "$FLBASE/env.sh"
if [ ! -d "$WINEPREFIX/drive_c" ]; then
  echo "Creating Wine prefix in $WINEPREFIX"
  wine wineboot -i
  wineserver -w
fi
ln -sfn "$HOME" "$WINEPREFIX/dosdevices/h:"

# 4. FL Studio itself (silent NSIS install).
if [ -n "$INSTALLER" ]; then
  [ -f "$INSTALLER" ] || { echo "No such installer: $INSTALLER" >&2; exit 1; }
  echo "Installing $(basename "$INSTALLER") (several minutes, no window is shown)"
  rc=0; wine "$INSTALLER" /S >"$FLBASE/install.log" 2>&1 || rc=$?
  wineserver -w
  # The installer exits with 199 under Wine even when it succeeds.
  ls "$WINEPREFIX/drive_c/Program Files/Image-Line/"FL\ Studio*/FL64.exe >/dev/null 2>&1 || {
    echo "Install failed (exit $rc), see $FLBASE/install.log" >&2; exit 1; }
  echo "FL Studio installed."
fi

cat <<EOF

Done. Next:
  1. ./build-wine-dlls.sh     (needed for FL Studio 26.1.4 and newer, and for native file dialogs)
  2. $BIN_DIR/flstudio
EOF
