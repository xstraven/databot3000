"""
Service account authentication utilities.

Handles authentication using Google Cloud service accounts discovered
from terraform state.
"""

import json
import logging
import os
from pathlib import Path
from typing import Optional

from google.auth import default
from google.oauth2 import service_account


logger = logging.getLogger(__name__)


class ServiceAccountAuth:
    """Manages authentication with Google Cloud service accounts."""

    def __init__(self, service_account_email: Optional[str] = None,
                 key_file: Optional[str] = None,
                 scopes: Optional[list] = None):
        """
        Initialize service account authentication.

        Args:
            service_account_email: Email of the service account
            key_file: Path to service account key JSON file
            scopes: OAuth scopes to use
        """
        self.service_account_email = service_account_email
        self.key_file = key_file
        self.scopes = scopes or [
            "https://www.googleapis.com/auth/cloud-platform",
        ]
        self._credentials = None

    def get_credentials(self):
        """
        Get credentials for authentication.

        Returns:
            Google credentials object
        """
        if self._credentials:
            return self._credentials

        if self.key_file and os.path.exists(self.key_file):
            # Use service account key file
            self._credentials = service_account.Credentials.from_service_account_file(
                self.key_file,
                scopes=self.scopes,
            )
            logger.debug(f"Authenticated with service account key: {self.key_file}")
        else:
            # Use Application Default Credentials
            self._credentials, _ = default(scopes=self.scopes)
            logger.debug("Using Application Default Credentials")

        return self._credentials

    @classmethod
    def from_state(cls, service_account_email: str, key_file: Optional[str] = None):
        """
        Create ServiceAccountAuth from terraform state.

        Args:
            service_account_email: Email from terraform state
            key_file: Path to service account key (optional)

        Returns:
            ServiceAccountAuth instance
        """
        return cls(service_account_email=service_account_email, key_file=key_file)

    def get_access_token(self) -> str:
        """
        Get access token for API calls.

        Returns:
            Access token string
        """
        credentials = self.get_credentials()
        if hasattr(credentials, "token"):
            if not credentials.token:
                credentials.refresh(
                    # For service accounts, we might need to refresh manually
                    from google.auth.transport.requests import Request
                    Request()
                )
            return credentials.token
        raise RuntimeError("Cannot get access token from credentials")

    def __repr__(self) -> str:
        return (f"ServiceAccountAuth(email={self.service_account_email}, "
                f"key_file={self.key_file})")
