"""Consistência do projeto: SQL x esquema, frontend x backend, marca e segredos."""
import re
import unittest
from pathlib import Path

from tests import _ambiente  # noqa: F401

RAIZ = Path(__file__).resolve().parent.parent
SQL = (RAIZ / "database" / "01_schema.sql").read_text(encoding="utf-8")
ARQUIVOS_PY = [
    *(RAIZ / "backend").rglob("*.py"),
    RAIZ / "popular_banco.py",
]


def ler_esquema():
    tabelas = {}
    for m in re.finditer(r"CREATE TABLE IF NOT EXISTS (\w+) \((.*?)\n\) ENGINE", SQL, re.S):
        colunas = set()
        for linha in m.group(2).splitlines():
            c = re.match(r"\s{2}([a-z_]+)\s+[A-Z]", linha)
            if c and c.group(1) not in ("PRIMARY", "UNIQUE", "KEY", "CONSTRAINT"):
                colunas.add(c.group(1))
        tabelas[m.group(1)] = colunas
    return tabelas


ESQUEMA = ler_esquema()


class TestEsquemaSql(unittest.TestCase):
    def test_14_tabelas(self):
        self.assertEqual(len(ESQUEMA), 14, sorted(ESQUEMA))

    def test_tabelas_usadas_no_codigo_existem(self):
        usadas = set()
        for arq in ARQUIVOS_PY:
            texto = arq.read_text(encoding="utf-8")
            usadas |= set(re.findall(
                r"(?:FROM|JOIN|INTO|UPDATE)\s+([a-z_]+)\b", texto))
        usadas = {t for t in usadas if t in ESQUEMA or t.endswith(("s", "_loja", "_pedido"))}
        ignorar = {"information_schema"}
        faltando = {t for t in usadas if t not in ESQUEMA} - ignorar
        # palavras comuns capturadas fora de SQL
        faltando -= {"is", "this", "as", "dados", "values", "tabelas", "pedidos_do"}
        self.assertEqual(faltando, set())

    def test_colunas_de_insert_existem(self):
        erros = []
        for arq in ARQUIVOS_PY:
            texto = arq.read_text(encoding="utf-8")
            for m in re.finditer(r"INSERT\s+(?:IGNORE\s+)?INTO\s+(\w+)\s*\(([^)]*)\)", texto, re.S):
                tabela = m.group(1)
                for col in re.findall(r"[a-z_]+", m.group(2)):
                    if col not in ESQUEMA.get(tabela, set()):
                        erros.append(f"{arq.name}: {tabela}.{col}")
        self.assertEqual(erros, [])

    def test_colunas_de_update_existem(self):
        erros = []
        for arq in ARQUIVOS_PY:
            texto = arq.read_text(encoding="utf-8")
            for m in re.finditer(r"UPDATE\s+(\w+)\s+SET\s+(.*?)(?:WHERE|\"\"\")", texto, re.S | re.I):
                tabela = m.group(1)
                if tabela not in ESQUEMA:
                    continue
                for col in re.findall(r"\b([a-z_]+)\s*=", m.group(2)):
                    if col not in ESQUEMA[tabela]:
                        erros.append(f"{arq.name}: {tabela}.{col}")
        self.assertEqual(erros, [])

    def test_chaves_de_configuracao_no_seed(self):
        seed = (RAIZ / "database" / "02_seed.sql").read_text(encoding="utf-8")
        for chave in ("nome_loja", "taxa_entrega_padrao", "pedido_minimo",
                      "formas_pagamento", "aceita_pedido_fechada", "loja_modo"):
            self.assertIn(f"'{chave}'", seed)

    def test_sql_sem_credenciais(self):
        for arq in (RAIZ / "database").glob("*.sql"):
            texto = arq.read_text(encoding="utf-8").lower()
            self.assertNotRegex(texto, r"identified by|password\s*=|create user")


class TestFrontendBackend(unittest.TestCase):
    def setUp(self):
        from app import create_app
        regras = [str(r) for r in create_app().url_map.iter_rules()]
        self.padroes = [re.compile("^" + re.sub(r"<[^>]+>", r"[^/]+", r) + "$") for r in regras]

    def existe(self, caminho):
        caminho = re.sub(r"\$\{[^}]+\}", "1", caminho.split("?")[0])
        return any(p.match(caminho) for p in self.padroes)

    def test_endpoints_do_cliente(self):
        js = (RAIZ / "public/js/api.js").read_text(encoding="utf-8")
        caminhos = re.findall(r"(?:get|post)\(\s*[`\"'](/[^`\"']+)", js)
        self.assertGreaterEqual(len(caminhos), 6)
        for c in caminhos:
            self.assertTrue(self.existe("/api" + c), c)

    def test_endpoints_do_admin(self):
        js = (RAIZ / "public/js/admin.js").read_text(encoding="utf-8")
        caminhos = set(re.findall(r"requisicao\(\s*[`\"'](/[^`\"']+)", js))
        self.assertGreaterEqual(len(caminhos), 20)
        for c in caminhos:
            self.assertTrue(self.existe("/api/admin" + c), c)


class TestMarcaESegredos(unittest.TestCase):
    EXT = {".py", ".js", ".html", ".css", ".md", ".sql", ".json", ".txt", ".example"}

    def arquivos(self):
        for p in RAIZ.rglob("*"):
            if p.is_file() and p.suffix in self.EXT | {""} and not any(
                    x in p.parts for x in (".git", ".venv", "venv", "__pycache__")):
                yield p

    def test_sem_referencias_a_marca_original(self):
        achados = []
        for p in self.arquivos():
            if p.name in ("test_projeto.py", "test_app.py"):
                continue
            try:
                if re.search(r"salty", p.read_text(encoding="utf-8"), re.I):
                    achados.append(str(p.relative_to(RAIZ)))
            except UnicodeDecodeError:
                pass
        self.assertEqual(achados, [])

    def test_sem_mojibake(self):
        for p in self.arquivos():
            if p.suffix in (".py", ".js", ".html", ".css", ".md", ".sql") and p.name != "test_projeto.py":
                self.assertNotRegex(p.read_text(encoding="utf-8"), r"Ã[§£¡©³ª]|Ãƒ", p.name)

    def test_env_protegido(self):
        gi = (RAIZ / ".gitignore").read_text(encoding="utf-8").splitlines()
        self.assertIn(".env", gi)
        self.assertFalse((RAIZ / ".env").exists())

    def test_env_example_sem_valores_secretos(self):
        for linha in (RAIZ / ".env.example").read_text(encoding="utf-8").splitlines():
            if "=" in linha and not linha.startswith("#"):
                chave, valor = linha.split("=", 1)
                if chave in ("SECRET_KEY", "ADMIN_PASSWORD", "DB_HOST", "DB_USER", "DB_PASSWORD",
                             "CLOUDINARY_CLOUD_NAME", "CLOUDINARY_API_KEY", "CLOUDINARY_API_SECRET"):
                    self.assertEqual(valor.strip(), "", chave)

    def test_sem_senha_fixa_no_codigo(self):
        for arq in ARQUIVOS_PY + [RAIZ / "app.py"]:
            texto = arq.read_text(encoding="utf-8")
            self.assertNotRegex(texto, r"(?i)(password|senha_correta|secret_key)\s*=\s*[\"'][^\"']+[\"']", arq.name) \
                if arq.name not in ("config.py",) else None

    def test_vercel_json(self):
        import json
        dados = json.loads((RAIZ / "vercel.json").read_text(encoding="utf-8"))
        self.assertEqual(dados["builds"][0]["src"], "app.py")


if __name__ == "__main__":
    unittest.main()
