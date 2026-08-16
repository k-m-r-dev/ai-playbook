#!/usr/bin/env python3
"""W2C smoke — same checks as `w2c.py smoke`."""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from w2c import main_smoke  # noqa: E402

if __name__ == "__main__":
    raise SystemExit(main_smoke())
