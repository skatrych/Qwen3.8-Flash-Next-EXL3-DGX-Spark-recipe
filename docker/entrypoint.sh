#!/usr/bin/env bash
set -euo pipefail

command_name="${1:-chat}"
if [[ $# -gt 0 ]]; then
  shift
fi

case "$command_name" in
  chat)
    case "${MODEL_SOURCE:-cache}" in
      cache)
        model_path="$(resolve-hf-model)"
        ;;
      local)
        model_path="$MODEL_PATH"
        if [[ ! -f "$model_path/config.json" ]]; then
          echo "Model not found at $model_path (missing config.json)." >&2
          echo "Run 'scripts/docker_native.sh download' or set MODEL_DIR to an existing pack." >&2
          exit 1
        fi
        ;;
      *)
        echo "MODEL_SOURCE must be 'cache' or 'local', got '${MODEL_SOURCE}'." >&2
        exit 2
        ;;
    esac

    if [[ "${DROP_MODEL_CACHE:-1}" == "1" ]]; then
      drop-model-cache "$model_path"
    fi

    args=(
      -m "$model_path"
      -mode "${PROMPT_MODE:-qwen35}"
      -mtp
      -ndt "${NUM_DRAFT_TOKENS:-5}"
      -dds
      -dc "${DRAFT_CONFIDENCE:-0.6}"
      -cq "${CACHE_QUANT:-8,8}"
      -cs "${CONTEXT_SIZE:-262144}"
      -tps
    )
    exec python examples/chat.py "${args[@]}" "$@"
    ;;
  doctor)
    exec exllamav3-doctor "$@"
    ;;
  download)
    download_args=(
      "${HF_REPO:-turboderp/Qwen3.8-Flash-Next-exl3}"
      --revision "${HF_REVISION:-3.05bpw_h5_ng5}"
    )
    case "${MODEL_SOURCE:-cache}" in
      cache) ;;
      local) download_args+=(--local-dir "$MODEL_PATH") ;;
      *)
        echo "MODEL_SOURCE must be 'cache' or 'local', got '${MODEL_SOURCE}'." >&2
        exit 2
        ;;
    esac
    exec hf download "${download_args[@]}" "$@"
    ;;
  shell)
    exec bash "$@"
    ;;
  *)
    exec "$command_name" "$@"
    ;;
esac
