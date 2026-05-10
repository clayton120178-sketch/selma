-- =============================================================
-- Migration: RLS admin — painel de controle e view acesso_status
-- Data: 2026-05-10
-- Problema: polícia usuario_ve_proprio restringia o admin a ver
--           apenas o próprio registro, tornando o dashboard vazio.
-- =============================================================

-- 1. Função SECURITY DEFINER para checar admin sem recursão de RLS
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM usuarios
    WHERE id = auth.uid() AND tipo_acesso = 'admin'
  );
$$;

-- 2. Política: admin pode ler todos os registros de usuarios
CREATE POLICY "admin_select_all_usuarios" ON usuarios
  FOR SELECT
  USING (is_admin() OR auth.uid() = id);

-- 3. Recriar a view acesso_status incluindo acesso_anual_inicio
--    (coluna existia na tabela mas estava ausente da view)
CREATE OR REPLACE VIEW acesso_status AS
SELECT
  id,
  email,
  nome,
  avatar_url,
  tipo_acesso,
  plano,
  trial_inicio,
  trial_fim,
  acesso_anual_fim,
  cupom_afiliado,
  ultimo_acesso,
  trial_inicio AS criado_em,
  COALESCE(transacoes_trial, 0) AS transacoes_trial,
  CASE
    WHEN tipo_acesso = 'admin'   THEN 'admin'
    WHEN tipo_acesso = 'anual'   AND acesso_anual_fim > now() THEN 'ativo'
    WHEN tipo_acesso = 'trial'   AND COALESCE(transacoes_trial, 0) < 10 THEN 'trial'
    ELSE 'bloqueado'
  END AS status,
  acesso_anual_inicio
FROM usuarios u;
