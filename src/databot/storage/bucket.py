"""
Cloud Storage bucket wrapper and operations.

Provides convenient abstractions for working with Google Cloud Storage buckets.
"""

import logging
import json
from io import BytesIO
from pathlib import Path
from typing import Optional, List, BinaryIO

from google.cloud import storage
from google.auth.credentials import Credentials


logger = logging.getLogger(__name__)


class Bucket:
    """Wrapper around Google Cloud Storage bucket."""

    def __init__(self, bucket_name: str, credentials: Optional[Credentials] = None,
                 project_id: Optional[str] = None):
        """
        Initialize Bucket wrapper.

        Args:
            bucket_name: Name of the GCS bucket
            credentials: Google credentials object (optional)
            project_id: GCP project ID (optional)
        """
        self.bucket_name = bucket_name
        self.project_id = project_id

        # Initialize GCS client
        self.client = storage.Client(
            project=project_id,
            credentials=credentials,
        )

        # Get bucket reference
        self.bucket = self.client.bucket(bucket_name)

        logger.debug(f"Initialized bucket: {bucket_name}")

    def exists(self) -> bool:
        """Check if bucket exists."""
        return self.bucket.exists()

    def list_files(self, prefix: str = "", recursive: bool = False) -> List[str]:
        """
        List files in the bucket.

        Args:
            prefix: Filter by prefix (optional)
            recursive: If True, list all files. If False, list only top-level.

        Returns:
            List of blob names
        """
        delimiter = None if recursive else "/"

        blobs = self.client.list_blobs(
            self.bucket_name,
            prefix=prefix,
            delimiter=delimiter,
        )

        return [blob.name for blob in blobs]

    def upload_file(self, local_path: str, remote_path: str) -> None:
        """
        Upload a file to the bucket.

        Args:
            local_path: Path to local file
            remote_path: Path in bucket (blob name)

        Raises:
            FileNotFoundError: If local file doesn't exist
        """
        local_file = Path(local_path)
        if not local_file.exists():
            raise FileNotFoundError(f"File not found: {local_path}")

        blob = self.bucket.blob(remote_path)
        blob.upload_from_filename(str(local_path))
        logger.debug(f"Uploaded {local_path} to gs://{self.bucket_name}/{remote_path}")

    def upload_data(self, data: bytes, remote_path: str) -> None:
        """
        Upload data to the bucket.

        Args:
            data: Bytes to upload
            remote_path: Path in bucket (blob name)
        """
        blob = self.bucket.blob(remote_path)
        blob.upload_from_string(data)
        logger.debug(f"Uploaded {len(data)} bytes to gs://{self.bucket_name}/{remote_path}")

    def upload_json(self, obj: dict, remote_path: str) -> None:
        """
        Upload a JSON object to the bucket.

        Args:
            obj: Dictionary to serialize and upload
            remote_path: Path in bucket (blob name)
        """
        data = json.dumps(obj, indent=2).encode("utf-8")
        self.upload_data(data, remote_path)
        logger.debug(f"Uploaded JSON to gs://{self.bucket_name}/{remote_path}")

    def download_file(self, remote_path: str, local_path: str) -> None:
        """
        Download a file from the bucket.

        Args:
            remote_path: Path in bucket (blob name)
            local_path: Path to save file locally

        Raises:
            FileNotFoundError: If blob doesn't exist
        """
        blob = self.bucket.blob(remote_path)

        if not blob.exists():
            raise FileNotFoundError(f"Blob not found: {remote_path}")

        blob.download_to_filename(local_path)
        logger.debug(f"Downloaded gs://{self.bucket_name}/{remote_path} to {local_path}")

    def download_data(self, remote_path: str) -> bytes:
        """
        Download file as bytes from the bucket.

        Args:
            remote_path: Path in bucket (blob name)

        Returns:
            File contents as bytes

        Raises:
            FileNotFoundError: If blob doesn't exist
        """
        blob = self.bucket.blob(remote_path)

        if not blob.exists():
            raise FileNotFoundError(f"Blob not found: {remote_path}")

        return blob.download_as_bytes()

    def download_json(self, remote_path: str) -> dict:
        """
        Download and parse a JSON file from the bucket.

        Args:
            remote_path: Path in bucket (blob name)

        Returns:
            Parsed JSON object

        Raises:
            FileNotFoundError: If blob doesn't exist
            json.JSONDecodeError: If file is not valid JSON
        """
        data = self.download_data(remote_path)
        return json.loads(data.decode("utf-8"))

    def delete_file(self, remote_path: str) -> None:
        """
        Delete a file from the bucket.

        Args:
            remote_path: Path in bucket (blob name)
        """
        blob = self.bucket.blob(remote_path)
        blob.delete()
        logger.debug(f"Deleted gs://{self.bucket_name}/{remote_path}")

    def delete_prefix(self, prefix: str) -> int:
        """
        Delete all files with a given prefix.

        Args:
            prefix: Prefix to match

        Returns:
            Number of files deleted
        """
        blobs = self.client.list_blobs(self.bucket_name, prefix=prefix)
        count = 0
        for blob in blobs:
            blob.delete()
            count += 1
        logger.debug(f"Deleted {count} files with prefix {prefix}")
        return count

    def get_url(self, remote_path: str, expiration: Optional[int] = None) -> str:
        """
        Get a signed URL for a blob.

        Args:
            remote_path: Path in bucket (blob name)
            expiration: Expiration time in seconds (default: 1 hour)

        Returns:
            Signed URL string
        """
        blob = self.bucket.blob(remote_path)
        import datetime
        from google.cloud.storage import Blob

        if expiration is None:
            expiration = 3600  # 1 hour

        url = blob.generate_signed_url(
            version="v4",
            expiration=datetime.timedelta(seconds=expiration),
            method="GET",
        )
        return url

    def __repr__(self) -> str:
        return f"Bucket(name={self.bucket_name})"
