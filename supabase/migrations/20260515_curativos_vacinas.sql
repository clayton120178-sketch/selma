-- =====================================================================
-- Migration: Novas ocorrências — Curativos e Aplicação de Vacinas
-- Data: 2026-05-15
-- =====================================================================

-- ── 1. OCORRÊNCIAS ───────────────────────────────────────────────────

INSERT INTO ocorrencias (slug, nome, categoria) VALUES
  ('curativo',        'Curativo',              'Procedimentos'),
  ('aplicacao_vacina','Aplicação de Vacina',   'Procedimentos')
ON CONFLICT (slug) DO NOTHING;


-- ── 2. TEMPLATES — CURATIVO ──────────────────────────────────────────
-- Contextos: hospital | ubs_ambulatorio | domiciliar
-- Os IDs de contexto são consultados pelo slug; usamos subquery segura.

INSERT INTO templates (ocorrencia_id, contexto_id, template, campos)
SELECT
  o.id,
  c.id,
  -- Template hospital
  'Realizado curativo em [local_lesao]. Tipo de lesão: [tipo_lesao]. Leito da ferida: [leito_ferida]. Exsudato: [exsudato_tipo], aspecto [exsudato_aspecto], quantidade [exsudato_quantidade]. Odor: [odor]. Bordas: [bordas]. Pele perilesional: [pele_perilesional]. Cobertura primária utilizada: [cobertura_primaria]. Cobertura secundária: [cobertura_secundaria]. Condições de fixação: [fixacao]. Tamanho aproximado da lesão: [tamanho_lesao]. Paciente [reacao_dor] durante o procedimento. Próxima troca programada: [proxima_troca]. Anotação realizada conforme prescrição médica/protocolo institucional.',
  '[
    {"id":"local_lesao","label":"Local da lesão","tipo":"texto"},
    {"id":"tipo_lesao","label":"Tipo de lesão","tipo":"opcoes","opcoes":["Ferida operatória limpa","Ferida operatória infectada","Ferida traumática","Úlcera por pressão","Lesão por umidade (MASD)","Úlcera venosa","Úlcera arterial","Úlcera neuropática / diabética","Queimadura","Fístula","Deiscência de sutura","Lesão oncológica","Outra"]},
    {"id":"leito_ferida","label":"Leito da ferida","tipo":"multiplo","opcoes":["Tecido de granulação (vermelho)","Tecido epitelial (rosa)","Fibrina (amarelo)","Necrose seca (preto/escuro)","Necrose úmida","Tecido de esfacelo","Osso/tendão exposto","Túnel/cavidade"]},
    {"id":"exsudato_tipo","label":"Tipo de exsudato","tipo":"opcoes","opcoes":["Ausente","Seroso","Serossanguinolento","Sanguinolento","Purulento","Hemopurulento"]},
    {"id":"exsudato_aspecto","label":"Aspecto do exsudato","tipo":"opcoes","opcoes":["Límpido","Turvo","Espesso","Não se aplica"],"depende_de":"exsudato_tipo","depende_valor":"Seroso|Serossanguinolento|Sanguinolento|Purulento|Hemopurulento"},
    {"id":"exsudato_quantidade","label":"Quantidade de exsudato","tipo":"opcoes","opcoes":["Pequena","Moderada","Grande","Não se aplica"],"depende_de":"exsudato_tipo","depende_valor":"Seroso|Serossanguinolento|Sanguinolento|Purulento|Hemopurulento"},
    {"id":"odor","label":"Odor","tipo":"opcoes","opcoes":["Ausente","Discreto","Moderado","Fétido / intenso"]},
    {"id":"bordas","label":"Bordas da lesão","tipo":"opcoes","opcoes":["Regulares e aderidas","Irregulares","Maceradas","Descoladas / solapadas","Endurecidas","Hiperemiadas"]},
    {"id":"pele_perilesional","label":"Pele perilesional","tipo":"opcoes","opcoes":["Íntegra","Macerada","Hiperemiada","Ressecada / descamativa","Edemaciada","Endurecida (induração)","Com bolhas","Com lesão satélite"]},
    {"id":"cobertura_primaria","label":"Cobertura primária","tipo":"opcoes","opcoes":["Não utilizada","Gaze estéril","Hidrogel","Alginato de cálcio","Espuma de poliuretano (foam)","Curativo de prata (Ag)","Carvão ativado com prata","Colagenase (enzimático)","Papaína","Película transparente (filme)","Hidrocoloide","Curativo de mel (mel medicinal / mel de Manuka)","Outra"]},
    {"id":"cobertura_secundaria","label":"Cobertura secundária","tipo":"opcoes","opcoes":["Não utilizada","Gaze estéril","Atadura","Filme transparente","Espuma de poliuretano (foam)","Malha tubular","Outra"]},
    {"id":"fixacao","label":"Fixação","tipo":"opcoes","opcoes":["Fita microporosa","Fita adesiva impermeável","Fita hipoalergênica","Malha tubular","Bandagem","Sem fixação adicional"]},
    {"id":"tamanho_lesao","label":"Tamanho aproximado da lesão","tipo":"texto"},
    {"id":"reacao_dor","label":"Reação do paciente durante o procedimento","tipo":"opcoes","opcoes":["referiu ausência de dor","referiu dor leve tolerável","referiu dor moderada — analgesia avaliada","referiu dor intensa — equipe médica notificada","não comunicativo / sem resposta verbal"]},
    {"id":"proxima_troca","label":"Próxima troca programada","tipo":"texto"}
  ]'::json
