-- ============================================================
-- MINHA LOJA - 04_demo_opcional.sql   (OPCIONAL - só desenvolvimento)
-- Dados totalmente FICTÍCIOS para testar o cardápio e o carrinho.
-- NÃO execute em produção. Para remover: apague pelo painel admin ou
-- recrie o banco. Só roda com as tabelas de cardápio vazias.
-- ============================================================

USE minha_loja;

INSERT INTO categorias (id, nome, descricao, ordem, ativo) VALUES
  (1, 'Categoria Exemplo 1', NULL, 1, 1),
  (2, 'Categoria Exemplo 2', NULL, 2, 1),
  (3, 'Categoria Exemplo 3', NULL, 3, 1);

INSERT INTO produtos (id, categoria_id, nome, descricao, preco, disponivel, destaque, tempo_preparo_min, ativo) VALUES
  (101, 1, 'Produto Exemplo 1', 'Descrição fictícia do produto de exemplo.', 10.00, 1, 1, 15, 1),
  (102, 1, 'Produto Exemplo 2', 'Descrição fictícia do produto de exemplo.', 12.00, 1, 0, 15, 1),
  (201, 2, 'Produto Exemplo 3', 'Descrição fictícia do produto de exemplo.',  8.00, 1, 0, 10, 1),
  (202, 2, 'Produto Exemplo 4 (indisponível)', 'Exemplo de produto marcado como indisponível.', 9.00, 0, 0, 10, 1),
  (301, 3, 'Produto Exemplo 5', 'Descrição fictícia do produto de exemplo.',  5.00, 1, 0, NULL, 1);

INSERT INTO grupos_opcoes (id, nome, minimo, maximo, ativo) VALUES
  (1, 'Tamanho',    1, 1, 1),
  (2, 'Adicionais', 0, 2, 1);

INSERT INTO opcoes (grupo_id, nome, preco_adicional, disponivel, ordem) VALUES
  (1, 'Pequeno', 0.00, 1, 1),
  (1, 'Grande',  5.00, 1, 2),
  (2, 'Adicional exemplo A', 2.00, 1, 1),
  (2, 'Adicional exemplo B', 3.00, 1, 2);

INSERT INTO produto_grupos_opcoes (produto_id, grupo_id, ordem) VALUES
  (101, 1, 1), (101, 2, 2),
  (102, 1, 1),
  (301, 2, 1);

-- Região de entrega fictícia para testar o checkout.
INSERT INTO regioes_entrega (bairro, cidade, taxa, prazo_estimado_min, ativo) VALUES
  ('Bairro Exemplo', 'Cidade Exemplo', 5.00, 40, 1);
