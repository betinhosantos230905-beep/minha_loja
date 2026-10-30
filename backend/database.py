import os

import mysql.connector
from dotenv import load_dotenv

load_dotenv()


def _ativo(valor):
    return str(valor).strip().lower() in ("1", "true", "sim", "yes", "on")


def get_connection():
    """Abre uma conexão com o banco configurado nas variáveis de ambiente.

    Para o TiDB Cloud use DB_SSL=true (conexão segura/TLS obrigatória).
    Sem DB_SSL_CA, é usado o pacote de certificados do `certifi`.
    """
    opcoes = {
        "host": os.getenv("DB_HOST", "localhost"),
        "port": int(os.getenv("DB_PORT", "3306")),
        "user": os.getenv("DB_USER", "root"),
        "password": os.getenv("DB_PASSWORD", ""),
        "database": os.getenv("DB_NAME", "minha_loja"),
        "connection_timeout": int(os.getenv("DB_TIMEOUT", "10")),
    }

    if _ativo(os.getenv("DB_SSL", "false")):
        ca = os.getenv("DB_SSL_CA", "").strip()

        if not ca:
            import certifi

            ca = certifi.where()

        opcoes.update(
            ssl_disabled=False,
            ssl_ca=ca,
            ssl_verify_cert=True,
            ssl_verify_identity=True,
        )

    return mysql.connector.connect(**opcoes)
