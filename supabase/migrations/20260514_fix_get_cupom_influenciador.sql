-- Fix: get_cupom_influenciador causava hang no contexto de RLS
-- Problema: SELECT direto em auth.users pode causar timeout em SECURITY DEFINER
-- Solução: usar auth.email() (helper nativo Supabase) + marcar como STABLE
CREATE OR REPLACE FUNCTION get_cupom_influenciador()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT cupom FROM influenciadores
  WHERE email = auth.email()
    AND ativo = true
  LIMIT 1;
$$;
