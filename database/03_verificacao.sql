-- ============================================================
-- MINHA LOJA - 03_verificacao.sql
-- Consultas para conferir se o banco foi criado corretamente.
-- Somente leitura. Execute depois do 01 e do 02.
-- ============================================================

USE minha_loja;

-- 1) As 14 tabelas esperadas devem aparecer (esperado: 14 linhas).
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'minha_loja'
  AND table_name IN (
    'categorias','produtos','grupos_opcoes','opcoes','produto_grupos_opcoes',
    'cupons','pedidos','itens_pedido','itens_pedido_opcoes','pagamentos',
    'historico_status_pedido','cupom_usos','regioes_entrega','configuracoes_loja'
  )
ORDER BY table_name;

-- 2) Tabelas que FALTAM (esperado: nenhuma linha).
SELECT esperado.nome AS tabela_faltando
FROM (
  SELECT 'categorias' AS nome UNION ALL SELECT 'produtos'
  UNION ALL SELECT 'grupos_opcoes' UNION ALL SELECT 'opcoes'
  UNION ALL SELECT 'produto_grupos_opcoes' UNION ALL SELECT 'cupons'
  UNION ALL SELECT 'pedidos' UNION ALL SELECT 'itens_pedido'
  UNION ALL SELECT 'itens_pedido_opcoes' UNION ALL SELECT 'pagamentos'
  UNION ALL SELECT 'historico_status_pedido' UNION ALL SELECT 'cupom_usos'
  UNION ALL SELECT 'regioes_entrega' UNION ALL SELECT 'configuracoes_loja'
) AS esperado
LEFT JOIN information_schema.tables t
  ON t.table_schema = 'minha_loja' AND t.table_name = esperado.nome
WHERE t.table_name IS NULL;

-- 3) Configurações iniciais (esperado: 6 linhas).
SELECT chave, valor FROM configuracoes_loja ORDER BY chave;

-- 4) Chaves estrangeiras criadas (esperado: várias linhas).
SELECT table_name, constraint_name, referenced_table_name
FROM information_schema.key_column_usage
WHERE table_schema = 'minha_loja'
  AND referenced_table_name IS NOT NULL
ORDER BY table_name, constraint_name;

-- 5) Índices únicos importantes (pedidos.numero, cupons.codigo etc.).
SELECT table_name, index_name, GROUP_CONCAT(column_name ORDER BY seq_in_index) AS colunas
FROM information_schema.statistics
WHERE table_schema = 'minha_loja' AND non_unique = 0 AND index_name <> 'PRIMARY'
GROUP BY table_name, index_name
ORDER BY table_name;

-- 6) Contagens iniciais (esperado: tudo 0, exceto configuracoes_loja = 6).
SELECT 'categorias' AS tabela, COUNT(*) AS registros FROM categorias
UNION ALL SELECT 'produtos', COUNT(*) FROM produtos
UNION ALL SELECT 'pedidos', COUNT(*) FROM pedidos
UNION ALL SELECT 'cupons', COUNT(*) FROM cupons
UNION ALL SELECT 'regioes_entrega', COUNT(*) FROM regioes_entrega
UNION ALL SELECT 'configuracoes_loja', COUNT(*) FROM configuracoes_loja;

-- 7) Versão do servidor e suporte a chaves estrangeiras no TiDB
--    (o app usa FKs; se a variável abaixo retornar 0, veja o README).
SELECT VERSION() AS versao;
SHOW VARIABLES LIKE 'tidb_enable_foreign_key';
