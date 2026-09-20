#!/usr/bin/env python3
import platform
from pathlib import Path

import torch
from exllamav3 import ext


commit = Path("/opt/exllamav3/EXLLAMAV3_COMMIT").read_text().strip()
cuda_available = torch.cuda.is_available()

print(f"platform: {platform.system()} {platform.machine()}")
print(f"torch: {torch.__version__} (CUDA {torch.version.cuda})")
print(f"exllamav3: {commit}")
print(f"extension: {ext.exllamav3_ext.__file__}")
print(f"CUDA available: {cuda_available}")

if not cuda_available:
    raise SystemExit("CUDA is unavailable; check the NVIDIA Container Toolkit/CDI setup")

print(f"device: {torch.cuda.get_device_name(0)}")
print(f"compute capability: {torch.cuda.get_device_capability(0)}")

