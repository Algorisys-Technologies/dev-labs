import os
import logging
from datetime import datetime

class CustomLogger:
    def __init__(self, log_dir="logs"):
        # Ensure logs directory exists
        self.logs_dir = os.path.join(os.getcwd(), log_dir)
        os.makedirs(self.logs_dir, exist_ok=True)

        # Timestamped log file (for persistence)
        log_file = f"{datetime.now().strftime('%m_%d_%Y_%H_%M_%S')}.log"
        self.log_file_path = os.path.join(self.logs_dir, log_file)

    def get_logger(self, name=__file__):
        logger_name = os.path.basename(name)

        # Create logger
        logger = logging.getLogger(logger_name)
        logger.setLevel(logging.INFO)

        # Prevent duplicate handlers if logger already exists
        if not logger.handlers:
            # File handler
            file_handler = logging.FileHandler(self.log_file_path)
            file_handler.setLevel(logging.INFO)
            file_handler.setFormatter(logging.Formatter(
                "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
            ))

            # Console handler
            console_handler = logging.StreamHandler()
            console_handler.setLevel(logging.INFO)
            console_handler.setFormatter(logging.Formatter(
                "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
            ))

            logger.addHandler(file_handler)
            logger.addHandler(console_handler)

        return logger


# --- Usage Example ---
if __name__ == "__main__":
    logger = CustomLogger().get_logger(__file__)

    logger.info("User uploaded a file | user_id=123 | filename=report.pdf")
    logger.error("Failed to process PDF | error=File not found | user_id=123")
 