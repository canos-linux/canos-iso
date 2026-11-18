#!/bin/bash
# packages must not get group-writable dirs (container umask is 002)
umask 022
# build-repo.sh [local|publish] - build the CanOS packages (canvas, canos-tools)
#   local   - put them into the ISO build repo ~/CanOS/pkg/repo (canos-local)
#   publish - upload them to the online repo [canos] (GitHub release canos-linux/canos-repo, tag x86_64)
set -e
here="$(cd "$(dirname "$0")" && pwd)"
canvas="${CANVAS_SRC:-$HOME/CanOS/canvas}"
out="$HOME/CanOS/pkg/canos-out"; rm -rf "$out"; mkdir -p "$out"
for p in canvas canos-tools; do
    b=$(mktemp -d); cp -r "$here/$p/." "$b/"
    [ $p = canvas ] && sed -i "s/^pkgver=.*/pkgver=$(tr -d ' \n' < "$canvas/VERSION")/" "$b/PKGBUILD"
    (cd "$b" && CANVAS_SRC="$canvas" PKGDEST="$out" makepkg -f --nodeps --noconfirm >/dev/null)
    rm -rf "$b"
done
ls "$out"
case "${1:-local}" in
local)
    repo="$HOME/CanOS/pkg/repo"
    rm -f "$repo"/canvas-*.pkg.tar.zst "$repo"/canos-tools-*.pkg.tar.zst
    cp "$out"/*.pkg.tar.zst "$repo/"
    repo-add -q -R "$repo/canos-local.db.tar.gz" "$repo"/canvas-*.pkg.tar.zst "$repo"/canos-tools-*.pkg.tar.zst
    echo "local repo updated" ;;
publish)
    pub="$HOME/CanOS/pkg/canos-repo"; mkdir -p "$pub"
    rm -f "$pub"/*.pkg.tar.zst
    cp "$out"/*.pkg.tar.zst "$pub/"
    rm -f "$pub"/canos.db* "$pub"/canos.files*
    repo-add -q "$pub/canos.db.tar.gz" "$pub"/*.pkg.tar.zst
    rm -f "$pub/canos.db" "$pub/canos.files"; cp "$pub/canos.db.tar.gz" "$pub/canos.db"; cp "$pub/canos.files.tar.gz" "$pub/canos.files"
    gh release view x86_64 -R canos-linux/canos-repo >/dev/null 2>&1 || gh release create x86_64 -R canos-linux/canos-repo --title "CanOS package repository" --notes "pacman repository [canos]. Server = https://github.com/canos-linux/canos-repo/releases/download/x86_64"
    for a in $(gh release view x86_64 -R canos-linux/canos-repo --json assets --jq '.assets[].name'); do
        [ -e "$pub/$a" ] || gh release delete-asset x86_64 "$a" -R canos-linux/canos-repo -y
    done
    gh release upload x86_64 -R canos-linux/canos-repo --clobber "$pub/canos.db" "$pub/canos.files" "$pub"/*.pkg.tar.zst
    echo "published" ;;
esac
