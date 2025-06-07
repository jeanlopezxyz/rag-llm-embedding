# src/utils.py
"""
Utility functions for Event Embeddings Generator
"""

import logging
import sys
import time
from contextlib import contextmanager
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple
import psycopg2
from psycopg2.extensions import connection as PostgresConnection
import numpy as np


def get_logger(name: str) -> logging.Logger:
    """
    Get a configured logger instance
    
    Args:
        name: Logger name (usually __name__)
    
    Returns:
        Configured logger instance
    """
    logger = logging.getLogger(name)
    
    # Only add handler if not already configured
    if not logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        logger.setLevel(logging.INFO)
    
    return logger


@contextmanager
def timer(name: str, logger: Optional[logging.Logger] = None):
    """
    Context manager for timing operations
    
    Args:
        name: Name of the operation
        logger: Logger instance (optional)
    
    Example:
        with timer("Processing embeddings", logger):
            process_embeddings()
    """
    start_time = time.time()
    if logger:
        logger.info(f"Starting: {name}")
    
    try:
        yield
    finally:
        elapsed = time.time() - start_time
        message = f"Completed: {name} (took {elapsed:.2f} seconds)"
        if logger:
            logger.info(message)
        else:
            print(message)


def batch_iterator(items: List[Any], batch_size: int):
    """
    Yield successive batches from a list
    
    Args:
        items: List of items to batch
        batch_size: Size of each batch
    
    Yields:
        Batches of items
    """
    for i in range(0, len(items), batch_size):
        yield items[i:i + batch_size]


def ensure_timezone_aware(dt: datetime) -> datetime:
    """
    Ensure datetime is timezone-aware (UTC)
    
    Args:
        dt: Datetime object
    
    Returns:
        Timezone-aware datetime
    """
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


def clean_text(text: Optional[str]) -> str:
    """
    Clean text for embedding generation
    
    Args:
        text: Input text
    
    Returns:
        Cleaned text
    """
    if not text:
        return ""
    
    # Remove excessive whitespace
    text = " ".join(text.split())
    
    # Remove null characters
    text = text.replace('\x00', '')
    
    # Limit length (some models have token limits)
    max_length = 1000  # Adjust based on your model
    if len(text) > max_length:
        text = text[:max_length] + "..."
    
    return text.strip()


def format_list_human(items: List[str], max_items: int = 5) -> str:
    """
    Format a list for human-readable output
    
    Args:
        items: List of strings
        max_items: Maximum items to show
    
    Returns:
        Formatted string
    """
    if not items:
        return ""
    
    if len(items) <= max_items:
        if len(items) == 1:
            return items[0]
        elif len(items) == 2:
            return f"{items[0]} y {items[1]}"
        else:
            return ", ".join(items[:-1]) + f" y {items[-1]}"
    else:
        shown = items[:max_items]
        remaining = len(items) - max_items
        return ", ".join(shown) + f" y {remaining} más"


def safe_json_dumps(obj: Any) -> str:
    """
    Safely convert object to JSON string
    
    Args:
        obj: Object to convert
    
    Returns:
        JSON string
    """
    import json
    from datetime import date, time
    
    def json_serializer(o):
        if isinstance(o, (datetime, date, time)):
            return o.isoformat()
        elif isinstance(o, np.ndarray):
            return o.tolist()
        elif hasattr(o, '__dict__'):
            return o.__dict__
        else:
            return str(o)
    
    return json.dumps(obj, default=json_serializer, ensure_ascii=False)


