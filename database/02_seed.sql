-- ============================================================
-- MINHA LOJA - 02_seed.sql
-- Dados iniciais MÍNIMOS e NEUTROS para o sistema funcionar.
-- Não contém produtos, clientes, pedidos nem dados comerciais.
-- Pode ser executado mais de uma vez (INSERT IGNORE não duplica).
-- Execute depois do 01_schema.sql.
-- ============================================================

USE minha_loja;

INSERT IGNORE INTO configuracoes_loja (chave, valor) VALUES
  ('nome_loja',            'Minha Loja'),
  ('taxa_entrega_padrao',  '0.00'),
  ('pedido_minimo',        '0.00'),
  ('formas_pagamento',     '["pix","dinheiro","cartao_entrega"]'),
  ('aceita_pedido_fechada','false'),
  ('loja_modo',            'automatico');

-- Horários de funcionamento (horario_0 = segunda ... horario_6 = domingo)
-- não são cadastrados aqui: enquanto não houver horários configurados no
-- painel administrativo, a loja não bloqueia pedidos.
