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
import numpy as np

import psycopg
from psycopg.connection import Connection as PostgresConnection

def get_logger(name: str) -> logging.Logger:
    """
    Get a configured logger instance
    """
    logger = logging.getLogger(name)
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
    """
    for i in range(0, len(items), batch_size):
        yield items[i:i + batch_size]

def ensure_timezone_aware(dt: datetime) -> datetime:
    """
    Ensure datetime is timezone-aware (UTC)
    """
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt

def clean_text(text: Optional[str]) -> str:
    """
    Clean text for embedding generation
    """
    if not text:
        return ""
    text = " ".join(text.split())
    text = text.replace('\x00', '')
    max_length = 1000
    if len(text) > max_length:
        text = text[:max_length] + "..."
    return text.strip()

def format_list_human(items: List[str], max_items: int = 5) -> str:
    """
    Format a list for human-readable output
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

# MODIFICACIÓN: La clase DatabaseConnection se reescribe para usar psycopg (v3).
class DatabaseConnection:
    """
    Database connection manager with retry logic, using psycopg (v3).
    """
    
    def __init__(self, config: Dict[str, Any], max_retries: int = 3):
        self.conninfo = " ".join([f"{k}='{v}'" for k, v in config.items()])
        self.max_retries = max_retries
        self.connection: Optional[PostgresConnection] = None
        self.logger = get_logger(self.__class__.__name__)
    
    def connect(self) -> PostgresConnection:
        """
        Establish database connection with retry logic
        """
        for attempt in range(self.max_retries):
            try:
                if not self.connection or self.connection.closed:
                    self.connection = psycopg.connect(self.conninfo)
                self.logger.info(f"Connected to database.")
                return self.connection
            except psycopg.OperationalError as e:
                self.logger.warning(f"Connection attempt {attempt + 1} failed: {e}")
                if attempt < self.max_retries - 1:
                    time.sleep(2 ** attempt)
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
                if cur.description:
                    return cur.fetchall()
                else:
                    self.connection.commit()
                    return []
        except psycopg.Error as e:
            self.logger.error(f"Query execution failed: {e}")
            if self.connection:
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

# --- El resto de las clases y funciones no necesitan cambios ---

class ProgressTracker:
    # ... (sin cambios)
    def __init__(self, total: int, desc: str = "Processing", logger: Optional[logging.Logger] = None):
        self.total = total
        self.desc = desc
        self.current = 0
        self.start_time = time.time()
        self.logger = logger or get_logger(self.__class__.__name__)
        self.last_log_percent = 0
    
    def update(self, n: int = 1):
        self.current += n
        percent = (self.current / self.total) * 100 if self.total > 0 else 0
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
        elapsed = time.time() - self.start_time
        rate = self.total / elapsed if elapsed > 0 else 0
        self.logger.info(
            f"{self.desc}: Completed {self.total} items in {elapsed:.1f}s "
            f"({rate:.1f} items/s)"
        )
    
    def __enter__(self):
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is None:
            self.finish()
        return False

def validate_embeddings(embeddings: np.ndarray, expected_dim: int) -> bool:
    # ... (sin cambios)
    if not isinstance(embeddings, np.ndarray):
        return False
    if len(embeddings.shape) == 1:
        return embeddings.shape[0] == expected_dim
    elif len(embeddings.shape) == 2:
        return embeddings.shape[1] == expected_dim
    else:
        return False

def format_duration(seconds: float) -> str:
    # ... (sin cambios)
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