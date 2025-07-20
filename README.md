# 🛠️ tor-static-builder

**Minimal, reproducible static Tor binary builder using Docker.**

This project clones and compiles Tor and its core dependencies — **OpenSSL**, **Libevent**, **Zlib**, **Liblzma (XZ)** and **Zstd** — using exact git commits. The result is a tiny, statically-linked `tor` binary exported for your use.

> 🐳 **Prebuilt image available at:**  
> [`ghcr.io/lanjelin/tor-static-builder`](https://ghcr.io/lanjelin/tor-static-builder)

---

## 🚀 Quick Start

### ✅ Pull Prebuilt Image
```bash
docker run --rm -v $PWD/export:/export ghcr.io/lanjelin/tor-static-builder
```
> Output will appear in `./export` — includes `tor` and all assets.

---

### 🏗️ Build From Source

#### 🔹 Docker CLI
```bash
docker build -t tor-static-builder .
docker run --rm -v $PWD/export:/export tor-static-builder
```

#### 🔸 Docker Compose
```yaml
# docker-compose.yml
services:
  tor-builder:
    build: .
    volumes:
      - ./export:/export
```

```bash
docker compose up --build
```

---

## 🧠 Notes

- 📌 Versions pinned in `VERSIONS.conf`
- 📁 Output is stored in `/export`
- 👥 Optional: set `PUID` and `PGID` to define ownership of exported files
- 🗜️ Set COMPRESS=1 to enable UPX compression of all binaries in /export/bin
- 🔈 Set VERBOSE=1 to stream full build output to terminal (default: only high-level steps shown)
---

## 🔧 Build Configuration

For detailed build flags, enabled features, library versions, and configuration paths used in this static Tor build, see:

👉 [BUILD_CONFIG.txt](BUILD_CONFIG.txt)  
👉 [VERSIONS.conf](VERSIONS.conf)

---

## ⚖️ License

This project only compiles and bundles upstream open-source code.
Use is governed by MIT and the individual upstream licenses (Tor, OpenSSL, etc.).

