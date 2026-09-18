FROM mirror.gcr.io/library/alpine:3.24.2@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6 AS build

ARG GIT_VERSION=2.55.0

# Install necessary build dependencies
RUN apk add --no-cache \
    wget \
    build-base \
    cargo \
    autoconf \
    curl-dev \
    expat-dev \
    linux-headers \
    openssl-dev \
    pcre2-dev \
    perl-dev \
    rust \
    zlib-dev \
    zlib-static

WORKDIR /build

# Set optimization flags
ENV CFLAGS="-static -Os -flto -fomit-frame-pointer -fdata-sections -ffunction-sections"
ENV LDFLAGS="-static -flto -Wl,--gc-sections"
ENV NO_GETTEXT=1

# Download, compile, and install Git
RUN wget https://github.com/git/git/archive/refs/tags/v${GIT_VERSION}.tar.gz && \
    tar -xf v${GIT_VERSION}.tar.gz && \
    cd git-${GIT_VERSION} && \
    make configure && \
    ./configure \
        --prefix=/usr/local \
        --without-tcltk \
    && make -j$(nproc) all \
    && strip --strip-all git \
    && make install

# Use a minimal base image for the final stage
FROM scratch

# Copy the compiled Git binary
COPY --from=build /usr/local/ /usr/local/

# Set Git as the entrypoint
ENTRYPOINT ["git"]
