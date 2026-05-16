-- Tabela de casos clÃ­nicos para o Modo Estudo
CREATE TABLE IF NOT EXISTS casos_estudo (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ocorrencia_id       INTEGER NOT NULL REFERENCES ocorrencias(id),
  contexto_id         INTEGER NOT NULL REFERENCES contextos(id),
  titulo              TEXT NOT NULL,
  narrativa           TEXT NOT NULL,
  campos_gabarito     JSONB NOT NULL,
  criterios_avaliacao JSONB NOT NULL,
  dificuldade         TEXT NOT NULL DEFAULT 'basico',
  ativo               BOOLEAN NOT NULL DEFAULT true,
  criado_em           TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT dificuldade_valida CHECK (dificuldade IN ('basico','intermediario','avancado'))
);

CREATE INDEX idx_casos_dificuldade ON casos_estudo(dificuldade, ativo);

ALTER TABLE casos_estudo ENABLE ROW LEVEL SECURITY;

CREATE POLICY "casos_leitura_autenticados"
  ON casos_estudo FOR SELECT
  USING (auth.uid() IS NOT NULL AND ativo = true);

CREATE POLICY "admin_gerencia_casos"
  ON casos_estudo FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Tabela de resultados das prÃ¡ticas (dados do paper psicomÃ©trico)
CREATE TABLE IF NOT EXISTS resultados_estudo (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  caso_id             UUID NOT NULL REFERENCES casos_estudo(id),
  texto_usuario       TEXT NOT NULL,
  score_completude    NUMERIC(5,2) NOT NULL,
  criterios_resultado JSONB NOT NULL,
  criado_em           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_resultados_user ON resultados_estudo(user_id, criado_em DESC);
CREATE INDEX idx_resultados_caso ON resultados_estudo(caso_id);

ALTER TABLE resultados_estudo ENABLE ROW LEVEL SECURITY;

CREATE POLICY "usuario_ve_proprio_resultado"
  ON resultados_estudo FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "admin_ve_todos_resultados"
  ON resultados_estudo FOR SELECT
  USING (is_admin());

