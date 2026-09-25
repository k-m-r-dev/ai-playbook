"""Stop the suite when no judge is configured. Do not skip cases."""

import os

import pytest

os.environ.setdefault("DEEPEVAL_TELEMETRY_OPT_OUT", "1")


def pytest_sessionstart(session):
    del session
    if os.environ.get("DEEPEVAL_MODEL") or os.environ.get("OPENAI_API_KEY"):
        return
    pytest.exit(
        "OPENAI_API_KEY or DEEPEVAL_MODEL is required. "
        "Refusing to skip cases or mark the suite done.",
        returncode=2,
    )
