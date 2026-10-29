#!/usr/bin/env bash
# Build the armhf CTR_HANDHELD binary in Docker and assemble the PortMaster
# port in dist/portmaster/:
#   ctrturbocharged/      the ports/ctrturbocharged folder for PortMaster-New
#   ctrturbocharged.zip   the same port laid out for a device's ports folder
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HERE="${ROOT}/packaging/portmaster"
IMAGE="ctr-armhf"
BUILD_DIR="build-armhf"
DIST_DIR="${ROOT}/dist/portmaster"
PORT_NAME="ctrturbocharged"
SCRIPT_NAME="Crash Team Racing Turbocharged.sh"

docker build -t "${IMAGE}" "${HERE}/docker"
docker run --rm -u "$(id -u):$(id -g)" -v "${ROOT}":/src -w /src "${IMAGE}" sh -ec "
    cmake -S . -B ${BUILD_DIR} -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE=/src/packaging/portmaster/docker/armhf-debian.cmake \
        -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DCTR_HANDHELD=ON
    cmake --build ${BUILD_DIR}
    arm-linux-gnueabihf-strip -o ${BUILD_DIR}/ctr_native.stripped ${BUILD_DIR}/ctr_native
"

PORT_DIR="${DIST_DIR}/${PORT_NAME}"
GAME_DIR="${PORT_DIR}/${PORT_NAME}"
rm -rf "${DIST_DIR}"
mkdir -p "${GAME_DIR}/assets/fonts" "${GAME_DIR}/licenses"

# Port metadata and launcher, as PortMaster-New expects them.
cp "${HERE}/port/${SCRIPT_NAME}" "${HERE}/port/port.json" "${HERE}/port/README.md" "${HERE}/port/gameinfo.xml" "${PORT_DIR}/"
if [[ -f "${HERE}/port/screenshot.png" ]]; then
    cp "${HERE}/port/screenshot.png" "${PORT_DIR}/"
fi
chmod +x "${PORT_DIR}/${SCRIPT_NAME}"

# The game folder: binary, handheld defaults, runtime assets and licences.
cp "${ROOT}/${BUILD_DIR}/ctr_native.stripped" "${GAME_DIR}/ctr_native"
chmod +x "${GAME_DIR}/ctr_native"
cp "${HERE}/port/${PORT_NAME}/config.default.ini" "${GAME_DIR}/"
cp "${ROOT}/LICENSE" "${ROOT}/THIRD_PARTY_NOTICES.md" "${GAME_DIR}/"
for license_file in MPL-2.0.txt SDL-zlib.txt HIDAPI-BSD.txt stb-MIT.txt yuv2rgb-BSD.txt SDL-EDID-MIT.txt SDL-fdlibm.txt; do
    cp "${ROOT}/licenses/${license_file}" "${GAME_DIR}/licenses/"
done
cp "${ROOT}/assets/dualshock.png" "${GAME_DIR}/assets/"
for font_file in FuzzyBubbles-Bold.ttf FuzzyBubbles-OFL.txt LuckiestGuy-Regular.ttf LuckiestGuy-Apache-2.0.txt LuckiestGuy-NOTICE.txt README.md; do
    cp "${ROOT}/assets/fonts/${font_file}" "${GAME_DIR}/assets/fonts/"
done

# On a device, the metadata sits inside the game folder next to the binary.
STAGE_DIR="$(mktemp -d)"
trap 'rm -rf "${STAGE_DIR}"' EXIT
cp -r "${GAME_DIR}" "${STAGE_DIR}/"
cp "${PORT_DIR}/${SCRIPT_NAME}" "${STAGE_DIR}/"
for meta_file in port.json README.md gameinfo.xml screenshot.png; do
    if [[ -f "${PORT_DIR}/${meta_file}" ]]; then
        cp "${PORT_DIR}/${meta_file}" "${STAGE_DIR}/${PORT_NAME}/"
    fi
done
(cd "${STAGE_DIR}" && zip -qr "${DIST_DIR}/${PORT_NAME}.zip" "${SCRIPT_NAME}" "${PORT_NAME}")

echo "Port folder: ${PORT_DIR}"
echo "Device zip:  ${DIST_DIR}/${PORT_NAME}.zip"
