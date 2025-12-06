import os
from dotenv import load_dotenv

load_dotenv()


DEFAULT_MODEL = os.getenv("DEFAULT_MODEL", "llama3.2")
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