class DatabaseConnection:
    """
    Database connection manager with retry logic
    """
    
    def __init__(self, config: Dict[str, Any], max_retries: int = 3):
        self.config = config
        self.max_retries = max_retries
        self.connection: Optional[PostgresConnection] = None
        self.logger = get_logger(self.__class__.__name__)
    
    def connect(self) -> PostgresConnection:
        """
        Establish database connection with retry logic
        """
        for attempt in range(self.max_retries):
            try:
                self.connection = psycopg2.connect(**self.config)
                self.logger.info(f"Connected to database: {self.config['dbname']}")
                return self.connection
            except psycopg2.Error as e:
                self.logger.warning(f"Connection attempt {attempt + 1} failed: {e}")
                if attempt < self.max_retries - 1:
                    time.sleep(2 ** attempt)  # Exponential backoff
                else:
                    raise
    
    def execute_query(self, query: str, params: Optional[Tuple] = None) -> List[Tuple]:
        """
        Execute a query and return results
        """
        if not self.connection or self.connection.closed:
            self.connect()
        
        try:
            with self.connection.cursor() as cur:
                cur.execute(query, params)
                if cur.description:  # Query returns data
                    return cur.fetchall()
                else:  # Query doesn't return data (INSERT, UPDATE, etc.)
                    self.connection.commit()
                    return []
        except psycopg2.Error as e:
            self.logger.error(f"Query execution failed: {e}")
            self.connection.rollback()
            raise
    
    def close(self):
        """Close database connection"""
        if self.connection and not self.connection.closed:
            self.connection.close()
            self.logger.info("Database connection closed")
    
    def __enter__(self):
        self.connect()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()


class ProgressTracker:
    """
    Track and display progress for batch operations
    """
    
    def __init__(self, total: int, desc: str = "Processing", logger: Optional[logging.Logger] = None):
        self.total = total
        self.desc = desc
        self.current = 0
        self.start_time = time.time()
        self.logger = logger or get_logger(self.__class__.__name__)
        self.last_log_percent = 0
    
    def update(self, n: int = 1):
        """Update progress"""
        self.current += n
        percent = (self.current / self.total) * 100 if self.total > 0 else 0
        
        # Log every 10%
        if percent >= self.last_log_percent + 10:
            elapsed = time.time() - self.start_time
            rate = self.current / elapsed if elapsed > 0 else 0
            eta = (self.total - self.current) / rate if rate > 0 else 0
            
            self.logger.info(
                f"{self.desc}: {self.current}/{self.total} ({percent:.1f}%) - "
                f"Rate: {rate:.1f} items/s - ETA: {eta:.0f}s"
            )
            self.last_log_percent = int(percent / 10) * 10
    
    def finish(self):
        """Mark as finished"""
        elapsed = time.time() - self.start_time
        rate = self.total / elapsed if elapsed > 0 else 0
        self.logger.info(
            f"{self.desc}: Completed {self.total} items in {elapsed:.1f}s "
            f"({rate:.1f} items/s)"
        )
    
    def __enter__(self):
        """Enter context manager"""
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Exit context manager"""
        if exc_type is None:
            self.finish()
        return False


def validate_embeddings(embeddings: np.ndarray, expected_dim: int) -> bool:
    """
    Validate embeddings array
    
    Args:
        embeddings: Numpy array of embeddings
        expected_dim: Expected dimension
    
    Returns:
        True if valid, False otherwise
    """
    if not isinstance(embeddings, np.ndarray):
        return False
    
    if len(embeddings.shape) == 1:
        # Single embedding
        return embeddings.shape[0] == expected_dim
    elif len(embeddings.shape) == 2:
        # Batch of embeddings
        return embeddings.shape[1] == expected_dim
    else:
        return False


def format_duration(seconds: float) -> str:
    """
    Format duration in seconds to human-readable string
    
    Args:
        seconds: Duration in seconds
    
    Returns:
        Formatted string (e.g., "2h 15m 30s")
    """
    hours, remainder = divmod(int(seconds), 3600)
    minutes, seconds = divmod(remainder, 60)
    
    parts = []
    if hours > 0:
        parts.append(f"{hours}h")
    if minutes > 0:
        parts.append(f"{minutes}m")
    if seconds > 0 or not parts:
        parts.append(f"{seconds}s")
    
    return " ".join(parts)
