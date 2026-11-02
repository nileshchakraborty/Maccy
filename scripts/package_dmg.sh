#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
RELEASE_APP="${BUILD_DIR}/Build/Products/Release/Maccy.app"
DMG_STAGING_DIR="${BUILD_DIR}/dmg_staging"
OUTPUT_DMG="${BUILD_DIR}/ClipVault-1.0.0.dmg"

echo "==> Verifying release build..."
if [ ! -d "${RELEASE_APP}" ]; then
    echo "Release app not found at ${RELEASE_APP}. Building now..."
    cd "${PROJECT_DIR}"
    xcodebuild -project Maccy.xcodeproj -scheme Maccy -configuration Release -derivedDataPath ./build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
fi

echo "==> Preparing DMG staging area..."
rm -rf "${DMG_STAGING_DIR}" "${OUTPUT_DMG}"
mkdir -p "${DMG_STAGING_DIR}"

echo "==> Copying application to staging as ClipVault.app..."
cp -R "${RELEASE_APP}" "${DMG_STAGING_DIR}/ClipVault.app"

echo "==> Creating /Applications symlink..."
ln -s /Applications "${DMG_STAGING_DIR}/Applications"

echo "==> Generating compressed disk image (DMG)..."
hdiutil create -volname "ClipVault" \
               -srcfolder "${DMG_STAGING_DIR}" \
               -ov \
               -format UDZO \
               "${OUTPUT_DMG}"

echo "==> Calculating SHA256 checksum..."
SHA256=$(shasum -a 256 "${OUTPUT_DMG}" | awk '{print $1}')
echo "SHA256: ${SHA256}"
echo "${SHA256}" > "${BUILD_DIR}/ClipVault-1.0.0.dmg.sha256"

echo "==> Cleaning up staging..."
rm -rf "${DMG_STAGING_DIR}"

echo "==> DMG successfully created at: ${OUTPUT_DMG}"
