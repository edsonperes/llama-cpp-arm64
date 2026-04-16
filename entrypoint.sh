#!/bin/bash
set -e

MODEL_PATH="${MODEL_PATH:-/app/models/Bonsai-8B.gguf}"
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8080}"
THREADS="${THREADS:-4}"
CTX_SIZE="${CTX_SIZE:-2048}"
PARALLEL="${PARALLEL:-1}"
BATCH_SIZE="${BATCH_SIZE:-512}"

echo "============================================"
echo "  llama.cpp Server - Bonsai 8B (Q1_0)"
echo "  OrangePi 5 / ARM64 CPU"
echo "============================================"
echo "Modelo: ${MODEL_PATH}"
echo "Porta: ${PORT}"
echo "Threads: ${THREADS}"
echo "Contexto: ${CTX_SIZE} tokens"
echo "Paralelo: ${PARALLEL} slots"
echo "Batch: ${BATCH_SIZE}"
echo "============================================"

if [ ! -f "${MODEL_PATH}" ]; then
    echo "[ERRO] Modelo nao encontrado em ${MODEL_PATH}"
    exit 1
fi

SIZE=$(du -h "${MODEL_PATH}" | cut -f1)
echo "[Modelo] ${MODEL_PATH} (${SIZE})"

ARGS=(
    --model "${MODEL_PATH}"
    --host "${HOST}"
    --port "${PORT}"
    --threads "${THREADS}"
    --ctx-size "${CTX_SIZE}"
    --parallel "${PARALLEL}"
    --batch-size "${BATCH_SIZE}"
)

if [ -n "${API_KEY}" ]; then
    ARGS+=(--api-key "${API_KEY}")
fi

if [ "${NO_WEBUI}" = "true" ]; then
    ARGS+=(--no-webui)
fi

echo "[Server] Iniciando na porta ${PORT}..."
exec /app/llama-server "${ARGS[@]}"
