"""Testes que NÃO precisam de banco de dados."""
import unittest

from tests import _ambiente  # noqa: F401  (define variáveis de ambiente)
from app import create_app


class TestPaginasEApi(unittest.TestCase):
    def setUp(self):
        self.client = create_app().test_client()

    def test_home_abre_com_nome_neutro(self):
        r = self.client.get("/")
        self.assertEqual(r.status_code, 200)
        self.assertIn(b"Minha Loja", r.data)
        self.assertNotIn(b"SAL" + b"TY", r.data.upper())

    def test_admin_html_abre(self):
        r = self.client.get("/admin.html")
        self.assertEqual(r.status_code, 200)
        self.assertIn(b"Minha Loja", r.data)

    def test_arquivos_estaticos(self):
        for caminho in ("/css/style.css", "/js/app.js", "/js/api.js",
                        "/js/cart.js", "/js/admin.js", "/css/admin.css"):
            self.assertEqual(self.client.get(caminho).status_code, 200, caminho)

    def test_rota_inexistente_retorna_json_404(self):
        r = self.client.get("/api/nao-existe")
        self.assertEqual(r.status_code, 404)
        self.assertIn("error", r.get_json())

    def test_nao_expoe_arquivos_fora_de_public(self):
        for caminho in ("/../app.py", "/..%2fapp.py", "/.env", "/database/01_schema.sql"):
            self.assertEqual(self.client.get(caminho).status_code, 404, caminho)


class TestAdminAutenticacao(unittest.TestCase):
    def setUp(self):
        self.client = create_app().test_client()

    def test_rotas_admin_exigem_login(self):
        for caminho in ("/api/admin/pedidos", "/api/admin/produtos",
                        "/api/admin/categorias", "/api/admin/cupons",
                        "/api/admin/regioes-entrega", "/api/admin/clientes",
                        "/api/admin/configuracoes", "/api/admin/faturamento"):
            r = self.client.get(caminho)
            self.assertEqual(r.status_code, 401, caminho)

    def test_senha_errada(self):
        r = self.client.post("/api/admin/login", json={"senha": "errada"})
        self.assertEqual(r.status_code, 401)

    def test_senha_ausente(self):
        r = self.client.post("/api/admin/login", json={})
        self.assertEqual(r.status_code, 401)

    def test_senha_nao_texto(self):
        r = self.client.post("/api/admin/login", json={"senha": 123})
        self.assertEqual(r.status_code, 401)

    def test_login_logout_e_sessao(self):
        self.assertFalse(self.client.get("/api/admin/sessao").get_json()["autenticado"])
        r = self.client.post("/api/admin/login", json={"senha": "senha-de-teste"})
        self.assertEqual(r.status_code, 200)
        self.assertTrue(self.client.get("/api/admin/sessao").get_json()["autenticado"])
        self.client.post("/api/admin/logout")
        self.assertFalse(self.client.get("/api/admin/sessao").get_json()["autenticado"])


class TestValidacaoDePedido(unittest.TestCase):
    """Validações que acontecem antes de qualquer acesso ao banco."""

    def setUp(self):
        self.client = create_app().test_client()

    def test_pedido_vazio(self):
        r = self.client.post("/api/orders", json={})
        self.assertEqual(r.status_code, 400)

    def test_modalidade_invalida(self):
        r = self.client.post("/api/orders", json={
            "nome": "Fulano de Tal", "telefone": "11999999999",
            "modalidade": "teletransporte", "pagamento": "dinheiro",
            "itens": [{"produto_id": 1, "quantidade": 1}],
        })
        self.assertEqual(r.status_code, 400)

    def test_pagamento_invalido(self):
        r = self.client.post("/api/orders", json={
            "nome": "Fulano de Tal", "telefone": "11999999999",
            "modalidade": "retirada", "pagamento": "cheque",
            "itens": [{"produto_id": 1, "quantidade": 1}],
        })
        self.assertEqual(r.status_code, 400)


class TestRegrasDePreco(unittest.TestCase):
    def test_desconto_percentual_e_fixo(self):
        from decimal import Decimal
        from backend.routes.orders import calcular_desconto_cupom, normalizar_telefone

        self.assertEqual(
            calcular_desconto_cupom({"tipo": "percentual", "valor": 10}, Decimal("50.00")),
            Decimal("5.00"))
        self.assertEqual(
            calcular_desconto_cupom({"tipo": "valor_fixo", "valor": 8}, Decimal("50.00")),
            Decimal("8.00"))
        # O desconto nunca passa do subtotal.
        self.assertEqual(
            calcular_desconto_cupom({"tipo": "valor_fixo", "valor": 80}, Decimal("50.00")),
            Decimal("50.00"))
        with self.assertRaises(ValueError):
            calcular_desconto_cupom({"tipo": "percentual", "valor": 150}, Decimal("50.00"))
        with self.assertRaises(ValueError):
            calcular_desconto_cupom({"tipo": "outro", "valor": 5}, Decimal("50.00"))
        self.assertEqual(normalizar_telefone("(11) 99999-9999"), "11999999999")


if __name__ == "__main__":
    unittest.main()
