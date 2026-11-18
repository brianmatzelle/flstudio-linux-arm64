#!/bin/bash
# Build the patched Wine DLLs (crypt32, comdlg32, shell32) for the ARM64 Proton
# copy made by install.sh, and install them. Stock files are kept as *.orig.
#
# Needs: git, curl, make, gcc, autoconf, flex, bison, pkg-config, libdbus-1-dev.
# Takes a few minutes and about 6 GB under $FLBASE/build.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
export FLBASE="${FLBASE:-$HOME/.local/share/flstudio}"
WINE_TAG="${WINE_TAG:-proton-wine-11.0-2e}"
LLVM_MINGW_URL="${LLVM_MINGW_URL:-https://github.com/mstorsjo/llvm-mingw/releases/download/20261104/llvm-mingw-20261104-ucrt-ubuntu-22.04-aarch64.tar.xz}"
B="$FLBASE/build"
LIB="$FLBASE/proton-arm64/files/lib/wine"
SYS32="$FLBASE/prefix/drive_c/windows/system32"

[ -d "$LIB/aarch64-windows" ] || { echo "Run install.sh first ($LIB not found)." >&2; exit 1; }
mkdir -p "$B"; cd "$B"

if [ ! -d llvm-mingw ]; then
  curl -fsSL -o llvm-mingw.tar.xz "$LLVM_MINGW_URL"
  mkdir llvm-mingw && tar -xf llvm-mingw.tar.xz -C llvm-mingw --strip-components=1
  rm llvm-mingw.tar.xz
fi
export PATH="$B/llvm-mingw/bin:$PATH"

if [ ! -d wine ]; then
  git clone -q --depth 1 --branch "$WINE_TAG" https://github.com/ValveSoftware/wine wine
  for p in "$HERE"/patches/*.patch; do
    echo "Applying $(basename "$p")"
    git -C wine apply "$p"
  done
  ( cd wine && autoreconf -f && dlls/winevulkan/make_vulkan && tools/make_requests && tools/make_specfiles )
fi

mkdir -p obj; cd obj
[ -f Makefile ] || ../wine/configure --enable-archs=aarch64,arm64ec --disable-tests \
  --without-x --without-freetype --without-wayland --without-gstreamer \
  --without-pulse --without-alsa --without-vulkan --without-opengl
make -j"$(nproc)" \
  dlls/crypt32/aarch64-windows/crypt32.dll \
  dlls/comdlg32/aarch64-windows/comdlg32.dll dlls/comdlg32/comdlg32.so \
  dlls/shell32/aarch64-windows/shell32.dll

# Install. Replace by rename so a running FL Studio keeps its old copy until restart.
for d in crypt32 comdlg32 shell32; do
  for dir in "$LIB/aarch64-windows" "$SYS32"; do
    [ -e "$dir/$d.dll" ] || continue
    [ -e "$dir/$d.dll.orig" ] || cp -p "$dir/$d.dll" "$dir/$d.dll.orig"
    cp "dlls/$d/aarch64-windows/$d.dll" "$dir/$d.dll.new"
    chmod 755 "$dir/$d.dll.new"
    mv "$dir/$d.dll.new" "$dir/$d.dll"
  done
done
install -m 755 dlls/comdlg32/comdlg32.so "$LIB/aarch64-unix/comdlg32.so"

echo "Patched DLLs installed. Restart FL Studio to load them."
