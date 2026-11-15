#!/bin/bash
# Syncs Canvas into the archiso profile. Run before buildiso.sh.
set -e
here="$(cd "$(dirname "$0")" && pwd)"
air="$here/archiso/airootfs"
canvas="${CANVAS_SRC:-$HOME/CanOS/canvas}"

rm -rf "$air/usr/share/canvas"
mkdir -p "$air/usr/share/canvas" "$air/usr/bin" "$air/etc/systemd/system"
git -C "$canvas" archive HEAD | tar -x -C "$air/usr/share/canvas"
chmod 755 "$air/usr/share/canvas/bin/"* "$air/usr/share/canvas/greeter/install-greeter"
ln -sfn /usr/share/canvas/bin/canvas "$air/usr/bin/canvas"
ln -sfn /usr/lib/systemd/system/greetd.service "$air/etc/systemd/system/display-manager.service"
echo "Canvas $(git -C "$canvas" rev-parse --short HEAD) synced into airootfs"