FROM ocorrencias o, contextos c
WHERE o.slug = 'curativo' AND c.slug = 'hospital';

INSERT INTO templates (ocorrencia_id, contexto_id, template, campos)
SELECT
  o.id,
  c.id,
  'Realizado curativo em [local_lesao]. Tipo de lesão: [tipo_lesao]. Leito da ferida: [leito_ferida]. Exsudato: [exsudato_tipo], quantidade [exsudato_quantidade]. Odor: [odor]. Bordas: [bordas]. Pele perilesional: [pele_perilesional]. Cobertura utilizada: [cobertura_primaria]. Fixação: [fixacao]. Tamanho aproximado: [tamanho_lesao]. Paciente [reacao_dor] durante o procedimento. Orientações sobre cuidados domiciliares prestadas ao paciente/responsável. Próxima troca: [proxima_troca].',
  '[
    {"id":"local_lesao","label":"Local da lesão","tipo":"texto"},
    {"id":"tipo_lesao","label":"Tipo de lesão","tipo":"opcoes","opcoes":["Ferida operatória limpa","Ferida operatória infectada","Ferida traumática","Úlcera por pressão","Lesão por umidade (MASD)","Úlcera venosa","Úlcera arterial","Úlcera neuropática / diabética","Queimadura","Deiscência de sutura","Outra"]},
    {"id":"leito_ferida","label":"Leito da ferida","tipo":"multiplo","opcoes":["Tecido de granulação (vermelho)","Tecido epitelial (rosa)","Fibrina (amarelo)","Necrose seca","Necrose úmida","Esfacelo","Túnel/cavidade"]},
    {"id":"exsudato_tipo","label":"Tipo de exsudato","tipo":"opcoes","opcoes":["Ausente","Seroso","Serossanguinolento","Sanguinolento","Purulento","Hemopurulento"]},
    {"id":"exsudato_quantidade","label":"Quantidade de exsudato","tipo":"opcoes","opcoes":["Pequena","Moderada","Grande","Não se aplica"],"depende_de":"exsudato_tipo","depende_valor":"Seroso|Serossanguinolento|Sanguinolento|Purulento|Hemopurulento"},
    {"id":"odor","label":"Odor","tipo":"opcoes","opcoes":["Ausente","Discreto","Moderado","Fétido / intenso"]},
    {"id":"bordas","label":"Bordas da lesão","tipo":"opcoes","opcoes":["Regulares e aderidas","Irregulares","Maceradas","Descoladas / solapadas","Endurecidas","Hiperemiadas"]},
    {"id":"pele_perilesional","label":"Pele perilesional","tipo":"opcoes","opcoes":["Íntegra","Macerada","Hiperemiada","Ressecada / descamativa","Edemaciada","Endurecida (induração)","Com bolhas"]},
    {"id":"cobertura_primaria","label":"Cobertura utilizada","tipo":"opcoes","opcoes":["Gaze estéril","Hidrogel","Alginato de cálcio","Espuma de poliuretano (foam)","Curativo de prata (Ag)","Curativo enzimático (colagenase/papaína)","Película transparente (filme)","Hidrocoloide","Outra"]},
    {"id":"fixacao","label":"Fixação","tipo":"opcoes","opcoes":["Fita microporosa","Fita hipoalergênica","Malha tubular","Bandagem","Sem fixação adicional"]},
    {"id":"tamanho_lesao","label":"Tamanho aproximado da lesão","tipo":"texto"},
    {"id":"reacao_dor","label":"Reação do paciente durante o procedimento","tipo":"opcoes","opcoes":["referiu ausência de dor","referiu dor leve tolerável","referiu dor moderada","referiu dor intensa — equipe médica notificada","não comunicativo / sem resposta verbal"]},
    {"id":"proxima_troca","label":"Próxima troca programada","tipo":"texto"}
  ]'::json
