"""
Databot3000 - Infrastructure management for personal AI projects on GCP.

Main entry points:
    storage(env) - Get a storage bucket for the environment
    from databot.core import StateLoader
    from databot.auth import ServiceAccountAuth
"""

from .storage import storage, Bucket
from .config import DatabotConfig
from .core import StateLoader
from .auth import ServiceAccountAuth


__version__ = "0.1.0"
__author__ = "David"


__all__ = [
    "storage",
    "Bucket",
    "DatabotConfig",
    "StateLoader",
    "ServiceAccountAuth",
]
