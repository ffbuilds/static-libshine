
# bump: LIBSHINE /LIBSHINE_VERSION=([\d.]+)/ https://github.com/toots/shine.git|*
# bump: LIBSHINE after ./hashupdate Dockerfile LIBSHINE $LATEST
# bump: LIBSHINE link "CHANGELOG" https://github.com/toots/shine/blob/master/ChangeLog
# bump: LIBSHINE link "Source diff $CURRENT..$LATEST" https://github.com/toots/shine/compare/$CURRENT..$LATEST
ARG LIBSHINE_VERSION=3.1.1
ARG LIBSHINE_URL="https://github.com/toots/shine/releases/download/$LIBSHINE_VERSION/shine-$LIBSHINE_VERSION.tar.gz"
ARG LIBSHINE_SHA256=58e61e70128cf73f88635db495bfc17f0dde3ce9c9ac070d505a0cd75b93d384

# bump: alpine /FROM alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
FROM alpine:3.16.2 AS base

FROM base AS download
ARG LIBSHINE_URL
ARG LIBSHINE_SHA256
ARG WGET_OPTS="--retry-on-host-error --retry-on-http-error=429,500,502,503 -nv"
WORKDIR /tmp
RUN \
  apk add --no-cache --virtual download \
    coreutils wget tar && \
  wget $WGET_OPTS -O libshine.tar.gz "$LIBSHINE_URL" && \
  echo "$LIBSHINE_SHA256  libshine.tar.gz" | sha256sum --status -c - && \
  mkdir libshine && \
  tar xf libshine.tar.gz -C libshine --strip-components=1 && \
  rm libshine.tar.gz && \
  apk del download

FROM base AS build
COPY --from=download /tmp/libshine/ /tmp/libshine/
WORKDIR /tmp/libshine
RUN \
  apk add --no-cache --virtual build \
    build-base && \
  ./configure --with-pic --enable-static --disable-shared --disable-fast-install && \
  make -j$(nproc) install && \
  apk del build

FROM scratch
ARG LIBSHINE_VERSION
COPY --from=build /usr/local/lib/pkgconfig/shine.pc /usr/local/lib/pkgconfig/shine.pc
COPY --from=build /usr/local/lib/libshine.a /usr/local/lib/libshine.a
COPY --from=build /usr/local/include/shine/ /usr/local/include/shine/
