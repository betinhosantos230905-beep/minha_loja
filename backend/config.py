import os
from pathlib import Path

from dotenv import load_dotenv


# Pasta principal do projeto Minha Loja.
BASE_DIR = Path(__file__).resolve().parent.parent

# Carrega o .env local (se existir). Na Vercel as variáveis vêm do painel.
ENV_FILE = BASE_DIR / ".env"
load_dotenv(ENV_FILE, override=True)


_DEBUG = os.getenv("FLASK_DEBUG", "0") == "1"


def _obter_secret_key():
    chave = os.getenv("SECRET_KEY", "").strip()

    if chave:
        return chave

    if _DEBUG:
        # Somente para desenvolvimento local.
        return "dev-apenas-local"

    raise RuntimeError(
        "Defina a variável de ambiente SECRET_KEY "
        "(use um valor longo e aleatório)."
    )


class Config:
    SECRET_KEY = _obter_secret_key()
    DEBUG = _DEBUG
    HOST = os.getenv("HOST", "127.0.0.1")
    PORT = int(os.getenv("PORT", "5000"))
