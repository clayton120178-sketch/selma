-- Tabela de histórico de anotações
-- Armazena apenas metadados — o texto é regerado sob demanda
CREATE TABLE IF NOT EXISTS historico_anotacoes (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  ocorrencia_id INTEGER NOT NULL REFERENCES ocorrencias(id),
  contexto_id   INTEGER NOT NULL REFERENCES contextos(id),
  campos_valores JSONB NOT NULL,
  ocorrencia_nome TEXT NOT NULL,
  contexto_nome   TEXT NOT NULL,
  criado_em     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_historico_user_criado
  ON historico_anotacoes(user_id, criado_em DESC);

CREATE INDEX idx_historico_criado
  ON historico_anotacoes(criado_em);

ALTER TABLE historico_anotacoes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "usuario_ve_proprio_historico"
  ON historico_anotacoes
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "admin_ve_todo_historico"
  ON historico_anotacoes
  FOR SELECT
  USING (is_admin());

-- Função de purga: remove registros com mais de 30 dias
CREATE OR REPLACE FUNCTION purgar_historico_antigo()
RETURNS void LANGUAGE sql SECURITY DEFINER AS $$
  DELETE FROM historico_anotacoes
  WHERE criado_em < now() - INTERVAL '30 days';
$$;
