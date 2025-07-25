#!/bin/bash
set -euo pipefail
exec 3>&1 # Save original stdout
if [[ "${VERBOSE:-0}" != "1" ]]; then
  exec >/export/build.log 2>&1
else
  exec > >(tee /export/build.log) 2>&1
fi

log_step() {
  echo >&3
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&3
  echo "▶ STEP $1 — $(date '+%Y-%m-%d %H:%M:%S')" >&3
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&3
}

parse_version() {
  section="$1"
  key="$2"
  awk -F " = " -v section="[$section]" -v key="$key" '
    $0 == section { in_section = 1; next }
    /^\[/ && $0 != section { in_section = 0 }
    in_section && $1 == key { print $2; exit }
  ' VERSIONS.conf
}

# === Clone all modules at exact commits
log_step "Cloning modules"
for name in libevent openssl tor zlib xz zstd; do
  url=$(parse_version "$name" url)
  tag=$(parse_version "$name" tag)
  log_step "Cloning $name @ $tag"
  git clone --depth=1 "$url" "$name"
  cd "$name"
  git fetch --depth=1 origin tag "$tag"
  git checkout "$tag"
  cd ..
done

# Save root dir
ROOT="$PWD"

# === zlib
log_step "Build zlib"
cd "$ROOT/zlib"
sh ./configure --prefix="$ROOT/zlib/dist" --static
make -j"$(nproc)"
make install

# === openssl
log_step "Build openssl"
cd "$ROOT/openssl"
sh ./config --prefix="$ROOT/openssl/dist" --openssldir="$ROOT/openssl/dist" no-shared no-dso no-zlib
make depend
make -j"$(nproc)"
make install_sw

# === libevent
log_step "Build libevent"
cd "$ROOT/libevent"
sh -l ./autogen.sh
PKG_CONFIG_PATH="$ROOT/openssl/dist/lib/pkgconfig" \
  "$ROOT/libevent/configure" --prefix="$ROOT/libevent/dist" \
  --disable-shared --enable-static --with-pic \
  --disable-samples --disable-libevent-regress
make -j"$(nproc)"
make install

# === xz / liblzma
log_step "Build xz (liblzma)"
cd "$ROOT/xz"
sh -l ./autogen.sh
"$ROOT/xz/configure" --prefix="$ROOT/xz/dist" \
  --disable-shared --enable-static \
  --disable-doc --disable-scripts
make -j"$(nproc)"
make install

# === zstd
log_step "Build zstd"
mkdir -p "$ROOT/zstd/cmake-build"
cd "$ROOT/zstd/cmake-build"
cmake "$ROOT/zstd/build/cmake" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$ROOT/zstd/dist" \
  -DZSTD_BUILD_SHARED=OFF \
  -DZSTD_BUILD_PROGRAMS=OFF \
  -DZSTD_BUILD_TESTS=OFF \
  -DZSTD_BUILD_CONTRIB=OFF
make -j"$(nproc)"
make install

# === tor
log_step "Build tor"
cd "$ROOT/tor"
sh -l ./autogen.sh
PKG_CONFIG_PATH="$ROOT/openssl/dist/lib/pkgconfig:$ROOT/zstd/dist/lib/pkgconfig:$ROOT/xz/dist/lib/pkgconfig" \
  CFLAGS="-Os -s" \
  LDFLAGS="-s" \
  "$ROOT/tor/configure" \
  --prefix="$ROOT/tor/dist" \
  --sysconfdir=/etc --enable-static-tor \
  --enable-static-libevent --with-libevent-dir="$ROOT/libevent/dist" \
  --enable-static-openssl --with-openssl-dir="$ROOT/openssl/dist" \
  --enable-static-zlib --with-zlib-dir="$ROOT/zlib/dist" \
  --enable-gpl --disable-seccomp --disable-libscrypt \
  --disable-tool-name-check --disable-gcc-hardening \
  --disable-html-manual --disable-manpage --disable-asciidoc \
  --disable-systemd --disable-unittests
make -j"$(nproc)"
make install

# === Export
log_step "Export built tor"
mkdir -p /export
cp -r "$ROOT/tor/dist/"* /export/
awk '/^Tor Version:/, /^Configure Line:/' /export/build.log >/export/BUILD_CONFIG.txt
if [[ -n "${PUID:-}" && -n "${PGID:-}" ]]; then
  chown -R "$PUID:$PGID" /export
fi

# === Optionally compress all binaries in /export/bin
if [[ "${COMPRESS:-0}" == "1" && -d /export/bin ]]; then
  log_step "Compressing all /export/bin binaries with UPX"
  find /export/bin -type f -executable -exec upx --best --lzma {} + || true
fi

echo "Build and export complete."
