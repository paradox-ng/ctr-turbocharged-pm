#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt

# The game needs 32-bit pointers, so the binary is armhf on every device.
export PORT_32BIT="Y"

[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"

get_controls

GAMEDIR="/$directory/ports/ctrturbocharged"
cd "$GAMEDIR"

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# The game reads the disc from assets/ctr-u.bin. Accept a .bin dropped in the
# port folder or in assets/ under any name and move it into place. Some dumps
# split the audio into extra tracks, so take the largest file: the data track.
if [ ! -f "$GAMEDIR/assets/ctr-u.bin" ]; then
  disc=""
  disc_size=0
  shopt -s nullglob nocaseglob
  for f in "$GAMEDIR"/*.bin "$GAMEDIR"/assets/*.bin; do
    size=$(stat -c %s "$f" 2>/dev/null || echo 0)
    if [ "$size" -gt "$disc_size" ]; then
      disc="$f"
      disc_size="$size"
    fi
  done
  shopt -u nullglob nocaseglob
  if [ -n "$disc" ]; then
    echo "Using disc image: $disc"
    mv "$disc" "$GAMEDIR/assets/ctr-u.bin"
  fi
fi

if [ ! -f "$GAMEDIR/assets/ctr-u.bin" ]; then
  echo "Missing disc image: copy your NTSC-U Crash Team Racing .bin to ports/ctrturbocharged/assets/"
  pm_message "Missing game disc. Copy your NTSC-U (US) Crash Team Racing .bin file (raw 2352-byte sectors, not .iso) to ports/ctrturbocharged/assets/ and start the game again."
  sleep 10
  pm_finish
  exit 1
fi

# Handheld defaults: 4:3, 30 FPS and the classic renderer. Changes made in the
# Options menu are saved to config.ini and kept across updates.
[ -f "$GAMEDIR/config.ini" ] || cp "$GAMEDIR/config.default.ini" "$GAMEDIR/config.ini"

# Config, saves, ghosts and the game log all stay in the port folder.
export CTR_TURBOCHARGED_DATA_DIR="$GAMEDIR"
export LD_LIBRARY_PATH="$GAMEDIR/libs.armhf:$LD_LIBRARY_PATH"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

$ESUDO chmod +x "$GAMEDIR/ctr_native"

# gptokeyb only provides the exit hotkey; the game reads the gamepad itself.
$GPTOKEYB "ctr_native" &

pm_platform_helper "$GAMEDIR/ctr_native"

./ctr_native

pm_finish
