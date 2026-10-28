# CTR Turbocharged for PortMaster
<img src="screenshots/game1.jpg"></img><br>
This fork packages [Crash Team Racing: Turbocharged](https://github.com/CameronRedmore/Crash-Team-Racing-Turbocharged) as a [PortMaster](https://portmaster.games) port for Linux handhelds. The first target is the Anbernic H700 family (RG40XXV and the RG35XX line): four Cortex-A53 cores, a Mali-G31 GPU, 1 GB of RAM and a 640x480 screen. Development and testing happen on an RG40XXV running muOS 2606.

Turbocharged is Cameron Redmore's PC fork of Rinnegatamante's [High Octane](https://github.com/Rinnegatamante/Crash-Team-Racing-High-Octane), which is built on the [ctr-native](https://github.com/CTR-tools/ctr-native) decompilation. The game code is theirs. This fork adds a handheld build mode and the PortMaster packaging, and keeps the patch small so it can be offered upstream as an optional build mode.

## Status

Work in progress. The port has not run on a device yet.

- [ ] Device check: 32-bit GPU, DRM and audio libraries on muOS
- [ ] `CTR_HANDHELD` build option (GLES 3.0, KMS/DRM, no desktop dialogs)
- [ ] armhf build in Docker
- [ ] Boots and plays on the RG40XXV
- [ ] PortMaster package (launch script, `port.json`, `gameinfo.xml`)
- [ ] Performance defaults for the H700
- [ ] Testing on Knulli and ROCKNIX

## What the port changes

The game needs 32-bit pointers, so the handheld build is a 32-bit ARM (armhf) binary. The H700 handhelds run a 64-bit system, so the firmware also has to provide 32-bit GPU, DRM and audio libraries. muOS is known to ship a 32-bit runtime on these devices, and checking its GPU libraries is the first step.

A new CMake option, `CTR_HANDHELD`, switches the build to:

- OpenGL ES 3.0, through the GLES renderer path High Octane wrote for its web build
- SDL3 with KMS/DRM video and ALSA, PulseAudio or PipeWire audio, with no X11 or Wayland
- no file picker or message boxes, since the handheld has no desktop, and no online update check

With the option off, desktop builds are unchanged.

Upstream also has an experimental 64-bit branch, `64bit-2026.10`. If a firmware has no 32-bit GPU libraries, an aarch64 build from that branch is the fallback.

## Your game disc

The port ships no game data, so you need your own copy of the game.

- Dump your NTSC-U (US) Crash Team Racing disc, serial SCUS-94426.
- Use the raw BIN with MODE2/2352 sectors. A 2048-byte `.iso` does not work, and the game ignores the `.cue` file. A single-track Redump dump of the US disc is in the right format.
- Rename the BIN to `ctr-u.bin` and copy it to `ports/ctrturbocharged/assets/` on the SD card.

The game checks the image at startup and exits if the region or format is wrong.

## Building

The build runs in a Debian bullseye container (glibc 2.31) with the armhf cross compiler, so the binary runs on any firmware with glibc 2.31 or newer. The Dockerfile and CMake toolchain file are in [packaging/portmaster/docker](packaging/portmaster/docker). Full build steps will be added here with the first working build.

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
