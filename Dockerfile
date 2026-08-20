FROM mirror.gcr.io/library/alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS build

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
