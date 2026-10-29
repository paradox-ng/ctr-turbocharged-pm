## Notes

Thanks to Cameron Redmore for [Crash Team Racing: Turbocharged](https://github.com/CameronRedmore/Crash-Team-Racing-Turbocharged), to Rinnegatamante for [Crash Team Racing: High Octane](https://github.com/Rinnegatamante/Crash-Team-Racing-High-Octane), which Turbocharged is built on, and to everyone behind [ctr-native](https://github.com/CTR-tools/ctr-native) and the Crash Team Racing decompilation. This port would not exist without their work.

The port runs the game as a 32-bit ARM (armhf) binary using OpenGL ES 3.0. The source, including the handheld changes, is at [paradox-ng/ctr-turbocharged-pm](https://github.com/paradox-ng/ctr-turbocharged-pm).

## Installation

The game data is not included. You need your own copy of the NTSC-U (US) release of Crash Team Racing, serial SCUS-94426.

1. Dump your disc as a raw image with 2352-byte sectors (MODE2/2352). A 2048-byte `.iso` will not work, and the `.cue` file is not used. A Redump dump of the US disc is in the right format.
2. Copy the `.bin` file to `ports/ctrturbocharged/assets/`. The launcher renames it to `ctr-u.bin` on first start.
3. Start Crash Team Racing Turbocharged from the Ports menu.

The game checks the image at startup and quits if it is the wrong region or format. The reason is written to `ports/ctrturbocharged/log.txt`.

## Controls

The game uses the PlayStation layout by button position.

| Button | PlayStation button |
|--|--|
| B (bottom) | Cross |
| Y (left) | Square |
| A (right) | Circle |
| X (top) | Triangle |
| L1 / R1 | L1 / R1 |
| L2 / R2 | L2 / R2 |
| D-pad | D-pad |
| Left stick | Left analog stick |
| Start | Start |
| Select | Select |
| Select + Start | Quit |

## Settings

The first start copies `config.default.ini` to `config.ini`, and changes made in the Options menu are saved there. The defaults are set for the H700 handhelds: 4:3, 30 FPS, the classic renderer, the original PS1 resolution, PGXP geometry precision and no anti-aliasing.

If the game runs well on your device, try 60 FPS from the Options menu. Saves, ghosts and settings are kept in `ports/ctrturbocharged/`.

## Compiling

```sh
git clone https://github.com/paradox-ng/ctr-turbocharged-pm.git
cd ctr-turbocharged-pm
packaging/portmaster/build.sh
```

The script builds the armhf binary in a Debian bullseye Docker container and assembles the port in `dist/portmaster/`.

## License

Crash Team Racing: Turbocharged is licensed under GPL-3.0. Licences for SDL, stb, the bundled fonts and other components are in `ports/ctrturbocharged/licenses/` and `ports/ctrturbocharged/assets/fonts/`.
