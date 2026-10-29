# CTR Turbocharged for PortMaster
<img src="screenshots/game1.jpg"></img><br>
This fork packages [Crash Team Racing: Turbocharged](https://github.com/CameronRedmore/Crash-Team-Racing-Turbocharged) as a [PortMaster](https://portmaster.games) port for Linux handhelds. The first target is the Anbernic H700 family (RG40XXV and the RG35XX line): four Cortex-A53 cores, a Mali-G31 GPU, 1 GB of RAM and a 640x480 screen. Development and testing happen on an RG40XXV running muOS 2606.

Turbocharged is Cameron Redmore's PC fork of Rinnegatamante's [High Octane](https://github.com/Rinnegatamante/Crash-Team-Racing-High-Octane), which is built on the [ctr-native](https://github.com/CTR-tools/ctr-native) decompilation. The game code is theirs. This fork adds a handheld build mode and the PortMaster packaging, and keeps the patch small so it can be offered upstream as an optional build mode.

## Status

Work in progress. The handheld build compiles and renders the intro, menus and demo races correctly on a PC through Mesa's GLES driver, but it has not run on a device yet.

- [ ] Device check: 32-bit GPU, DRM and audio libraries on muOS
- [x] `CTR_HANDHELD` build option (GLES 3.0, KMS/DRM, no desktop dialogs)
- [x] armhf build in Docker
- [x] Headless GLES smoke test on a PC
- [ ] Boots and plays on the RG40XXV
- [x] PortMaster package (launch script, `port.json`, `gameinfo.xml`)
- [ ] Screenshot from a device
- [ ] Performance defaults for the H700
- [ ] Testing on Knulli and ROCKNIX

## What the port changes

The game needs 32-bit pointers, so the handheld build is a 32-bit ARM (armhf) binary. The H700 handhelds run a 64-bit system, so the firmware also has to provide 32-bit GPU, DRM and audio libraries. muOS is known to ship a 32-bit runtime on these devices, and checking its GPU libraries is the first step.

A new CMake option, `CTR_HANDHELD`, switches the build to:

- OpenGL ES 3.0, through the GLES renderer path High Octane wrote for its web build
- SDL3 with KMS/DRM video and ALSA, PulseAudio or PipeWire audio, with no X11 or Wayland
- no file picker or message boxes, since the handheld has no desktop, and no online update check
- an opaque final frame, because the alpha channel carries the PS1 mask bit and SDL's KMS/DRM surface scans out with alpha
- 4:3 framing for the classic renderer when the aspect ratio option is 4:3, instead of its fixed widescreen

With the option off, desktop builds are unchanged.

Upstream also has an experimental 64-bit branch, `64bit-2026.10`. If a firmware has no 32-bit GPU libraries, an aarch64 build from that branch is the fallback.

## Your game disc

The port ships no game data, so you need your own copy of the game.

- Dump your NTSC-U (US) Crash Team Racing disc, serial SCUS-94426.
- Use the raw BIN with MODE2/2352 sectors. A 2048-byte `.iso` does not work, and the game ignores the `.cue` file. A single-track Redump dump of the US disc is in the right format.
- Copy the BIN to `ports/ctrturbocharged/assets/` on the SD card. The launcher renames it to `ctr-u.bin` on first start.

The game checks the image at startup and exits if the region or format is wrong. The reason is in `ports/ctrturbocharged/log.txt`.

## Building

You need Docker. The build runs in a Debian bullseye container with the armhf cross compiler, so the binary never needs a glibc newer than 2.31.

```sh
packaging/portmaster/build.sh
```

This builds `build-armhf/ctr_native` and puts two things in `dist/portmaster/`: `ctrturbocharged/`, the port folder in the layout PortMaster-New expects, and `ctrturbocharged.zip`, the same port laid out for a device. To install it on a device, copy the zip into the `autoinstall` folder inside PortMaster's folder (`/mnt/mmc/MUOS/PortMaster/autoinstall/` on muOS) and open PortMaster, which installs it.

To check the GLES renderer without a device, run the smoke test with your disc image:

```sh
packaging/portmaster/smoke-test.sh /path/to/ctr-u.bin
```

It builds a 32-bit x86 copy of the handheld build, runs it headless on Mesa's software GLES driver, and saves frames of the intro and a demo race to `dist/smoke/`. It also lists any GL errors Mesa reports.

The port files (launch script, metadata, default config) are in [packaging/portmaster/port](packaging/portmaster/port), and the containers in [packaging/portmaster/docker](packaging/portmaster/docker).

## Branches

- `portmaster` is the default branch, with the handheld build and the packaging.
- `turbocharged` mirrors upstream's `turbocharged` branch without changes and is used to pull in new releases.

## Upstream

The [Turbocharged README](https://github.com/CameronRedmore/Crash-Team-Racing-Turbocharged#readme) and [ctr.cmzi.uk](https://ctr.cmzi.uk) cover the full feature list, desktop setup, changelog and known issues. Report problems with the handheld build in this fork's issues, since upstream does not support it.

## Credits

- Cameron Redmore for Crash Team Racing: Turbocharged
- Rinnegatamante for Crash Team Racing: High Octane
- The ctr-native project and everyone who worked on the CTR decompilation
- [DuckStation](https://github.com/stenzek/duckstation) by Stenzek, whose PGXP implementation the PGXP option is modelled on, and iCatButler for the original PGXP
- robin994 for helping test the splitscreen implementation
- The [PortMaster](https://portmaster.games) team for the launcher and packaging tools

## License

GPL-3.0, the same as upstream. See [LICENSE](LICENSE), [licenses/](licenses/) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). The bundled fonts keep their own licences in [assets/fonts](assets/fonts).

Crash Team Racing is a trademark of Activision. This is a fan project with no affiliation to Activision or Sony.
