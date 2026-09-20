#!/usr/bin/env python3
import os
import re
from pathlib import Path

repo_id = os.environ.get("HF_REPO", "turboderp/Qwen3.8-Flash-Next-exl3")
revision = os.environ.get("HF_REVISION", "3.05bpw_h5_ng5")
hf_home = Path(os.environ.get("HF_HOME", "/huggingface"))

if not re.fullmatch(r"[A-Za-z0-9._-]+/[A-Za-z0-9._-]+", repo_id):
    raise SystemExit(f"Invalid HF_REPO: {repo_id}")
if Path(revision).is_absolute() or ".." in Path(revision).parts:
    raise SystemExit(f"Invalid HF_REVISION: {revision}")

repo_cache = hf_home / "hub" / f"models--{repo_id.replace('/', '--')}"
ref = repo_cache / "refs" / revision
snapshot_id = ref.read_text().strip() if ref.is_file() else revision
snapshot = repo_cache / "snapshots" / snapshot_id

if not (snapshot / "config.json").is_file():
    raise SystemExit(
        f"{repo_id}@{revision} is not available in HF_HOME={hf_home}. "
        "Run 'scripts/docker_native.sh download' first."
    )

print(snapshot)
