# flstudio-linux-arm64

Scripts, Wine patches and notes for running **FL Studio 2026 on ARM64 (aarch64) Linux**.

FL Studio is a Windows x86-64 program. Here it runs through the ARM64 build of Valve's
Proton (Wine 11 with the FEX emulator in ARM64EC mode), used directly as a plain Wine,
without Steam at runtime and without root.

This repository does **not** contain FL Studio, Wine or any binaries. You need your own
FL Studio installer and licence from [Image-Line](https://www.image-line.com/).
This project is not affiliated with or endorsed by Image-Line.

## Status

Tested on one machine: Ubuntu 24.04 (aarch64, glibc 2.39), Xorg with the i3 window
manager, PipeWire, FL Studio 26.1.7.

| Works | Notes |
|---|---|
| Install, launch, account sign-in/unlock | Unlock needs the `flstudio://` link handler installed by `install.sh` |
| Audio playback and recording | Through the "FL Studio ASIO" device; see [Audio](#audio) |
| Native Linux file dialogs | Needs the patched `comdlg32`; see [Wine patches](#wine-patches) |

Not tested: MIDI controllers in actual use (devices are listed; see [MIDI](#midi)), Wayland, other distributions, third-party VST plugins, low-latency ASIO (WineASIO).

## Requirements

- An aarch64 Linux desktop.
- Steam with the **Proton 11.0 (ARM64)** tool installed (Library > Tools). It is only used
  as the source of the Wine build; `install.sh` makes a private copy (about 2 GB).
- An FL Studio Windows installer (`flstudio_win64_<version>.exe`) from your Image-Line account.
- For the Wine patches: `git curl make gcc autoconf flex bison pkg-config libdbus-1-dev`.
- For native file dialogs: `xdg-desktop-portal` with a backend such as `xdg-desktop-portal-gtk`.

## Install

```sh
./install.sh ~/Downloads/flstudio_win64_26.1.7.5654.exe
./build-wine-dlls.sh
flstudio
```

`install.sh` puts everything under `~/.local/share/flstudio` (override with `FLBASE`):

- `proton-arm64/` — the copy of Proton
- `prefix/` — the Wine prefix, with your home directory mapped as drive `H:`
- `env.sh` — environment used by the launchers (edit this for audio routing)

and installs `flstudio` and `flstudio-url` into `~/.local/bin` plus two desktop entries.

The FL Studio installer runs silently and takes several minutes. It exits with code 199
under Wine even when it succeeds; the script checks for `FL64.exe` instead.

Launcher usage:

```sh
flstudio [project.flp]     # start FL Studio, optionally opening a project
flstudio --wine <args>     # run any command in the same Wine environment
flstudio --kill            # stop Wine (wineserver -k)
```

## Wine patches

`build-wine-dlls.sh` checks out Valve's Wine at tag `proton-wine-11.0-2e`, applies the
patches in `patches/`, builds three DLLs with llvm-mingw and installs them into the Proton
copy and the prefix. The stock files are kept next to them as `*.orig`.

| Patch | Why |
|---|---|
| `0001-crypt32-…` | FL Studio 26.1.4 and newer refuse to start with "The validity of the program could not be verified". Wine re-sorted the PKCS#7 authenticated attributes before hashing, so `WinVerifyTrust` failed with `TRUST_E_CERT_SIGNATURE`. Backport of Wine [MR 11824](https://gitlab.winehq.org/wine/wine/-/merge_requests/11824), which is merged upstream; Proton 11.0-2e predates it. |
| `0002-comdlg32-…` | Native file dialogs through the XDG desktop portal. This is Wine [MR 10060](https://gitlab.winehq.org/wine/wine/-/merge_requests/10060), a draft that is not merged, without its tests and winecfg changes. Without it FL Studio uses Wine's own folder picker, which did not accept input on the test machine. |
| `0003-comdlg32-…` | Local fix on top of 0002. The MR blocks the calling thread while the portal dialog is open, which left the FL Studio window black and the native dialog without mouse or keyboard input. The request now runs on a worker thread while the caller pumps messages. |

`env.sh` sets `WINE_FORCE_PORTAL=1`. FL Studio registers dialog event listeners, and the
MR's default "auto" mode falls back to Wine's dialog when it sees those.

If you update the Proton copy from Steam, run `build-wine-dlls.sh` again.

`tools/vt.c` (prints the `WinVerifyTrust` result for a file) and `tools/fd.c` (opens an
`IFileDialog`) are small test programs; build them with llvm-mingw's
`aarch64-w64-mingw32-clang -municode`.

## Audio

- Choose **FL Studio ASIO** in Options > Audio settings. The DirectSound entries for a
  device offer output only, no inputs.
- FL Studio ASIO follows the system default output and input, and its panel has no input
  picker under Wine. To pin it to an interface, set `FL_SINK` and `FL_SOURCE` in `env.sh`
  to names from `pactl list short sinks` and `pactl list short sources`.
- USB class-compliant interfaces work through the normal Linux driver. Vendor Windows
  drivers cannot be used.

## MIDI

If FL Studio shows "The driver was not enabled" at startup, open Options > MIDI settings
and disable the `PipeWire-RT-Event` and `PipeWire-System` inputs. Wine cannot connect to
those sequencer ports. Enable your actual controller instead.

## Account unlock

Signing in at Image-Line's website ends with a `flstudio://` link that must reach FL
Studio. `install.sh` registers `flstudio-url` as the handler for that scheme. These links
carry a login token, so the handler never logs them.

## Other notes

- **Saving to Linux folders:** your home directory is drive `H:` inside FL Studio.
- **Downgrading:** the installer will not silently install over a newer version. Run
  `uninstall.exe /S` from the FL Studio program folder first.
- **i3 and other tiling window managers:** FL Studio has an empty-titled helper window
  that Windows keeps invisible. i3 shows it as a small white floating window, and closing
  it quits FL Studio. To hide it:

  ```
  for_window [class="steam_proton" title="^$"] move scratchpad
  ```

## Licence

The scripts and documentation are under the MIT licence (see `LICENSE`). The files in
`patches/` are changes to Wine and are under Wine's licence, LGPL 2.1 or later.
