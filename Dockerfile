# ============================================
# llama.cpp Bonsai 8B server for OrangePi 5
# PrismML fork - ARM64 optimized
# ============================================

# Stage 1: Build llama.cpp
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/PrismML-Eng/llama.cpp.git /build/llama.cpp

WORKDIR /build/llama.cpp

RUN cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DGGML_NATIVE=OFF \
    -DGGML_OPENMP=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DCMAKE_C_FLAGS="-march=armv8.2-a+dotprod+fp16+crypto" \
    -DCMAKE_CXX_FLAGS="-march=armv8.2-a+dotprod+fp16+crypto" \
    && cmake --build build --config Release --target llama-server -j$(nproc)

# Stage 2: Download model (separate for independent caching)
FROM debian:bookworm-slim AS model

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /model && \
    curl -L --retry 3 --retry-delay 5 \
    -o /model/Bonsai-8B.gguf \
    "https://huggingface.co/prism-ml/Bonsai-8B-gguf/resolve/main/Bonsai-8B.gguf"

# Stage 3: Runtime
FROM debian:bookworm-slim

LABEL maintainer="edsonperes"
LABEL org.opencontainers.image.source="https://github.com/edsonperes/llama-cpp-arm64"
LABEL org.opencontainers.image.description="llama.cpp Bonsai 8B (Q1_0) inference server for OrangePi 5"

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /build/llama.cpp/build/bin/llama-server /app/llama-server
COPY --from=model /model/Bonsai-8B.gguf /app/models/Bonsai-8B.gguf
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh /app/llama-server

ENV MODEL_PATH=/app/models/Bonsai-8B.gguf
ENV HOST=0.0.0.0
ENV PORT=8080
ENV THREADS=4
ENV CTX_SIZE=2048
ENV PARALLEL=1
ENV BATCH_SIZE=512

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -sf http://localhost:${PORT}/health || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
