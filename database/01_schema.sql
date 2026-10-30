-- ============================================================
-- MINHA LOJA - 01_schema.sql
-- Esquema do banco, compatível com TiDB Cloud (e MySQL 8).
-- Execute MANUALMENTE no SQL Editor do TiDB Cloud, em ordem:
--   01_schema.sql -> 02_seed.sql -> 03_verificacao.sql
-- Este arquivo não contém senhas nem dados de nenhuma loja.
-- ============================================================

CREATE DATABASE IF NOT EXISTS minha_loja
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE minha_loja;

-- ------------------------------------------------------------
-- Cardápio
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categorias (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nome        VARCHAR(60)  NOT NULL,
  descricao   VARCHAR(200) NULL,
  imagem_url  VARCHAR(255) NULL,
  ordem       INT          NOT NULL DEFAULT 0,
  ativo       TINYINT(1)   NOT NULL DEFAULT 1,
  criado_em   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_categorias_nome (nome),
  KEY idx_categorias_ativo_ordem (ativo, ordem)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS produtos (
  id                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
  categoria_id       INT UNSIGNED NOT NULL,
  nome               VARCHAR(100) NOT NULL,
  descricao          VARCHAR(300) NULL,
  preco              DECIMAL(10,2) NOT NULL,
  preco_promocional  DECIMAL(10,2) NULL,
  imagem_url         VARCHAR(255) NULL,
  disponivel         TINYINT(1)   NOT NULL DEFAULT 1,
  destaque           TINYINT(1)   NOT NULL DEFAULT 0,
  tempo_preparo_min  SMALLINT UNSIGNED NULL,
  ativo              TINYINT(1)   NOT NULL DEFAULT 1,
  criado_em          TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_produtos_categoria (categoria_id),
  KEY idx_produtos_ativo (ativo, disponivel),
  CONSTRAINT fk_produtos_categoria
    FOREIGN KEY (categoria_id) REFERENCES categorias (id),
  CONSTRAINT ck_produtos_preco CHECK (preco >= 0),
  CONSTRAINT ck_produtos_promo CHECK (preco_promocional IS NULL OR preco_promocional >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS grupos_opcoes (
  id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nome    VARCHAR(100) NOT NULL,
  minimo  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  maximo  SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  ativo   TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS opcoes (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  grupo_id         INT UNSIGNED NOT NULL,
  nome             VARCHAR(100) NOT NULL,
  preco_adicional  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  disponivel       TINYINT(1) NOT NULL DEFAULT 1,
  ordem            INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_opcoes_grupo (grupo_id, ordem),
  CONSTRAINT fk_opcoes_grupo
    FOREIGN KEY (grupo_id) REFERENCES grupos_opcoes (id) ON DELETE CASCADE,
  CONSTRAINT ck_opcoes_preco CHECK (preco_adicional >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS produto_grupos_opcoes (
  produto_id  INT UNSIGNED NOT NULL,
  grupo_id    INT UNSIGNED NOT NULL,
  ordem       INT NOT NULL DEFAULT 0,
  PRIMARY KEY (produto_id, grupo_id),
  KEY idx_pgo_grupo (grupo_id),
  CONSTRAINT fk_pgo_produto
    FOREIGN KEY (produto_id) REFERENCES produtos (id) ON DELETE CASCADE,
  CONSTRAINT fk_pgo_grupo
    FOREIGN KEY (grupo_id) REFERENCES grupos_opcoes (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Cupons
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cupons (
  id                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo              VARCHAR(30)  NOT NULL,
  tipo                VARCHAR(20)  NOT NULL,           -- percentual | valor_fixo
  valor               DECIMAL(10,2) NOT NULL,
  pedido_minimo       DECIMAL(10,2) NULL,
  inicio_em           DATETIME NULL,
  fim_em              DATETIME NULL,
  limite_total        INT UNSIGNED NULL,
  limite_por_cliente  INT UNSIGNED NULL,
  ativo               TINYINT(1) NOT NULL DEFAULT 1,
  criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_cupons_codigo (codigo),
  CONSTRAINT ck_cupons_tipo CHECK (tipo IN ('percentual', 'valor_fixo')),
  CONSTRAINT ck_cupons_valor CHECK (valor > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Pedidos
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pedidos (
  id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  numero              VARCHAR(30)  NOT NULL,
  chave_idempotencia  VARCHAR(100) NULL,
  cupom_id            INT UNSIGNED NULL,
  nome_cliente        VARCHAR(120) NOT NULL,
  telefone_cliente    VARCHAR(20)  NOT NULL,
  email_cliente       VARCHAR(254) NULL,
  modalidade          VARCHAR(10)  NOT NULL,           -- entrega | retirada
  entrega_cep         VARCHAR(8)   NULL,
  entrega_rua         VARCHAR(150) NULL,
  entrega_numero      VARCHAR(15)  NULL,
  entrega_complemento VARCHAR(80)  NULL,
  entrega_bairro      VARCHAR(80)  NULL,
  entrega_cidade      VARCHAR(80)  NULL,
  entrega_uf          CHAR(2)      NULL,
  entrega_referencia  VARCHAR(150) NULL,
  status              VARCHAR(20)  NOT NULL DEFAULT 'recebido',
  subtotal            DECIMAL(10,2) NOT NULL,
  taxa_entrega        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  desconto            DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  total               DECIMAL(10,2) NOT NULL,
  observacoes         VARCHAR(300) NULL,
  criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_pedidos_numero (numero),
  UNIQUE KEY uq_pedidos_idempotencia (chave_idempotencia),
  KEY idx_pedidos_status_criado (status, criado_em),
  KEY idx_pedidos_criado (criado_em),
  KEY idx_pedidos_telefone (telefone_cliente),
  KEY idx_pedidos_cupom (cupom_id),
  CONSTRAINT fk_pedidos_cupom
    FOREIGN KEY (cupom_id) REFERENCES cupons (id),
  CONSTRAINT ck_pedidos_modalidade CHECK (modalidade IN ('entrega', 'retirada')),
  CONSTRAINT ck_pedidos_status CHECK (status IN
    ('recebido','confirmado','em_preparo','pronto_retirada','saiu_entrega','entregue','cancelado')),
  CONSTRAINT ck_pedidos_valores CHECK
    (subtotal >= 0 AND taxa_entrega >= 0 AND desconto >= 0 AND total >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS itens_pedido (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pedido_id       BIGINT UNSIGNED NOT NULL,
  produto_id      INT UNSIGNED NOT NULL,
  nome_produto    VARCHAR(100) NOT NULL,
  preco_unitario  DECIMAL(10,2) NOT NULL,
  quantidade      SMALLINT UNSIGNED NOT NULL,
  observacao      VARCHAR(140) NULL,
  subtotal        DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (id),
  KEY idx_itens_pedido (pedido_id),
  KEY idx_itens_produto (produto_id),
  CONSTRAINT fk_itens_pedido
    FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE CASCADE,
  CONSTRAINT fk_itens_produto
    FOREIGN KEY (produto_id) REFERENCES produtos (id),
  CONSTRAINT ck_itens_qtd CHECK (quantidade >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS itens_pedido_opcoes (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  item_pedido_id   BIGINT UNSIGNED NOT NULL,
  opcao_id         INT UNSIGNED NULL,
  nome_grupo       VARCHAR(100) NOT NULL,
  nome_opcao       VARCHAR(100) NOT NULL,
  preco_adicional  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (id),
  KEY idx_ipo_item (item_pedido_id),
  KEY idx_ipo_opcao (opcao_id),
  CONSTRAINT fk_ipo_item
    FOREIGN KEY (item_pedido_id) REFERENCES itens_pedido (id) ON DELETE CASCADE,
  CONSTRAINT fk_ipo_opcao
    FOREIGN KEY (opcao_id) REFERENCES opcoes (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pagamentos (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pedido_id   BIGINT UNSIGNED NOT NULL,
  forma       VARCHAR(20)  NOT NULL,                   -- pix | dinheiro | cartao_entrega
  valor       DECIMAL(10,2) NOT NULL,
  troco_para  DECIMAL(10,2) NULL,
  status      VARCHAR(20)  NOT NULL DEFAULT 'pendente', -- pendente | pago
  pago_em     DATETIME NULL,
  PRIMARY KEY (id),
  KEY idx_pagamentos_pedido (pedido_id),
  KEY idx_pagamentos_status_pago (status, pago_em),
  CONSTRAINT fk_pagamentos_pedido
    FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE CASCADE,
  CONSTRAINT ck_pagamentos_forma CHECK (forma IN ('pix', 'dinheiro', 'cartao_entrega'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS historico_status_pedido (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pedido_id        BIGINT UNSIGNED NOT NULL,
  status_anterior  VARCHAR(20) NULL,
  status_novo      VARCHAR(20) NOT NULL,
  criado_em        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_hist_pedido (pedido_id, criado_em),
  CONSTRAINT fk_hist_pedido
    FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cupom_usos (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cupom_id        INT UNSIGNED NOT NULL,
  pedido_id       BIGINT UNSIGNED NOT NULL,
  usuario_id      INT UNSIGNED NULL,                    -- reservado; o app grava NULL
  valor_desconto  DECIMAL(10,2) NOT NULL,
  criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_cupom_usos_cupom (cupom_id),
  KEY idx_cupom_usos_pedido (pedido_id),
  CONSTRAINT fk_cupom_usos_cupom
    FOREIGN KEY (cupom_id) REFERENCES cupons (id),
  CONSTRAINT fk_cupom_usos_pedido
    FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Entrega e configurações
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS regioes_entrega (
  id                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  bairro              VARCHAR(80) NOT NULL,
  cidade              VARCHAR(80) NOT NULL,
  taxa                DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  prazo_estimado_min  SMALLINT UNSIGNED NULL,
  ativo               TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_regioes_cidade_bairro (cidade, bairro),
  CONSTRAINT ck_regioes_taxa CHECK (taxa >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS configuracoes_loja (
  chave  VARCHAR(80)  NOT NULL,
  valor  VARCHAR(500) NOT NULL,
  PRIMARY KEY (chave)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
