"""
Logging configuration for Zedin Steam Manager
"""
import logging
import logging.handlers
import os
import sys
from datetime import datetime
from pathlib import Path

# Create logs directory if it doesn't exist
LOGS_DIR = Path(__file__).parent.parent / "logs"
LOGS_DIR.mkdir(exist_ok=True)

# Log file paths
API_LOG_FILE = LOGS_DIR / "api.log"
ERROR_LOG_FILE = LOGS_DIR / "errors.log"
AUTH_LOG_FILE = LOGS_DIR / "auth.log"
SYSTEM_LOG_FILE = LOGS_DIR / "system.log"

class CustomFormatter(logging.Formatter):
    """Custom formatter with colors for console output"""
    
    grey = "\x1b[38;20m"
    yellow = "\x1b[33;20m"
    red = "\x1b[31;20m"
    bold_red = "\x1b[31;1m"
    blue = "\x1b[34;20m"
    green = "\x1b[32;20m"
    reset = "\x1b[0m"
    format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

    FORMATS = {
        logging.DEBUG: grey + format + reset,
        logging.INFO: blue + format + reset,
        logging.WARNING: yellow + format + reset,
        logging.ERROR: red + format + reset,
        logging.CRITICAL: bold_red + format + reset
    }

    def format(self, record):
        log_fmt = self.FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt)
        return formatter.format(record)

def setup_logger(name: str, log_file: str = None, level: int = logging.INFO) -> logging.Logger:
    """Set up logger with file and console handlers"""
    
    logger = logging.getLogger(name)
    logger.setLevel(level)
    
    # Remove existing handlers to avoid duplicates
    for handler in logger.handlers[:]:
        logger.removeHandler(handler)
    
    # Console handler with colors
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(CustomFormatter())
    logger.addHandler(console_handler)
    
    # File handler if log file specified
    if log_file:
        file_handler = logging.handlers.RotatingFileHandler(
            log_file,
            maxBytes=10*1024*1024,  # 10MB
            backupCount=5,
            encoding='utf-8'
        )
        file_handler.setLevel(logging.DEBUG)
        file_formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        file_handler.setFormatter(file_formatter)
        logger.addHandler(file_handler)
    
    return logger

# Create main loggers
api_logger = setup_logger("zedin.api", API_LOG_FILE)
error_logger = setup_logger("zedin.errors", ERROR_LOG_FILE)
auth_logger = setup_logger("zedin.auth", AUTH_LOG_FILE)
system_logger = setup_logger("zedin.system", SYSTEM_LOG_FILE)

def log_api_request(method: str, path: str, status_code: int, response_time: float = None):
    """Log API requests"""
    message = f"{method} {path} - Status: {status_code}"
    if response_time:
        message += f" - Response time: {response_time:.3f}s"
    api_logger.info(message)

def log_error(error: Exception, context: str = None):
    """Log errors with context"""
    message = f"Error: {str(error)}"
    if context:
        message = f"[{context}] {message}"
    error_logger.error(message, exc_info=True)

def log_auth_event(event: str, user_email: str = None, success: bool = True):
    """Log authentication events"""
    status = "SUCCESS" if success else "FAILED"
    message = f"Auth {event} - {status}"
    if user_email:
        message += f" - User: {user_email}"
    auth_logger.info(message)

def log_system_info(message: str):
    """Log system information"""
    system_logger.info(message)

# Initialize logging when imported
def init_logging():
    """Initialize logging system"""
    system_logger.info("=" * 60)
    system_logger.info("🚀 Zedin Steam Manager - Logging System Initialized")
    system_logger.info(f"📁 Log Directory: {LOGS_DIR}")
    system_logger.info(f"⏰ Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    system_logger.info("=" * 60)

# Auto-initialize when imported
init_logging()