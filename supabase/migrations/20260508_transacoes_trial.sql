-- =============================================================
-- Migration: Substituir trial por tempo (7 dias) por
--            trial por transações (10 usos)
-- Data: 2026-05-08
-- =============================================================

-- 1. Adicionar coluna transacoes_trial à tabela usuarios
ALTER TABLE usuarios
  ADD COLUMN IF NOT EXISTS transacoes_trial INT NOT NULL DEFAULT 0;

-- 2. Recriar a view acesso_status com todos os campos necessários
--    Usa trial_inicio como criado_em (data_criacao não existe na tabela)
CREATE OR REPLACE VIEW acesso_status AS
SELECT
  u.id,
  u.email,
  u.nome,
  u.avatar_url,
  u.tipo_acesso,
  u.trial_inicio,
  u.trial_fim,
  u.acesso_anual_fim,
  u.cupom_afiliado,
  u.ultimo_acesso,
  u.trial_inicio                    AS criado_em,
  COALESCE(u.transacoes_trial, 0)   AS transacoes_trial,
  CASE
    WHEN u.tipo_acesso = 'admin'
      THEN 'admin'
    WHEN u.tipo_acesso = 'anual' AND u.acesso_anual_fim > now()
      THEN 'ativo'
    WHEN u.tipo_acesso = 'trial' AND COALESCE(u.transacoes_trial, 0) < 10
      THEN 'trial'
    ELSE 'bloqueado'
  END AS status
FROM usuarios u;
