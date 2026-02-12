FROM zmkfirmware/zmk-build-arm:3.5-branch

WORKDIR /workspace

# Copy only west.yml first to cache dependencies layer
COPY config/west.yml ./config/west.yml

# Initialize West and fetch dependencies (this layer will be cached)
RUN west init -l config && \
    west update && \
    west update

# Set CMAKE_PREFIX_PATH for builds
ENV CMAKE_PREFIX_PATH="/workspace/zephyr:$CMAKE_PREFIX_PATH"

# Now copy the rest of the project (changes won't invalidate dependency cache)
COPY . /workspace

# Create build output directory
RUN mkdir -p /workspace/bin

# Build script that will be run when container starts
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "Building BLOQ firmware..."\n\
BUILD_VARIANT="${BUILD_VARIANT:-keymap}"\n\
BUILD_TARGET="${BUILD_TARGET:-both}"\n\
echo "Build variant: ${BUILD_VARIANT}"\n\
echo "Build target: ${BUILD_TARGET}"\n\
\n\
COMMON_CMAKE_ARGS="-DZMK_CONFIG=/workspace/config"\n\
if command -v ccache >/dev/null 2>&1; then\n\
  export CCACHE_DIR="${CCACHE_DIR:-/ccache}"\n\
  export CCACHE_BASEDIR="${CCACHE_BASEDIR:-/workspace}"\n\
  export CCACHE_COMPILERCHECK="${CCACHE_COMPILERCHECK:-content}"\n\
  export CCACHE_MAXSIZE="${CCACHE_MAXSIZE:-2G}"\n\
  mkdir -p "${CCACHE_DIR}"\n\
  ccache -M "${CCACHE_MAXSIZE}" >/dev/null 2>&1 || true\n\
  COMMON_CMAKE_ARGS="${COMMON_CMAKE_ARGS} -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache"\n\
  echo "ccache enabled at ${CCACHE_DIR}"\n\
fi\n\
\n\
if [ "$BUILD_TARGET" = "left" ] || [ "$BUILD_TARGET" = "both" ]; then\n\
  echo "Building left half..."\n\
  west build -d /build/left -b "nice_nano" \\\n    -s /workspace/zmk/app \\\n    -- -DSHIELD="bloq_left" ${COMMON_CMAKE_ARGS}\n\
fi\n\
\n\
if [ "$BUILD_TARGET" = "right" ] || [ "$BUILD_TARGET" = "both" ]; then\n\
  echo "Building right half..."\n\
  west build -d /build/right -b "nice_nano" \\\n    -s /workspace/zmk/app \\\n    -- -DSHIELD="bloq_right" ${COMMON_CMAKE_ARGS}\n\
fi\n\
\n\
if [ "$BUILD_VARIANT" = "all" ] && [ "$BUILD_TARGET" = "both" ]; then\n\
  echo "Building settings reset..."\n\
  west build -d /build/settings_reset -b "nice_nano" \\\n    -s /workspace/zmk/app \\\n    -- -DSHIELD="settings_reset" ${COMMON_CMAKE_ARGS}\n\
fi\n\
\n\
echo "Copying firmware files..."\n\
if [ "$BUILD_TARGET" = "left" ] || [ "$BUILD_TARGET" = "both" ]; then\n\
  cp /build/left/zephyr/zmk.uf2 /workspace/bin/bloq_left.uf2\n\
fi\n\
if [ "$BUILD_TARGET" = "right" ] || [ "$BUILD_TARGET" = "both" ]; then\n\
  cp /build/right/zephyr/zmk.uf2 /workspace/bin/bloq_right.uf2\n\
fi\n\
if [ "$BUILD_VARIANT" = "all" ] && [ "$BUILD_TARGET" = "both" ]; then\n\
  cp /build/settings_reset/zephyr/zmk.uf2 /workspace/bin/settings_reset.uf2\n\
fi\n\
\n\
echo "Build complete! Firmware files are in bin/"\n\
ls -lh /workspace/bin/*.uf2\n\
' > /build.sh && chmod +x /build.sh

CMD ["/build.sh"]
