# Source this to get the FL Studio Wine environment (ARM64 Proton wine + FEX).
export FLBASE="${FLBASE:-$HOME/.local/share/flstudio}"
export WINEPREFIX="$FLBASE/prefix"
export PATH="$FLBASE/proton-arm64/files/bin-arm64:$PATH"
export DISPLAY="${DISPLAY:-:0}"
export WINEDEBUG="${WINEDEBUG:--all}"
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-winemenubuilder.exe=d}"

# Native Linux (XDG portal) file dialogs from the patched comdlg32 (see patches/).
# Forced, because FL Studio registers dialog event listeners, which makes the
# patch's "auto" mode fall back to Wine's own picker. Set to 0 to disable.
export WINE_FORCE_PORTAL="${WINE_FORCE_PORTAL:-1}"

# Audio routing. The "FL Studio ASIO" driver follows the default PulseAudio/PipeWire
# devices and its panel has no input picker under Wine. To pin FL to a specific
# interface, export FL_SINK / FL_SOURCE before launching (names from
# `pactl list short sinks` / `pactl list short sources`), or set them here.
if [ -n "${FL_SINK:-}" ]; then export PULSE_SINK="$FL_SINK"; fi
if [ -n "${FL_SOURCE:-}" ]; then export PULSE_SOURCE="$FL_SOURCE"; fi
