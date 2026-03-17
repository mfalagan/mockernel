FROM debian:trixie-slim

# avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# passed from devcontainer.json
ARG ARM_GNU_TOOLCHAIN_VERSION
ARG ARM_GNU_TOOLCHAIN_TARGET

# install packages
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        \
        # core tools
        make \
        git \
        openssh-client \
        \
        # OSdev tools
        device-tree-compiler \
        qemu-system-arm \
        \
        # toolchain download / extraction helpers
        ca-certificates \
        curl \
        xz-utils \
        file \
    ; \
    rm -rf /var/lib/apt/lists/*
    
# mark the workspace as a safe git directory
RUN git config --system --add safe.directory /workspace

# fetch and extract the ARM GNU toolchain
RUN set -eux; \
    DEB_HOST_ARCH="$(dpkg --print-architecture)"; \
    case "${DEB_HOST_ARCH}" in \
        amd64) ARM_GNU_TOOLCHAIN_HOST_ARCH="x86_64" ;; \
        arm64) ARM_GNU_TOOLCHAIN_HOST_ARCH="aarch64" ;; \
        *) echo "Unsupported Debian architecture: ${DEB_HOST_ARCH}" >&2; exit 1 ;; \
    esac; \
    ARM_GNU_TOOLCHAIN_BASENAME="arm-gnu-toolchain-${ARM_GNU_TOOLCHAIN_VERSION}-${ARM_GNU_TOOLCHAIN_HOST_ARCH}-${ARM_GNU_TOOLCHAIN_TARGET}"; \
    ARM_GNU_TOOLCHAIN_URL="https://developer.arm.com/-/media/Files/downloads/gnu/${ARM_GNU_TOOLCHAIN_VERSION}/binrel/${ARM_GNU_TOOLCHAIN_BASENAME}.tar.xz"; \
    mkdir -p /opt; \
    curl -fL "${ARM_GNU_TOOLCHAIN_URL}" -o /tmp/arm-gnu-toolchain.tar.xz; \
    tar -xJf /tmp/arm-gnu-toolchain.tar.xz -C /opt; \
    rm /tmp/arm-gnu-toolchain.tar.xz; \
    ln -s "/opt/${ARM_GNU_TOOLCHAIN_BASENAME}" /opt/arm-gnu-toolchain; \
    ln -s "/opt/arm-gnu-toolchain/bin/${ARM_GNU_TOOLCHAIN_TARGET}-g++" /usr/local/bin/arm-cross-g++

# add the toolchain to the PATH
ENV PATH="/opt/arm-gnu-toolchain/bin:${PATH}"

# fail the image build if the tools are missing
RUN set -eux; \
    aarch64-none-elf-gcc --version; \
    qemu-system-aarch64 --version; \
    dtc --version