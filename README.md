# Minha Loja

Sistema de pedidos online (cardápio, carrinho, checkout, entrega/retirada, cupons e painel
administrativo). Backend **Flask**, frontend em **HTML/CSS/JavaScript puro** (pasta `public/`,
servida pelo próprio Flask) e banco **MySQL/TiDB**.

> Este projeto é independente: tem banco, credenciais e implantação próprios.

## Estrutura

| Pasta/arquivo | O que é |
|---|---|
| `app.py` | Ponto de entrada (Flask serve a API e o frontend) |
| `backend/` | Rotas (`routes/`), regras (`services/`), consultas (`repositories/`), conexão (`database.py`) |
| `public/` | Frontend do cliente (`index.html`) e painel (`admin.html`) |
| `database/` | Scripts SQL para o TiDB Cloud (executar **manualmente**) |
| `popular_banco.py` | Opcional: carrega dados de demonstração fictícios (só desenvolvimento) |
| `tests/` | Testes automatizados |
| `vercel.json` | Configuração de implantação na Vercel |

## 1. Banco de dados no TiDB Cloud (manual)

1. No TiDB Cloud, crie um cluster e anote host, porta (4000), usuário e senha.
2. Abra o **SQL Editor** e execute, nesta ordem, colando o conteúdo de cada arquivo:
   1. `database/01_schema.sql` — cria o banco `minha_loja` e as 14 tabelas;
   2. `database/02_seed.sql` — configurações iniciais neutras (sem produtos);
   3. `database/03_verificacao.sql` — confere tabelas, configurações e chaves estrangeiras.
3. (Só para testes) `database/04_demo_opcional.sql` insere um cardápio **fictício**. Não use em produção.

**Chaves estrangeiras:** o app foi escrito para um banco com FKs (erro 1451 ao excluir itens
vinculados). Versões recentes do TiDB suportam FKs; confira o resultado de
`SHOW VARIABLES LIKE 'tidb_enable_foreign_key'` no `03_verificacao.sql`. Se estiver `OFF`,
ative com `SET GLOBAL tidb_enable_foreign_key = ON;` (se o seu plano permitir). Mesmo sem FKs,
o app impede por conta própria excluir produtos já vendidos e categorias com produtos.

**TLS:** o TiDB Cloud exige conexão segura. Use `DB_SSL=true` (o app usa os certificados do
pacote `certifi`; opcionalmente aponte `DB_SSL_CA` para um arquivo `.pem`).

## 2. Variáveis de ambiente

Copie `.env.example` para `.env` (nunca vai para o Git) e preencha:

| Variável | Para que serve |
|---|---|
| `SECRET_KEY` | Assina a sessão do admin. Obrigatória fora do modo debug. Gere com `python -c "import secrets; print(secrets.token_hex(32))"` |
| `ADMIN_PASSWORD` | Senha do painel administrativo (não existe senha fixa no código) |
| `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` | Conexão com o TiDB (`DB_PORT=4000`, `DB_NAME=minha_loja`) |
| `DB_SSL`, `DB_SSL_CA` | TLS (`true` para TiDB Cloud) |
| `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` | Upload de imagens de produtos (conta **sua**; sem isso o upload não funciona, o resto sim) |
| `FLASK_DEBUG` | `1` só no computador local (liga o debug e permite cookie sem HTTPS) |

## 3. Rodar localmente

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1          # Linux/macOS: source .venv/bin/activate
pip install -r requirements.txt
copy .env.example .env                 # preencha o .env (FLASK_DEBUG=1 para local)
python app.py
```

Abra http://127.0.0.1:5000 (cardápio) e http://127.0.0.1:5000/admin.html (painel).

## 4. Testes

```powershell
python -m unittest discover -s tests -t . -v
```

Os testes não precisam de banco. Eles conferem rotas, autenticação do admin, regras de
desconto, **consistência entre o SQL e o código**, endpoints do frontend e proteção de segredos.
Fluxos que gravam no banco (criar pedido de ponta a ponta) precisam ser testados manualmente
depois de configurar o TiDB.

## 5. Implantação na Vercel (independente)

1. Crie o repositório **novo** (`git init` nesta pasta) e envie para a sua conta.
2. Na Vercel: *Add New → Project*, importe o repositório. O `vercel.json` já aponta para `app.py`.
3. Em *Settings → Environment Variables*, cadastre todas as variáveis da seção 2
   (`FLASK_DEBUG=0`, `SECRET_KEY`, `ADMIN_PASSWORD`, `DB_*`, `DB_SSL=true`, `CLOUDINARY_*`).
4. Faça o deploy. Em caso de erro, veja *Deployments → (deploy) → Logs / Runtime Logs*.
5. Em *Settings → Domains* configure o domínio, se houver.

## 6. Configurar a loja

* **Nome da loja:** `configuracoes_loja.nome_loja` (aparece no cardápio, no admin e no comprovante).
  Para alterar: `UPDATE configuracoes_loja SET valor = 'Nome da Sua Loja' WHERE chave = 'nome_loja';`
* **Taxa de entrega padrão, horários e abertura manual:** pelo painel administrativo.
* **Pedido mínimo, formas de pagamento e aceitar pedido com a loja fechada:** chaves
  `pedido_minimo`, `formas_pagamento` (lista JSON) e `aceita_pedido_fechada` em `configuracoes_loja`
  (ainda não têm tela no painel).
* **Cidades e bairros de entrega:** painel → Regiões de entrega.

## Pontos conhecidos (herdados da base, preservados)

* A rota `GET /api/loja/status` (`loja_publica_bp` em `funcionamento.py`) existe, mas não está
  registrada no `app.py` e o frontend não a utiliza.
* Grupos de opções/adicionais não têm cadastro no painel: são criados direto no banco.
* O pagamento Pix é marcado como pago manualmente no painel (não há integração com gateway).
