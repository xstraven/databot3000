"""
Neon database client for connecting to Neon PostgreSQL databases.

This module discovers Neon project connection strings from environment variables
or MCP tools and provides an async PostgreSQL client interface.
"""

import asyncpg
import logging
import os
from typing import Optional, Dict, Any, List
from pathlib import Path
import json


logger = logging.getLogger(__name__)


class NeonClient:
    """
    Async PostgreSQL client for Neon databases.

    Example:
        >>> async with NeonClient("databot", "neondb") as client:
        ...     result = await client.fetch("SELECT * FROM users")
        ...     print(result)
    """

    def __init__(
        self,
        project_name: str,
        database_name: str = "neondb",
        connection_string: Optional[str] = None,
    ):
        """
        Initialize Neon client.

        Args:
            project_name: Name of the Neon project
            database_name: Name of the database (default: neondb)
            connection_string: Optional connection string. If not provided,
                             will be discovered from environment or config.
        """
        self.project_name = project_name
        self.database_name = database_name
        self._connection_string = connection_string
        self._pool: Optional[asyncpg.Pool] = None
        self._conn: Optional[asyncpg.Connection] = None

    def _discover_connection_string(self) -> str:
        """
        Discover connection string from environment or config files.

        Returns:
            Connection string for the Neon database

        Raises:
            RuntimeError: If connection string cannot be discovered
        """
        # Try environment variable first (pattern: NEON_<PROJECT>_<DATABASE>)
        env_key = f"NEON_{self.project_name.upper()}_{self.database_name.upper()}"
        if env_key in os.environ:
            logger.debug(f"Found connection string in environment: {env_key}")
            return os.environ[env_key]

        # Try generic NEON_CONNECTION_STRING
        if "NEON_CONNECTION_STRING" in os.environ:
            logger.debug("Found NEON_CONNECTION_STRING in environment")
            return os.environ["NEON_CONNECTION_STRING"]

        # Try to load from config file
        config_paths = [
            Path.home() / ".config" / "databot" / "neon.json",
            Path(".neon.json"),
            Path("neon.json"),
        ]

        for config_path in config_paths:
            if config_path.exists():
                try:
                    with open(config_path) as f:
                        config = json.load(f)
                        if self.project_name in config:
                            project_config = config[self.project_name]
                            if isinstance(project_config, dict):
                                conn_str = project_config.get(self.database_name)
                            else:
                                conn_str = project_config

                            if conn_str:
                                logger.debug(f"Found connection string in {config_path}")
                                return conn_str
                except (json.JSONDecodeError, IOError) as e:
                    logger.warning(f"Failed to load config from {config_path}: {e}")

        raise RuntimeError(
            f"Could not discover connection string for project '{self.project_name}' "
            f"and database '{self.database_name}'. "
            f"Set environment variable {env_key} or NEON_CONNECTION_STRING, "
            f"or create a config file at ~/.config/databot/neon.json"
        )

    @property
    def connection_string(self) -> str:
        """Get the connection string, discovering it if necessary."""
        if not self._connection_string:
            self._connection_string = self._discover_connection_string()
        return self._connection_string

    async def connect(self, use_pool: bool = False, pool_size: int = 10) -> None:
        """
        Establish connection to the database.

        Args:
            use_pool: If True, create a connection pool. Otherwise, single connection.
            pool_size: Size of connection pool (only used if use_pool=True)
        """
        if use_pool:
            if not self._pool:
                logger.debug(f"Creating connection pool for {self.project_name}")
                self._pool = await asyncpg.create_pool(
                    self.connection_string,
                    min_size=1,
                    max_size=pool_size,
                )
        else:
            if not self._conn:
                logger.debug(f"Creating connection to {self.project_name}")
                self._conn = await asyncpg.connect(self.connection_string)

    async def close(self) -> None:
        """Close the database connection or pool."""
        if self._pool:
            await self._pool.close()
            self._pool = None
        if self._conn:
            await self._conn.close()
            self._conn = None

    async def __aenter__(self):
        """Context manager entry - establishes connection."""
        await self.connect()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit - closes connection."""
        await self.close()

    async def fetch(self, query: str, *args) -> List[asyncpg.Record]:
        """
        Fetch multiple rows.

        Args:
            query: SQL query
            *args: Query parameters

        Returns:
            List of records

        Example:
            >>> rows = await client.fetch("SELECT * FROM users WHERE age > $1", 18)
        """
        if self._pool:
            async with self._pool.acquire() as conn:
                return await conn.fetch(query, *args)
        elif self._conn:
            return await self._conn.fetch(query, *args)
        else:
            raise RuntimeError("Not connected. Call connect() or use context manager.")

    async def fetchrow(self, query: str, *args) -> Optional[asyncpg.Record]:
        """
        Fetch a single row.

        Args:
            query: SQL query
            *args: Query parameters

        Returns:
            Single record or None

        Example:
            >>> row = await client.fetchrow("SELECT * FROM users WHERE id = $1", 123)
        """
        if self._pool:
            async with self._pool.acquire() as conn:
                return await conn.fetchrow(query, *args)
        elif self._conn:
            return await self._conn.fetchrow(query, *args)
        else:
            raise RuntimeError("Not connected. Call connect() or use context manager.")

    async def fetchval(self, query: str, *args, column: int = 0) -> Any:
        """
        Fetch a single value.

        Args:
            query: SQL query
            *args: Query parameters
            column: Column index to return (default: 0)

        Returns:
            Single value

        Example:
            >>> count = await client.fetchval("SELECT COUNT(*) FROM users")
        """
        if self._pool:
            async with self._pool.acquire() as conn:
                return await conn.fetchval(query, *args, column=column)
        elif self._conn:
            return await self._conn.fetchval(query, *args, column=column)
        else:
            raise RuntimeError("Not connected. Call connect() or use context manager.")

    async def execute(self, query: str, *args) -> str:
        """
        Execute a query without returning results.

        Args:
            query: SQL query
            *args: Query parameters

        Returns:
            Status string (e.g., "INSERT 0 1")

        Example:
            >>> await client.execute("INSERT INTO users (name) VALUES ($1)", "Alice")
        """
        if self._pool:
            async with self._pool.acquire() as conn:
                return await conn.execute(query, *args)
        elif self._conn:
            return await self._conn.execute(query, *args)
        else:
            raise RuntimeError("Not connected. Call connect() or use context manager.")

    async def executemany(self, query: str, args_list: List[tuple]) -> None:
        """
        Execute a query multiple times with different parameters.

        Args:
            query: SQL query
            args_list: List of parameter tuples

        Example:
            >>> await client.executemany(
            ...     "INSERT INTO users (name, age) VALUES ($1, $2)",
            ...     [("Alice", 30), ("Bob", 25)]
            ... )
        """
        if self._pool:
            async with self._pool.acquire() as conn:
                await conn.executemany(query, args_list)
        elif self._conn:
            await self._conn.executemany(query, args_list)
        else:
            raise RuntimeError("Not connected. Call connect() or use context manager.")

    def __repr__(self) -> str:
        return f"NeonClient(project={self.project_name}, database={self.database_name})"


def neondb(
    project_name: str,
    database_name: str = "neondb",
    connection_string: Optional[str] = None,
) -> NeonClient:
    """
    Get a Neon database client.

    Args:
        project_name: Name of the Neon project
        database_name: Name of the database (default: neondb)
        connection_string: Optional connection string

    Returns:
        NeonClient instance

    Example:
        >>> async with neondb("databot") as client:
        ...     users = await client.fetch("SELECT * FROM users")
        ...     print(users)
    """
    return NeonClient(project_name, database_name, connection_string)
