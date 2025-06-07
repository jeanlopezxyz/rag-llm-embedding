# src/__init__.py
"""
Event Embeddings Generator Package

This package provides tools for generating embeddings from event data
and storing them in PGVector for semantic search capabilities.
"""

__version__ = "1.0.0"
__author__ = "Your Team"
__email__ = "team@company.com"

from .config import Config
from .utils import get_logger

# Package-level logger
logger = get_logger(__name__)
