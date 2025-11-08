"""
Configuration management for databot.

Handles loading configuration from terraform state files and environment variables.
"""

import os
import json
from pathlib import Path
from typing import Optional


class DatabotConfig:
    """Configuration loader for databot infrastructure."""

    def __init__(self, state_file: Optional[str] = None, environment: str = "dev"):
        """
        Initialize configuration.

        Args:
            state_file: Path to terraform state file. If not provided, searches for it.
            environment: Environment name (dev, prod, etc.)
        """
        self.environment = environment
        self.state_file = state_file or self._find_state_file()
        self.state = {}

        if self.state_file and os.path.exists(self.state_file):
            self._load_state()

    def _find_state_file(self) -> Optional[str]:
        """Find terraform state file in common locations."""
        search_paths = [
            # Current working directory
            Path("terraform.tfstate"),
            # terraform/environments/dev
            Path("terraform/environments") / self.environment / "terraform.tfstate",
            # terraform/environments/prod
            Path("terraform/environments") / self.environment / "terraform.tfstate",
            # terraform/live/production
            Path("terraform/live/production/terraform.tfstate"),
        ]

        for path in search_paths:
            if path.exists():
                return str(path)

        return None

    def _load_state(self):
        """Load and parse terraform state file."""
        try:
            with open(self.state_file, "r") as f:
                self.state = json.load(f)
        except (IOError, json.JSONDecodeError) as e:
            raise RuntimeError(f"Failed to load state file {self.state_file}: {e}")

    def get_outputs(self) -> dict:
        """Get all outputs from terraform state."""
        if not self.state:
            return {}
        return self.state.get("outputs", {})

    def get_output(self, key: str, default=None):
        """Get a specific output value."""
        outputs = self.get_outputs()
        if key in outputs:
            output = outputs[key]
            # Terraform state stores values in a structured format
            return output.get("value", default)
        return default

    def get_resources(self, resource_type: Optional[str] = None) -> dict:
        """Get resources from terraform state."""
        if not self.state:
            return {}

        resources = {}
        for module in self.state.get("resources", []):
            if resource_type is None or module.get("type") == resource_type:
                resources[module.get("type", "unknown")] = module.get("instances", [])

        return resources

    def get_bucket_names(self) -> dict:
        """Get all storage bucket names."""
        buckets = {}
        outputs = self.get_outputs()

        # Look for outputs containing "bucket"
        for key, output in outputs.items():
            if "bucket" in key.lower():
                value = output.get("value")
                if value:
                    buckets[key] = value

        return buckets

    def get_service_account_email(self) -> Optional[str]:
        """Get service account email for current environment."""
        outputs = self.get_outputs()

        # Look for service account email output
        for key, output in outputs.items():
            if "service_account_email" in key.lower():
                value = output.get("value")
                if value:
                    return value

        return None

    @property
    def state_file_exists(self) -> bool:
        """Check if state file exists."""
        return self.state_file is not None and os.path.exists(self.state_file)

    def __repr__(self) -> str:
        return f"DatabotConfig(environment={self.environment}, state_file={self.state_file})"
