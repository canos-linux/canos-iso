#!/bin/bash
# Syncs Canvas into the archiso profile. Run before buildiso.sh.
set -e
here="$(cd "$(dirname "$0")" && pwd)"
air="$here/archiso/airootfs"
canvas="${CANVAS_SRC:-$HOME/CanOS/canvas}"

rm -rf "$air/usr/share/canvas" "$air/usr/bin/canvas"
mkdir -p "$air/etc/systemd/system"
ln -sfn /usr/lib/systemd/system/greetd.service "$air/etc/systemd/system/display-manager.service"
CANVAS_SRC="$canvas" "$here/packaging/build-repo.sh" local
echo "Canvas $(git -C "$canvas" rev-parse --short HEAD) packaged into canos-local"
