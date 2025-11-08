"""
Storage module for discovering and accessing Cloud Storage buckets.

Main entry point: storage(environment) -> Bucket
"""

import logging
import os
from pathlib import Path
from typing import Optional

from google.auth import default as get_default_credentials

from .bucket import Bucket
from ..config import DatabotConfig
from ..core import StateLoader


logger = logging.getLogger(__name__)


def storage(environment: str = "dev") -> Bucket:
    """
    Get a Storage bucket for the given environment.

    Automatically discovers the bucket from terraform state files.

    Args:
        environment: Environment name (dev, prod, staging, etc.)

    Returns:
        Bucket object for the discovered bucket

    Example:
        >>> bucket = storage('dev')
        >>> files = bucket.list_files()
        >>> bucket.upload_file('local.txt', 'remote.txt')

    Raises:
        RuntimeError: If terraform state not found or bucket not configured
    """
    logger.debug(f"Discovering storage bucket for environment: {environment}")

    # Load configuration
    config = DatabotConfig(environment=environment)

    if not config.state_file_exists:
        raise RuntimeError(
            f"Terraform state file not found for {environment} environment. "
            "Make sure to run 'terraform apply' first."
        )

    # Load state
    loader = StateLoader(config.state_file)

    # Get bucket name for this environment
    bucket_names = config.get_bucket_names()

    if not bucket_names:
        raise RuntimeError(
            f"No storage buckets found in terraform state for {environment} environment"
        )

    # Get the appropriate bucket for this environment
    # Try environment-specific bucket first, then fall back to first available
    bucket_name = None
    for key, name in bucket_names.items():
        if environment.lower() in key.lower():
            bucket_name = name
            break

    if not bucket_name:
        # Fall back to first bucket
        bucket_name = list(bucket_names.values())[0]
        logger.warning(
            f"Using default bucket '{bucket_name}' as no {environment}-specific "
            "bucket was found"
        )

    logger.debug(f"Using bucket: {bucket_name}")

    # Get credentials (will use default application credentials)
    try:
        credentials, project = get_default_credentials()
    except Exception as e:
        logger.warning(f"Failed to get default credentials: {e}")
        credentials = None
        project = None

    # Create and return bucket
    bucket = Bucket(
        bucket_name=bucket_name,
        credentials=credentials,
        project_id=project,
    )

    return bucket


__all__ = ["storage", "Bucket"]
