#!/usr/bin/env python3
import os
import sys
from pathlib import Path


model_dir = Path(sys.argv[1])
count = 0
for path in model_dir.iterdir():
    if not path.is_file():
        continue
    fd = os.open(path, os.O_RDONLY)
    try:
        os.posix_fadvise(fd, 0, 0, os.POSIX_FADV_DONTNEED)
    finally:
        os.close(fd)
    count += 1

print(f"fadvise DONTNEED on {count} model files")