FROM ocorrencias o, contextos c
WHERE o.slug = 'curativo' AND c.slug = 'ubs_ambulatorio';

INSERT INTO templates (ocorrencia_id, contexto_id, template, campos)
SELECT
  o.id,
  c.id,
  'Realizado curativo domiciliar em [local_lesao]. Tipo de lesão: [tipo_lesao]. Leito da ferida: [leito_ferida]. Exsudato: [exsudato_tipo], quantidade [exsudato_quantidade]. Odor: [odor]. Pele perilesional: [pele_perilesional]. Cobertura utilizada: [cobertura_primaria]. Fixação: [fixacao]. Paciente [reacao_dor] durante o procedimento. Cuidador/responsável [participacao_cuidador] no procedimento. Orientações sobre higiene da ferida, sinais de infecção e próxima troca prestadas ao paciente e responsável. Retorno/próxima visita: [proxima_troca].',
  '[
    {"id":"local_lesao","label":"Local da lesão","tipo":"texto"},
    {"id":"tipo_lesao","label":"Tipo de lesão","tipo":"opcoes","opcoes":["Ferida operatória","Ferida traumática","Úlcera por pressão","Lesão por umidade (MASD)","Úlcera venosa","Úlcera arterial","Úlcera neuropática / diabética","Deiscência de sutura","Outra"]},
    {"id":"leito_ferida","label":"Leito da ferida","tipo":"multiplo","opcoes":["Tecido de granulação (vermelho)","Tecido epitelial (rosa)","Fibrina (amarelo)","Necrose seca","Necrose úmida","Esfacelo","Túnel/cavidade"]},
    {"id":"exsudato_tipo","label":"Tipo de exsudato","tipo":"opcoes","opcoes":["Ausente","Seroso","Serossanguinolento","Sanguinolento","Purulento","Hemopurulento"]},
    {"id":"exsudato_quantidade","label":"Quantidade de exsudato","tipo":"opcoes","opcoes":["Pequena","Moderada","Grande","Não se aplica"],"depende_de":"exsudato_tipo","depende_valor":"Seroso|Serossanguinolento|Sanguinolento|Purulento|Hemopurulento"},
    {"id":"odor","label":"Odor","tipo":"opcoes","opcoes":["Ausente","Discreto","Moderado","Fétido / intenso"]},
    {"id":"pele_perilesional","label":"Pele perilesional","tipo":"opcoes","opcoes":["Íntegra","Macerada","Hiperemiada","Ressecada","Edemaciada","Endurecida"]},
    {"id":"cobertura_primaria","label":"Cobertura utilizada","tipo":"opcoes","opcoes":["Gaze estéril","Hidrogel","Alginato de cálcio","Espuma de poliuretano (foam)","Curativo de prata (Ag)","Curativo enzimático","Hidrocoloide","Outra"]},
    {"id":"fixacao","label":"Fixação","tipo":"opcoes","opcoes":["Fita microporosa","Fita hipoalergênica","Malha tubular","Bandagem","Sem fixação adicional"]},
    {"id":"reacao_dor","label":"Reação do paciente durante o procedimento","tipo":"opcoes","opcoes":["referiu ausência de dor","referiu dor leve tolerável","referiu dor moderada","referiu dor intensa — familiar notificado para acionar UBS/UPA","não comunicativo / sem resposta verbal"]},
    {"id":"participacao_cuidador","label":"Participação do cuidador/familiar","tipo":"opcoes","opcoes":["presente e orientado","presente e participou ativamente do procedimento","ausente durante o procedimento","não há cuidador identificado"]},
    {"id":"proxima_troca","label":"Próxima troca / retorno programado","tipo":"texto"}
  ]'::json
