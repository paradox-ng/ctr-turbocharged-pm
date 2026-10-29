#!/usr/bin/env bash
# Smoke-test the CTR_HANDHELD (GLES) build on a PC, without a device.
#
# Builds a 32-bit x86 copy of the handheld build in Docker, runs it headless on
# Mesa's llvmpipe through SDL's offscreen driver, and saves frames of the
# attract mode as PNGs. Catches GLSL ES compile errors, invalid GLES calls
# (with MESA_DEBUG) and rendering differences before anything goes to a device.
#
# Usage: packaging/portmaster/smoke-test.sh <ctr-u.bin> [output-dir] [frame...]
# Frames are counted in buffer swaps; the defaults reach the intro, the
# title screen and a demo-mode race.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HERE="${ROOT}/packaging/portmaster"
IMAGE="ctr-smoke"
BUILD_DIR="build-smoke"

DISC="$(realpath "${1:?usage: $0 <ctr-u.bin> [output-dir] [frame...]}")"
OUT_DIR="$(realpath -m "${2:-${ROOT}/dist/smoke}")"
shift $(($# < 2 ? $# : 2))
FRAMES=("$@")
if [[ ${#FRAMES[@]} -eq 0 ]]; then
    FRAMES=(900 2700 8100)
fi

docker build -q -t "${IMAGE}" -f "${HERE}/docker/Dockerfile.smoke" "${HERE}/docker" > /dev/null
docker run --rm -u "$(id -u):$(id -g)" -v "${ROOT}":/src -w /src "${IMAGE}" sh -ec "
    cmake -S . -B ${BUILD_DIR} -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DCTR_HANDHELD=ON > /dev/null
    cmake --build ${BUILD_DIR} > /dev/null
"

# A fresh data folder: the handheld defaults, with the language set so the
# first-run menu does not wait for input.
rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}/data"
cp -r "${ROOT}/${BUILD_DIR}/assets" "${OUT_DIR}/data/"
{
    echo "language=2"
    cat "${HERE}/port/ctrturbocharged/config.default.ini"
} > "${OUT_DIR}/data/config.ini"

# gdb stops at each requested swap and reads back the 640x480 frame.
{
    echo "set pagination off"
    echo "set confirm off"
    echo "handle SIGPIPE nostop noprint"
    echo "handle SIG32 nostop noprint"
    echo "handle SIG33 nostop noprint"
    echo "break SDL_GL_SwapWindow"
    previous=0
    first=1
    for frame in "${FRAMES[@]}"; do
        echo "ignore 1 $((frame - previous - 1))"
        if [[ ${first} -eq 1 ]]; then
            echo "run"
            echo 'set $buf = (unsigned char *)malloc(640 * 480 * 4)'
            first=0
        else
            echo "continue"
        fi
        echo 'call (void)glReadPixels(0, 0, 640, 480, 0x1908, 0x1401, $buf)'
        echo "dump binary memory /data/frame-${frame}.raw \$buf \$buf+(640*480*4)"
        previous=${frame}
    done
    echo "kill"
    echo "quit"
} > "${OUT_DIR}/frames.gdb"

docker run --rm -u "$(id -u):$(id -g)" \
    -v "${ROOT}":/src:ro -v "${OUT_DIR}/data":/data -v "${OUT_DIR}/frames.gdb":/frames.gdb:ro \
    -v "${DISC}":/data/assets/ctr-u.bin:ro -w /data \
    -e SDL_VIDEODRIVER=offscreen -e SDL_AUDIO_DRIVER=dummy -e LIBGL_ALWAYS_SOFTWARE=1 \
    -e MESA_DEBUG=1 -e CTR_TURBOCHARGED_DATA_DIR=/data -e HOME=/data \
    "${IMAGE}" gdb -q -batch -x /frames.gdb "/src/${BUILD_DIR}/ctr_native" > "${OUT_DIR}/run.log" 2>&1 || true

# Convert the raw RGBA readbacks (bottom-up rows) to PNG.
python3 -I - "${OUT_DIR}/data" "${OUT_DIR}" <<'EOF'
import pathlib, struct, sys, zlib
src, dst = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
w, h = 640, 480
def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
for raw in sorted(src.glob("frame-*.raw")):
    pixels = raw.read_bytes()
    rows = b"".join(b"\x00" + pixels[y * w * 4:(y + 1) * w * 4] for y in range(h - 1, -1, -1))
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(rows, 6)) + chunk(b"IEND", b"")
    (dst / (raw.stem + ".png")).write_bytes(png)
    raw.unlink()
    print(dst / (raw.stem + ".png"))
EOF

echo "GL errors reported by Mesa:"
grep -i '^mesa' "${OUT_DIR}/run.log" | sort | uniq -c || echo "  none"
echo "Game log: ${OUT_DIR}/data/Crash Team Racing: Turbocharged.log"
