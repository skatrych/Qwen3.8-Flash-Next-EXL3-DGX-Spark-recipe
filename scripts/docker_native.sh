#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [[ -z "${MODEL_SOURCE+x}" ]]; then
  if [[ -n "${MODEL_DIR:-}" ]]; then
    export MODEL_SOURCE=local
  else
    export MODEL_SOURCE=cache
  fi
fi
export MODEL_DIR="${MODEL_DIR:-$REPO_ROOT/models/Qwen3.8-Flash-Next-EXL3}"
export HF_CACHE_DIR="${HF_CACHE_DIR:-$HOME/.cache/huggingface}"
export CONTAINER_CACHE_DIR="${CONTAINER_CACHE_DIR:-$REPO_ROOT/.docker-cache}"
export CONTAINER_DATA_DIR="${CONTAINER_DATA_DIR:-$REPO_ROOT/.docker-data}"
export DOCKER_UID="${DOCKER_UID:-$(id -u)}"
export DOCKER_GID="${DOCKER_GID:-$(id -g)}"

prepare_mounts() {
  mkdir -p \
    "$MODEL_DIR" \
    "$HF_CACHE_DIR" \
    "$CONTAINER_CACHE_DIR" \
    "$CONTAINER_DATA_DIR"
}

usage() {
  cat <<'EOF'
usage: scripts/docker_native.sh COMMAND [ARGS...]

Commands:
  build       Build the pinned native ExLlamaV3 image
  download    Download the model into the selected HF cache or local directory
  doctor      Verify CUDA, PyTorch, and the compiled ExLlamaV3 extension
  run         Start the interactive tuned chat; extra args go to chat.py
  shell       Open a shell in the isolated inference container

The default model source is the host Hugging Face cache at
~/.cache/huggingface. Setting MODEL_DIR automatically selects local-directory
mode. Environment overrides also include HF_CACHE_DIR, MODEL_SOURCE,
CONTEXT_SIZE, CACHE_QUANT, NUM_DRAFT_TOKENS, DRAFT_CONFIDENCE, CPUSET, and the
EXL3_* tuning variables.
EOF
}

command_name="${1:-}"
if [[ $# -gt 0 ]]; then
  shift
fi

case "$command_name" in
  build)
    exec docker compose build native "$@"
    ;;
  download)
    prepare_mounts
    exec docker compose run --rm --no-deps download download "$@"
    ;;
  doctor)
    prepare_mounts
    exec docker compose run --rm --no-deps -T native doctor "$@"
    ;;
  run)
    prepare_mounts
    exec docker compose run --rm --no-deps native chat "$@"
    ;;
  shell)
    prepare_mounts
    exec docker compose run --rm --no-deps native shell "$@"
    ;;
  -h|--help|help|"")
    usage
    ;;
  *)
    echo "unknown command: $command_name" >&2
    usage >&2
    exit 2
    ;;
esac
