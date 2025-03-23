FROM alpine:3.21.3 AS build

ARG GIT_VERSION=2.49.0

# Install necessary build dependencies
RUN apk add --no-cache \
    wget \
    build-base \
    autoconf \
    curl-dev \
    expat-dev \
    openssl-dev \
    pcre2-dev \
    perl-dev \
    zlib-dev \
    zlib-static

WORKDIR /build

# Set optimization flags
ENV CFLAGS="-static -Os -flto -fomit-frame-pointer -fdata-sections -ffunction-sections"
ENV LDFLAGS="-static -flto -Wl,--gc-sections"

# Download, compile, and install Git
RUN wget https://github.com/git/git/archive/refs/tags/v${GIT_VERSION}.tar.gz && \
    tar -xf v${GIT_VERSION}.tar.gz && \
    cd git-${GIT_VERSION} && \
    make configure && \
    ./configure \
        --prefix=/usr/local \
        --without-tcltk \
        --without-gettext \
        --without-svn \
    && make -j$(nproc) all \
    && strip --strip-all git \
    && make install

# Use a minimal base image for the final stage
FROM scratch

# Copy the compiled Git binary
COPY --from=build /usr/local/ /usr/local/

# Set Git as the entrypoint
ENTRYPOINT ["git"]