FROM ocorrencias o, contextos c
WHERE o.slug = 'curativo' AND c.slug = 'domiciliar';


-- ── 3. TEMPLATES — APLICAÇÃO DE VACINA ───────────────────────────────

INSERT INTO templates (ocorrencia_id, contexto_id, template, campos)
SELECT
  o.id,
  c.id,
  'Realizada aplicação de vacina [nome_vacina], dose: [dose_numero]. Via de administração: [via_administracao]. Local de aplicação: [local_aplicacao]. Lote: [lote]. Validade do imunobiológico: [validade]. Fabricante: [fabricante]. Técnica asséptica observada. Paciente permaneceu em observação por [tempo_observacao] minutos após aplicação. Reação imediata: [reacao_imediata]. Cartão de vacina [cartao_vacina]. Paciente orientado sobre: possíveis reações esperadas, cuidados com o local de aplicação e retorno conforme calendário vacinal.',
  '[
    {"id":"nome_vacina","label":"Imunobiológico (vacina)","tipo":"opcoes","opcoes":["BCG","Hepatite B","Pentavalente (DTP + Hib + HB)","DTP — Tríplice bacteriana","dTpa — Tríplice acelular adulto","dT — Dupla adulto","Febre Amarela","Tríplice viral (SCR — Sarampo, Caxumba, Rubéola)","Tetraviral (SCRV)","Varicela","HPV (Papilomavírus Humano)","Meningocócica C","Meningocócica ACWY","Pneumocócica 10V","Pneumocócica 23V","Rotavírus humano G1P1[8] (VORH)","Influenza (gripe)","COVID-19","Raiva","Outra / não listada"]},
    {"id":"dose_numero","label":"Dose","tipo":"opcoes","opcoes":["Dose única","1ª dose","2ª dose","3ª dose","4ª dose (reforço)","1º reforço","2º reforço","Dose de reforço anual","Dose de bloqueio","Dose extra"]},
    {"id":"via_administracao","label":"Via de administração","tipo":"opcoes","opcoes":["Intramuscular (IM)","Subcutânea (SC)","Intradérmica (ID)","Oral (VO)"]},
    {"id":"local_aplicacao","label":"Local de aplicação","tipo":"opcoes","opcoes":["Deltoide direito","Deltoide esquerdo","Vasto lateral direito da coxa","Vasto lateral esquerdo da coxa","Região glútea ventroglútea direita","Região glútea ventroglútea esquerda","Região dorsal do antebraço (ID)","Oral"]},
    {"id":"lote","label":"Lote do imunobiológico","tipo":"texto"},
    {"id":"validade","label":"Validade do imunobiológico","tipo":"texto"},
    {"id":"fabricante","label":"Fabricante","tipo":"opcoes","opcoes":["Bio-Manguinhos / Fiocruz","Instituto Butantan","Serum Institute of India","Pfizer","AstraZeneca","Janssen","Moderna","GSK","Sanofi Pasteur","MSD","Outro"]},
    {"id":"tempo_observacao","label":"Tempo de observação pós-vacina","tipo":"opcoes","opcoes":["15","20","30"]},
    {"id":"reacao_imediata","label":"Reação imediata observada","tipo":"opcoes","opcoes":["Nenhuma reação observada","Dor local leve — paciente orientado","Eritema no local — paciente orientado","Edema local leve — paciente orientado","Lipotimia / síncope vasovagal — protocolo aplicado, paciente estável","Reação anafilática — protocolo de emergência acionado"]},
    {"id":"cartao_vacina","label":"Cartão de vacina","tipo":"opcoes","opcoes":["atualizado e devolvido ao paciente","apresentado, atualizado e arquivado na unidade","não apresentado pelo paciente — dose registrada no sistema"]}
  ]'::json
