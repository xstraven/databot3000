"""
Terraform state loader for discovering infrastructure.

Reads terraform.tfstate files and provides convenient access to
infrastructure resources and outputs.
"""

import json
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional


logger = logging.getLogger(__name__)


class StateLoader:
    """Loads and parses Terraform state files."""

    def __init__(self, state_file: str):
        """
        Initialize StateLoader with a state file.

        Args:
            state_file: Path to terraform.tfstate file

        Raises:
            FileNotFoundError: If state file doesn't exist
            json.JSONDecodeError: If state file is invalid JSON
        """
        self.state_file = Path(state_file)

        if not self.state_file.exists():
            raise FileNotFoundError(f"State file not found: {state_file}")

        try:
            with open(self.state_file, "r") as f:
                self.state = json.load(f)
        except json.JSONDecodeError as e:
            raise json.JSONDecodeError(
                f"Failed to parse state file {state_file}: {e.msg}",
                e.doc,
                e.pos,
            )

        self._cache = {}

    @property
    def version(self) -> int:
        """Get terraform state version."""
        return self.state.get("version", 0)

    @property
    def terraform_version(self) -> Optional[str]:
        """Get terraform version that created the state."""
        return self.state.get("terraform_version")

    def get_outputs(self) -> Dict[str, Any]:
        """
        Get all outputs from state.

        Returns:
            Dictionary of {output_name: output_value}
        """
        if "outputs" not in self._cache:
            outputs = {}
            for key, output in self.state.get("outputs", {}).items():
                outputs[key] = output.get("value")
            self._cache["outputs"] = outputs

        return self._cache["outputs"]

    def get_output(self, name: str, default: Any = None) -> Any:
        """
        Get a specific output value.

        Args:
            name: Output name
            default: Default value if not found

        Returns:
            Output value or default
        """
        outputs = self.get_outputs()
        return outputs.get(name, default)

    def get_resources(self, resource_type: Optional[str] = None) -> Dict[str, List[Dict]]:
        """
        Get resources from state, optionally filtered by type.

        Args:
            resource_type: Optional resource type filter (e.g., 'aws_s3_bucket')

        Returns:
            Dictionary of {resource_type: [resource_instances]}
        """
        if "resources" not in self._cache:
            resources = {}
            for resource in self.state.get("resources", []):
                rtype = resource.get("type")
                if rtype not in resources:
                    resources[rtype] = []
                resources[rtype].append(resource)
            self._cache["resources"] = resources

        resources = self._cache["resources"]

        if resource_type:
            return {resource_type: resources.get(resource_type, [])}
        return resources

    def get_resource_instances(self, resource_type: str) -> List[Dict[str, Any]]:
        """
        Get all instances of a specific resource type.

        Args:
            resource_type: Type of resource (e.g., 'google_storage_bucket')

        Returns:
            List of resource instances
        """
        resources = self.get_resources(resource_type)
        return resources.get(resource_type, [])

    def find_resources_by_name(self, resource_type: str, name: str) -> List[Dict]:
        """
        Find resources by type and address name.

        Args:
            resource_type: Type of resource
            name: Name/address of resource

        Returns:
            List of matching resources
        """
        instances = self.get_resource_instances(resource_type)
        matches = []

        for instance in instances:
            if instance.get("name") == name or instance.get("address") == name:
                matches.append(instance)

        return matches

    def get_google_storage_buckets(self) -> Dict[str, str]:
        """
        Get all Google Cloud Storage buckets.

        Returns:
            Dictionary of {bucket_name: attributes}
        """
        buckets = {}
        instances = self.get_resource_instances("google_storage_bucket")

        for instance in instances:
            if instance.get("instances"):
                for inst in instance["instances"]:
                    attrs = inst.get("attributes", {})
                    bucket_name = attrs.get("name")
                    if bucket_name:
                        buckets[bucket_name] = attrs
        return buckets

    def get_google_service_accounts(self) -> Dict[str, str]:
        """
        Get all Google Service Accounts.

        Returns:
            Dictionary of {email: account_info}
        """
        accounts = {}
        instances = self.get_resource_instances("google_service_account")

        for instance in instances:
            if instance.get("instances"):
                for inst in instance["instances"]:
                    attrs = inst.get("attributes", {})
                    email = attrs.get("email")
                    if email:
                        accounts[email] = attrs
        return accounts

    def get_google_workbench_instances(self) -> Dict[str, str]:
        """
        Get all Vertex AI Workbench instances.

        Returns:
            Dictionary of {instance_name: attributes}
        """
        workbenches = {}
        instances = self.get_resource_instances("google_workbench_instance")

        for instance in instances:
            if instance.get("instances"):
                for inst in instance["instances"]:
                    attrs = inst.get("attributes", {})
                    name = attrs.get("name")
                    if name:
                        workbenches[name] = attrs
        return workbenches

    def get_module_outputs(self, module_name: str) -> Dict[str, Any]:
        """
        Get outputs from a specific module.

        Args:
            module_name: Module name (e.g., 'storage', 'api')

        Returns:
            Dictionary of module outputs
        """
        # Module outputs are in the main outputs but prefixed with module name
        outputs = self.get_outputs()
        module_outputs = {}

        for key, value in outputs.items():
            # Could be module.name.output_name format
            if key.startswith(f"{module_name}_"):
                output_key = key[len(module_name) + 1:]
                module_outputs[output_key] = value

        return module_outputs

    def __repr__(self) -> str:
        return f"StateLoader(state_file={self.state_file}, version={self.version})"
