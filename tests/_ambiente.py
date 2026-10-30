"""Variáveis de ambiente fictícias usadas somente nos testes."""
import os

os.environ.setdefault("SECRET_KEY", "chave-de-teste-nao-usar-em-producao")
os.environ["ADMIN_PASSWORD"] = "senha-de-teste"
os.environ.setdefault("FLASK_DEBUG", "0")
