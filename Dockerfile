FROM debian:bullseye-slim

# Install all required packages
RUN apt update && apt install -y --no-install-recommends \
    git build-essential libtool autopoint upx \
    po4a perl pkg-config autoconf automake cmake curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create working dir and copy build script and version pins
WORKDIR /build
COPY entrypoint.sh /entrypoint.sh
COPY VERSIONS.conf /build/VERSIONS.conf
RUN chmod +x /entrypoint.sh

# Run the builder
ENTRYPOINT ["/entrypoint.sh"]

