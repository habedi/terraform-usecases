"""Validation tests for Terraform use cases."""

from pathlib import Path
import pytest

USE_CASES_DIR = Path(__file__).resolve().parent.parent / "use-cases"
USE_CASE_DIRS = sorted([d for d in USE_CASES_DIR.iterdir() if d.is_dir() and d.name.startswith("use-case-")])


def test_use_cases_exist() -> None:
    """Verify that use case directories exist."""
    assert len(USE_CASE_DIRS) >= 3


@pytest.mark.parametrize("use_case_dir", USE_CASE_DIRS, ids=lambda d: d.name)
def test_required_terraform_files(use_case_dir: Path) -> None:
    """Verify each use case contains required Terraform and documentation files."""
    required_files = ["main.tf", "variables.tf", "outputs.tf", "versions.tf", "README.md"]
    for filename in required_files:
        assert (use_case_dir / filename).exists(), f"{use_case_dir.name} missing {filename}"
