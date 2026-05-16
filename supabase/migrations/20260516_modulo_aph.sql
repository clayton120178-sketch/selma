-- ============================================================
-- Migration: 20260516_modulo_aph.sql
-- Módulo APH — Atendimento Pré-Hospitalar
-- ============================================================

-- Tabela principal de boletins APH
CREATE TABLE IF NOT EXISTS ocorrencias_aph (
  id                         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id                    UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  criado_em                  TIMESTAMPTZ DEFAULT now(),
  atualizado_em              TIMESTAMPTZ DEFAULT now(),

  -- SEÇÃO A: Identificação da Ocorrência
  numero_ocorrencia          TEXT,
  data_acionamento           TIMESTAMPTZ,
  data_chegada_local         TIMESTAMPTZ,
  data_saida_local           TIMESTAMPTZ,
  data_chegada_hospital      TIMESTAMPTZ,
  viatura                    TEXT,
  medico_regulador           TEXT,
  natureza_ocorrencia        TEXT, -- trauma | clinico | obstetrico | psiquiatrico | pediatrico
  tipo_local                 TEXT, -- via_publica | residencia | comercio | outro
  endereco_ocorrencia        TEXT,

  -- SEÇÃO B: Identificação do Paciente
  paciente_nome              TEXT,
  paciente_idade             INTEGER,
  paciente_sexo              TEXT, -- M | F | nao_informado
  paciente_documento         TEXT,
  paciente_contato           TEXT,

  -- SEÇÃO C: ABCDE — Avaliação Primária
  abcde_via_aerea            TEXT, -- pervio | obstruido | dispositivo
  abcde_dispositivo_va       TEXT,
  abcde_respiracao           TEXT, -- normal | alterada | ausente
  abcde_fr                   INTEGER,
  abcde_spo2                 INTEGER,
  abcde_o2_fluxo             INTEGER,
  abcde_o2_dispositivo       TEXT, -- cateter | mascara_simples | mascara_reservatorio | vmi
  abcde_circulacao           TEXT, -- normal | alterada | pcr
  abcde_pulso                TEXT, -- presente | ausente
  abcde_ritmo_pulso          TEXT, -- regular | irregular
  abcde_forca_pulso          TEXT, -- cheio | fino | filiforme
  abcde_tec                  TEXT, -- menor_2s | maior_2s
  abcde_hemorragia           BOOLEAN DEFAULT false,
  abcde_hemorragia_tipo      TEXT,
  abcde_nivel_consciencia    TEXT, -- alerta | voz | dor | irresponsivo
  abcde_pupilas              TEXT, -- isocoricas_fotorreativas | anisocoricas | miose | midriase
  abcde_exposicao            TEXT,
  abcde_suspeita_trauma_raqui BOOLEAN DEFAULT false,

  -- SEÇÃO D: Glasgow
  glasgow_ocular             INTEGER, -- 1-4
  glasgow_verbal             INTEGER, -- 1-5
  glasgow_motor              INTEGER, -- 1-6
  glasgow_total              INTEGER GENERATED ALWAYS AS (
    COALESCE(glasgow_ocular, 0) + COALESCE(glasgow_verbal, 0) + COALESCE(glasgow_motor, 0)
  ) STORED,

  -- SEÇÃO E: Sinais Vitais — Série Temporal
  -- Formato JSONB: [{ horario, pa_sist, pa_diast, fc, fr, spo2, hgt, temp, eva }, ...]
  sinais_vitais              JSONB DEFAULT '[]'::jsonb,

  -- SEÇÃO F: SAMPLE — Anamnese
  sample_sintomas            TEXT,
  sample_alergias            TEXT,
  sample_medicamentos        TEXT,
  sample_historico           TEXT,
  sample_ultima_refeicao     TEXT,
  sample_eventos             TEXT,

  -- SEÇÃO G: Mecanismo de Lesão
  mecanismo_tipo             TEXT, -- trauma_contuso | perfurante | queimadura | afogamento | eletrico | clinico
  mecanismo_cinematica       TEXT,
  mecanismo_uso_epi          TEXT, -- cinto | capacete | airbag | nenhum

  -- SEÇÃO H: Intervenções
  -- Formato JSONB: [{ tipo, descricao, horario, profissional }, ...]
  intervencoes               JSONB DEFAULT '[]'::jsonb,

  -- SEÇÃO I: Desfecho
  desfecho_hospital          TEXT,
  desfecho_condicao          TEXT, -- estavel | instavel | em_pcr | obito_local
  desfecho_observacoes       TEXT,
  desfecho_profissional      TEXT,
  desfecho_coren             TEXT,
  desfecho_medico            TEXT,

  status_boletim             TEXT DEFAULT 'rascunho' -- rascunho | finalizado
);

-- RLS
ALTER TABLE ocorrencias_aph ENABLE ROW LEVEL SECURITY;

-- Usuário vê e escreve apenas seus próprios boletins
CREATE POLICY "aph_usuario_proprio" ON ocorrencias_aph
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Admin vê todos os boletins
CREATE POLICY "aph_admin_select_all" ON ocorrencias_aph
  FOR SELECT
  USING (is_admin());

-- Trigger para atualizar atualizado_em automaticamente
CREATE OR REPLACE FUNCTION update_aph_timestamp()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.atualizado_em = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_aph_updated
  BEFORE UPDATE ON ocorrencias_aph
  FOR EACH ROW EXECUTE FUNCTION update_aph_timestamp();
