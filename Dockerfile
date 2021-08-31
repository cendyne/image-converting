FROM alpine:3.14 as builder
# RUN apk add --no-cache imagemagick libwebp-tools
RUN apk add cmake pkgconfig brotli-dev \
  giflib-dev libjpeg-turbo-dev openexr-dev libpng-dev \
  libwebp-dev clang git make binutils libc-dev \
  build-base llvm-static llvm-dev clang-static clang-dev \
  ninja nasm perl openssl-dev
# RUN git clone https://chromium.googlesource.com/libyuv/libyuv
# WORKDIR /libyuv
# RUN mkdir build && cd build && cmake .. && make && make install
# WORKDIR /
# RUN git clone
# RUN apk add dav1d-dev aom-dev
RUN git clone https://github.com/AOMediaCodec/libavif.git
RUN git clone --single-branch https://chromium.googlesource.com/libyuv/libyuv
RUN git clone -b v3.1.2 --depth 1 https://aomedia.googlesource.com/aom
WORKDIR /libyuv/
RUN mkdir build.libavif && cd build.libavif && \
  cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DENABLE_DOCS=0 \
  -DENABLE_EXAMPLES=0 -DENABLE_TESTDATA=0 -DENABLE_TESTS=0 \
  -DENABLE_TOOLS=0 .. && \
  cmake --build . --config Release && \
  cmake --build . --target install --config Release
WORKDIR /aom
RUN mkdir build.libavif && cd build.libavif && cmake .. -DBUILD_SHARED_LIBS=1 \
  -DCMAKE_BUILD_TYPE=Release -DENABLE_DOCS=0 -DENABLE_EXAMPLES=0 \
  -DENABLE_TESTDATA=0 -DENABLE_TESTS=0 -DENABLE_TOOLS=0 && \
  cmake --build . --config Release && \
  cmake --build . --target install --config Release
# Rav1e is actually slower than AOM, creates bigger files than AOM
# WORKDIR /
# RUN git clone -b 0.4 --depth 1 https://github.com/xiph/rav1e.git
# WORKDIR /rav1e
# RUN apk add cargo
# RUN cargo install cargo-c
# RUN cargo cinstall --release --library-type=staticlib \
#   --prefix=/usr/local/
# RUN cargo cinstall --release --library-type=cdylib \
#   --prefix=/usr/local/

WORKDIR /libavif/
RUN mkdir build && cd build && \
  cmake .. -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
#  -DAVIF_CODEC_RAV1E=ON \
  -DAVIF_CODEC_AOM=ON \
  -DAVIF_BUILD_TESTS=0 \
  -DAVIF_BUILD_APPS=ON && \
  make && make install
WORKDIR /
RUN git clone https://github.com/libjxl/libjxl.git --recursive
WORKDIR /libjxl
RUN mkdir build && cd build && \
  cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF .. && \
  cmake --build . && \
  cmake --install .

RUN find /usr/local/ | grep "\.a" | xargs rm

FROM alpine:3.14

RUN apk add --no-cache imagemagick libwebp-tools openexr ffmpeg
COPY --from=builder /usr/local/lib/* /usr/local/lib/
COPY --from=builder /usr/local/bin/* /usr/local/bin/
