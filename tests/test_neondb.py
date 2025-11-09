"""Tests for neondb module."""

import pytest
import asyncio
from unittest.mock import patch, AsyncMock, MagicMock
from databot.neondb import NeonClient, neondb


class TestNeonClient:
    """Tests for NeonClient class."""

    def test_init(self):
        """Test client initialization."""
        client = NeonClient("test_project", "test_db")
        assert client.project_name == "test_project"
        assert client.database_name == "test_db"
        assert client._pool is None
        assert client._conn is None

    def test_init_with_connection_string(self):
        """Test client initialization with connection string."""
        conn_str = "postgresql://user:pass@localhost/db"
        client = NeonClient("test_project", connection_string=conn_str)
        assert client._connection_string == conn_str

    @patch.dict("os.environ", {"NEON_TEST_PROJECT_NEONDB": "postgresql://test/db"})
    def test_discover_connection_string_from_env(self):
        """Test connection string discovery from environment variable."""
        client = NeonClient("test_project", "neondb")
        conn_str = client._discover_connection_string()
        assert conn_str == "postgresql://test/db"

    @patch.dict("os.environ", {"NEON_CONNECTION_STRING": "postgresql://fallback/db"})
    def test_discover_connection_string_fallback(self):
        """Test connection string discovery from fallback env variable."""
        client = NeonClient("unknown_project", "neondb")
        conn_str = client._discover_connection_string()
        assert conn_str == "postgresql://fallback/db"

    def test_discover_connection_string_not_found(self):
        """Test connection string discovery failure."""
        client = NeonClient("nonexistent_project", "neondb")
        with pytest.raises(RuntimeError, match="Could not discover connection string"):
            client._discover_connection_string()

    @pytest.mark.asyncio
    async def test_connect_single_connection(self):
        """Test establishing a single connection."""
        with patch("asyncpg.connect", new_callable=AsyncMock) as mock_connect:
            mock_conn = AsyncMock()
            mock_connect.return_value = mock_conn

            conn_str = "postgresql://user:pass@localhost/db"
            client = NeonClient("test", connection_string=conn_str)
            await client.connect(use_pool=False)

            mock_connect.assert_called_once_with(conn_str)
            assert client._conn == mock_conn

    @pytest.mark.asyncio
    async def test_connect_pool(self):
        """Test establishing a connection pool."""
        with patch("asyncpg.create_pool", new_callable=AsyncMock) as mock_create_pool:
            mock_pool = AsyncMock()
            mock_create_pool.return_value = mock_pool

            conn_str = "postgresql://user:pass@localhost/db"
            client = NeonClient("test", connection_string=conn_str)
            await client.connect(use_pool=True, pool_size=5)

            mock_create_pool.assert_called_once()
            assert client._pool == mock_pool

    @pytest.mark.asyncio
    async def test_context_manager(self):
        """Test using client as context manager."""
        with patch("asyncpg.connect", new_callable=AsyncMock) as mock_connect:
            mock_conn = AsyncMock()
            mock_connect.return_value = mock_conn

            conn_str = "postgresql://user:pass@localhost/db"
            async with NeonClient("test", connection_string=conn_str) as client:
                assert client._conn == mock_conn

            # Verify close was called
            mock_conn.close.assert_called_once()

    @pytest.mark.asyncio
    async def test_fetch(self):
        """Test fetch operation."""
        mock_conn = AsyncMock()
        mock_conn.fetch.return_value = [{"id": 1, "name": "test"}]

        conn_str = "postgresql://user:pass@localhost/db"
        client = NeonClient("test", connection_string=conn_str)
        client._conn = mock_conn

        result = await client.fetch("SELECT * FROM users")
        assert result == [{"id": 1, "name": "test"}]
        mock_conn.fetch.assert_called_once_with("SELECT * FROM users")

    @pytest.mark.asyncio
    async def test_fetchrow(self):
        """Test fetchrow operation."""
        mock_conn = AsyncMock()
        mock_conn.fetchrow.return_value = {"id": 1, "name": "test"}

        conn_str = "postgresql://user:pass@localhost/db"
        client = NeonClient("test", connection_string=conn_str)
        client._conn = mock_conn

        result = await client.fetchrow("SELECT * FROM users WHERE id = $1", 1)
        assert result == {"id": 1, "name": "test"}
        mock_conn.fetchrow.assert_called_once_with(
            "SELECT * FROM users WHERE id = $1", 1
        )

    @pytest.mark.asyncio
    async def test_fetchval(self):
        """Test fetchval operation."""
        mock_conn = AsyncMock()
        mock_conn.fetchval.return_value = 42

        conn_str = "postgresql://user:pass@localhost/db"
        client = NeonClient("test", connection_string=conn_str)
        client._conn = mock_conn

        result = await client.fetchval("SELECT COUNT(*) FROM users")
        assert result == 42
        mock_conn.fetchval.assert_called_once()

    @pytest.mark.asyncio
    async def test_execute(self):
        """Test execute operation."""
        mock_conn = AsyncMock()
        mock_conn.execute.return_value = "INSERT 0 1"

        conn_str = "postgresql://user:pass@localhost/db"
        client = NeonClient("test", connection_string=conn_str)
        client._conn = mock_conn

        result = await client.execute("INSERT INTO users (name) VALUES ($1)", "Alice")
        assert result == "INSERT 0 1"
        mock_conn.execute.assert_called_once_with(
            "INSERT INTO users (name) VALUES ($1)", "Alice"
        )

    @pytest.mark.asyncio
    async def test_fetch_without_connection(self):
        """Test fetch operation without established connection."""
        conn_str = "postgresql://user:pass@localhost/db"
        client = NeonClient("test", connection_string=conn_str)

        with pytest.raises(RuntimeError, match="Not connected"):
            await client.fetch("SELECT * FROM users")


def test_neondb_function():
    """Test neondb factory function."""
    client = neondb("test_project", "test_db")
    assert isinstance(client, NeonClient)
    assert client.project_name == "test_project"
    assert client.database_name == "test_db"


def test_neondb_function_with_defaults():
    """Test neondb factory function with default database."""
    client = neondb("test_project")
    assert isinstance(client, NeonClient)
    assert client.project_name == "test_project"
    assert client.database_name == "neondb"
