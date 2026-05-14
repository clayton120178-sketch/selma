-- =============================================================
-- Migration: Portal do Influenciador
-- Data: 2026-05-14
-- Mudanças:
--   1. Adiciona campo email à tabela influenciadores
--   2. Cria função is_influenciador() com SECURITY DEFINER
--   3. Cria política RLS para influenciadores lerem apenas
--      os usuários vinculados ao seu cupom
-- =============================================================

-- 1. Adicionar coluna email à tabela influenciadores
ALTER TABLE influenciadores
  ADD COLUMN IF NOT EXISTS email TEXT DEFAULT NULL;

-- Criar índice único para garantir unicidade do email (opcional mas recomendado)
CREATE UNIQUE INDEX IF NOT EXISTS influenciadores_email_unique
  ON influenciadores (email)
  WHERE email IS NOT NULL;

-- 2. Função SECURITY DEFINER para verificar se o usuário logado é influenciador ativo
--    Retorna o cupom do influenciador, ou NULL se não for influenciador
CREATE OR REPLACE FUNCTION get_cupom_influenciador()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT cupom FROM influenciadores
  WHERE email = (SELECT email FROM auth.users WHERE id = auth.uid())
    AND ativo = true
  LIMIT 1;
$$;

-- 3. Política RLS: influenciador lê apenas usuários com o seu cupom
--    A tabela usuarios já tem RLS habilitado.
--    Adicionamos uma nova política sem remover as existentes.
CREATE POLICY "influenciador_ve_seus_usuarios" ON usuarios
  FOR SELECT
  USING (
    cupom_afiliado IS NOT NULL
    AND cupom_afiliado = get_cupom_influenciador()
  );