FROM ocorrencias o, contextos c
WHERE o.slug = 'aplicacao_vacina' AND c.slug = 'ubs_ambulatorio';

INSERT INTO templates (ocorrencia_id, contexto_id, template, campos)
SELECT
  o.id,
  c.id,
  'Realizada aplicação de vacina [nome_vacina], dose: [dose_numero], conforme prescrição médica / protocolo institucional. Via de administração: [via_administracao]. Local de aplicação: [local_aplicacao]. Lote: [lote]. Validade do imunobiológico: [validade]. Fabricante: [fabricante]. Técnica asséptica observada. Paciente permaneceu em observação por [tempo_observacao] minutos após aplicação. Reação imediata: [reacao_imediata]. Registro lançado no prontuário eletrônico / caderneta de vacinação.',
  '[
    {"id":"nome_vacina","label":"Imunobiológico (vacina)","tipo":"opcoes","opcoes":["BCG","Hepatite B","DTP — Tríplice bacteriana","dTpa — Tríplice acelular adulto","dT — Dupla adulto","Febre Amarela","Tríplice viral (SCR)","Varicela","Meningocócica C","Meningocócica ACWY","Pneumocócica 23V","Influenza (gripe)","COVID-19","Raiva","Outra / não listada"]},
    {"id":"dose_numero","label":"Dose","tipo":"opcoes","opcoes":["Dose única","1ª dose","2ª dose","3ª dose","4ª dose (reforço)","1º reforço","2º reforço","Dose de reforço anual","Dose de bloqueio","Dose extra"]},
    {"id":"via_administracao","label":"Via de administração","tipo":"opcoes","opcoes":["Intramuscular (IM)","Subcutânea (SC)","Intradérmica (ID)","Oral (VO)"]},
    {"id":"local_aplicacao","label":"Local de aplicação","tipo":"opcoes","opcoes":["Deltoide direito","Deltoide esquerdo","Vasto lateral direito da coxa","Vasto lateral esquerdo da coxa","Região glútea ventroglútea direita","Região glútea ventroglútea esquerda","Região dorsal do antebraço (ID)","Oral"]},
    {"id":"lote","label":"Lote do imunobiológico","tipo":"texto"},
    {"id":"validade","label":"Validade do imunobiológico","tipo":"texto"},
    {"id":"fabricante","label":"Fabricante","tipo":"opcoes","opcoes":["Bio-Manguinhos / Fiocruz","Instituto Butantan","Serum Institute of India","Pfizer","AstraZeneca","Janssen","Moderna","GSK","Sanofi Pasteur","MSD","Outro"]},
    {"id":"tempo_observacao","label":"Tempo de observação pós-vacina","tipo":"opcoes","opcoes":["15","20","30"]},
    {"id":"reacao_imediata","label":"Reação imediata observada","tipo":"opcoes","opcoes":["Nenhuma reação observada","Dor local leve — paciente orientado","Eritema no local — paciente orientado","Edema local leve — paciente orientado","Lipotimia / síncope vasovagal — protocolo aplicado, paciente estável","Reação anafilática — protocolo de emergência acionado"]}
  ]'::json
FROM ocorrencias o, contextos c
WHERE o.slug = 'aplicacao_vacina' AND c.slug = 'hospital';
