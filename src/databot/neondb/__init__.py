"""
Neon database module for discovering and connecting to Neon PostgreSQL databases.

Main entry point: neondb(project_name, database_name) -> NeonClient
"""

from .client import NeonClient, neondb

__all__ = ["NeonClient", "neondb"]
