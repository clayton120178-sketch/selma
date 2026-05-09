-- =============================================================
-- Migration: Dois planos — Anotações (R$97) e Completo (R$117)
-- Data: 2026-05-09
-- =============================================================

-- 1. Adicionar coluna plano à tabela usuarios
--    Valores: NULL (legado) | 'anotacoes' | 'completo'
--    Usuários legados (tipo_acesso = 'anual' sem plano) são tratados como 'anotacoes' no app
ALTER TABLE usuarios
  ADD COLUMN IF NOT EXISTS plano VARCHAR(20) DEFAULT NULL;

-- 2. Recriar a view acesso_status expondo o campo plano
--    DROP necessário porque CREATE OR REPLACE não permite inserir coluna no meio da lista
DROP VIEW IF EXISTS acesso_status;
CREATE VIEW acesso_status AS
SELECT
  u.id,
  u.email,
  u.nome,
  u.avatar_url,
  u.tipo_acesso,
  u.plano,
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
