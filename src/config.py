# src/config.py
"""
Configuration management for Event Embeddings Generator
"""

import os
from dataclasses import dataclass
from typing import Optional


@dataclass
class DatabaseConfig:
    """Database connection configuration"""
    host: str
    port: int
    dbname: str
    user: str
    password: str
    
    @property
    def connection_string(self) -> str:
        """Get PostgreSQL connection string"""
        return f"postgresql://{self.user}:{self.password}@{self.host}:{self.port}/{self.dbname}"
    
    def to_dict(self) -> dict:
        """Convert to dictionary for psycopg2"""
        return {
            'host': self.host,
            'port': self.port,
            'dbname': self.dbname,
            'user': self.user,
            'password': self.password
        }


@dataclass
class EmbeddingConfig:
    """Embedding model configuration"""
    model_name: str = "sentence-transformers/multi-qa-mpnet-base-dot-v1"
    dimension: int = 768
    device: str = "cpu"
    batch_size: int = 32
    normalize: bool = True


@dataclass
class ProcessingConfig:
    """Processing configuration"""
    incremental_mode: str = "auto"  # auto, true, false
    lookback_hours: int = 24
    init_databases: bool = True
    load_test_data: bool = False
    cache_dir: str = "/cache/.cache"


class Config:
    """Main configuration class"""
    
    def __init__(self):
        # Database configurations
        self.source_db = self._load_database_config("SOURCE")
        self.dest_db = self._load_database_config("DEST")
        
        # Embedding configuration
        self.embedding = EmbeddingConfig(
            model_name=os.getenv("EMBEDDING_MODEL_NAME", "sentence-transformers/multi-qa-mpnet-base-dot-v1"),
            dimension=int(os.getenv("EMBEDDING_DIM", "768")),
            device=os.getenv("EMBEDDING_DEVICE", "cpu"),
            batch_size=int(os.getenv("BATCH_SIZE", "32")),
            normalize=os.getenv("EMBEDDING_NORMALIZE", "true").lower() == "true"
        )
        
        # Processing configuration
        self.processing = ProcessingConfig(
            incremental_mode=os.getenv("INCREMENTAL_MODE", "auto").lower(),
            lookback_hours=int(os.getenv("LOOKBACK_HOURS", "24")),
            init_databases=os.getenv("INIT_DBS", "true").lower() == "true",
            load_test_data=os.getenv("LOAD_TEST_DATA", "false").lower() == "true",
            cache_dir=os.getenv("CACHE_DIR", "/cache/.cache")
        )
        
        # Table names
        self.table_names = {
            'sessions': 'session_embeddings',
            'speakers': 'speaker_embeddings',
            'sync_log': 'embeddings_sync_log'
        }
        
        # Set cache directories
        os.environ['TRANSFORMERS_CACHE'] = self.processing.cache_dir
        os.environ['SENTENCE_TRANSFORMERS_HOME'] = self.processing.cache_dir
    
    def _load_database_config(self, prefix: str) -> DatabaseConfig:
        """Load database configuration from environment variables"""
        return DatabaseConfig(
            host=os.getenv(f"DB_{prefix}_HOST", "localhost"),
            port=int(os.getenv(f"DB_{prefix}_PORT", "5432")),
            dbname=os.getenv(f"DB_{prefix}_NAME", f"{prefix.lower()}_db"),
            user=os.getenv(f"DB_{prefix}_USER", "postgres"),
            password=os.getenv(f"DB_{prefix}_PASSWORD", "")
        )
    
    def validate(self) -> bool:
        """Validate configuration"""
        errors = []
        
        # Check required database configs
        if not self.source_db.host or not self.source_db.password:
            errors.append("Source database configuration incomplete")
        
        if not self.dest_db.host or not self.dest_db.password:
            errors.append("Destination database configuration incomplete")
        
        # Check embedding dimension
        if self.embedding.dimension not in [384, 768, 1024]:
            errors.append(f"Unusual embedding dimension: {self.embedding.dimension}")
        
        # Check device
        if self.embedding.device not in ["cpu", "cuda", "mps"]:
            errors.append(f"Invalid device: {self.embedding.device}")
        
        if errors:
            for error in errors:
                print(f"Configuration Error: {error}")
            return False
        
        return True
    
    def __repr__(self) -> str:
        """String representation"""
        return (
            f"Config(\n"
            f"  source_db={self.source_db.host}:{self.source_db.port}/{self.source_db.dbname},\n"
            f"  dest_db={self.dest_db.host}:{self.dest_db.port}/{self.dest_db.dbname},\n"
            f"  model={self.embedding.model_name},\n"
            f"  device={self.embedding.device},\n"
            f"  incremental={self.processing.incremental_mode}\n"
            f")"
        )


# Global config instance
config = Config()
