-- =====================================================================
-- Migration: Nova ocorrência — Óbito
-- Data: 2026-05-16
-- Templates: padrão (7 contextos), centro_cirurgico, maternidade
-- =====================================================================

-- ── 1. OCORRÊNCIA ────────────────────────────────────────────────────

INSERT INTO ocorrencias (slug, nome, categoria) VALUES
  ('obito', 'Óbito', 'Eventos Clínicos')
ON CONFLICT (slug) DO NOTHING;


-- ── 2. TEMPLATE PADRÃO (7 contextos) ─────────────────────────────────

INSERT INTO templates (ocorrencia_id, contexto_id, template, campos)
SELECT o.id, c.id,
'Óbito constatado às [hora_obito] pelo médico [medico_responsavel]. Causa mortis: [causa_mortis]. Família notificada: [familia_notificada], às [hora_notificacao_familia], por [quem_notificou_familia]. [comunicacao_adicional] Realizados cuidados pós-morte: higienização do corpo, posicionamento em decúbito dorsal, membros alinhados, olhos e boca ocluídos. Identificação: [identificacao]. Dispositivos retirados: [dispositivos_retirados]. Materiais utilizados: [materiais_utilizados]. Pertences inventariados e [destino_pertences]. Cuidados éticos observados: [cuidados_eticos]. Documentação: [documentacao]. Destino do corpo: [destino_corpo]. Saída do setor às [hora_saida_setor].',
'[
  {"id":"hora_obito","label":"Hora do óbito","tipo":"tempo"},
  {"id":"medico_responsavel","label":"Médico que decretou o óbito","tipo":"texto"},
  {"id":"causa_mortis","label":"Causa mortis","tipo":"opcoes","opcoes":["Declarada pelo médico no momento","Aguarda esclarecimento / investigação em curso","Não declarada — médico legista acionado"]},
  {"id":"familia_notificada","label":"Família notificada","tipo":"opcoes","opcoes":["Sim — presencial","Sim — por telefone","Não localizada — tentativas registradas","Não havia familiar identificado"]},
  {"id":"hora_notificacao_familia","label":"Horário da notificação à família","tipo":"tempo"},
  {"id":"quem_notificou_familia","label":"Notificação realizada por","tipo":"opcoes","opcoes":["Médico responsável","Enfermeiro(a) do setor","Assistente social","Outro profissional da equipe"]},
  {"id":"comunicacao_adicional","label":"Comunicações adicionais realizadas","tipo":"multiplo","opcoes":["Médico assistente notificado (não estava presente)","SCIH notificada — suspeita de causa infecciosa","Assistência social acionada","Ouvidoria notificada","Nenhuma comunicação adicional necessária"]},
  {"id":"identificacao","label":"Identificação do corpo","tipo":"opcoes","opcoes":["Pulseira de identificação mantida e conferida","Etiqueta de identificação fixada no corpo e no invólucro","Pulseira + etiqueta — dupla identificação realizada","Identificação pendente — equipe responsável notificada"]},
  {"id":"dispositivos_retirados","label":"Dispositivos retirados","tipo":"multiplo","opcoes":["AVP — Acesso Venoso Periférico","CVC — Cateter Venoso Central","PICC","SVD — Sonda Vesical de Demora","SNE — Sonda Nasoenteral","SNG — Sonda Nasogástrica","Dreno cirúrgico","Dreno de tórax","Cateter de diálise","Cateter de pressão arterial invasiva","Traqueostomia (cânula retirada)","TOT — Tubo orotraqueal","Marca-passo externo","Nenhum dispositivo presente","Outro"]},
  {"id":"materiais_utilizados","label":"Materiais utilizados nos cuidados pós-morte","tipo":"texto"},
  {"id":"destino_pertences","label":"Pertences do paciente","tipo":"opcoes","opcoes":["entregues à família mediante assinatura de recibo","inventariados e guardados aguardando familiar responsável","inventariados e encaminhados à administração do hospital — sem familiar presente","sem pertences identificados no setor"]},
  {"id":"cuidados_eticos","label":"Cuidados éticos observados","tipo":"multiplo","opcoes":["Privacidade e dignidade preservadas durante todo o procedimento","Acompanhamento espiritual/religioso providenciado a pedido da família","Família recebeu tempo para despedida com privacidade","Equipe orientada sobre sigilo e conduta adequada","Nenhum familiar presente — cuidados realizados com equipe mínima"]},
  {"id":"documentacao","label":"Documentação","tipo":"multiplo","opcoes":["DO — Declaração de Óbito emitida pelo médico","Prontuário encerrado e encaminhado ao arquivo","Boletim de ocorrência registrado (morte suspeita / violenta)","RNHM — Registro Nacional de Homicídios e Mortes Violentas notificado","Documentação completa — sem pendências"]},
  {"id":"destino_corpo","label":"Destino do corpo","tipo":"opcoes","opcoes":["SVO — Serviço de Verificação de Óbito","IML — Instituto Médico Legal","Funerária autorizada pela família","Necrotério do hospital — aguardando familiar","Outro"]},
  {"id":"hora_saida_setor","label":"Horário de saída do setor","tipo":"tempo"}
]'::json
FROM ocorrencias o, contextos c
WHERE o.slug = 'obito'
AND c.slug IN ('adulto_clinico','uti','uti_neo','clinica_cirurgica','pronto_atendimento','geriatria','pediatria');


-- ── 3. TEMPLATE CENTRO CIRÚRGICO ─────────────────────────────────────

INSERT INTO templates (ocorrencia_id, contexto_id, template, campos)
SELECT o.id, c.id,
'Óbito constatado às [hora_obito] pelo médico [medico_responsavel]. Causa mortis: [causa_mortis]. Procedimento cirúrgico em curso: [procedimento_cirurgico]. Fase da cirurgia no momento do óbito: [fase_cirurgia]. Cirurgião responsável presente: [cirurgiao_presente]. Anestesiologista presente: [anestesiologista_presente]. Família notificada: [familia_notificada], às [hora_notificacao_familia], por [quem_notificou_familia]. [comunicacao_adicional] Realizados cuidados pós-morte: higienização do corpo, posicionamento em decúbito dorsal, membros alinhados, olhos e boca ocluídos. Identificação: [identificacao]. Dispositivos retirados: [dispositivos_retirados]. Materiais utilizados: [materiais_utilizados]. Pertences inventariados e [destino_pertences]. Cuidados éticos observados: [cuidados_eticos]. Documentação: [documentacao]. Destino do corpo: [destino_corpo]. Saída do setor às [hora_saida_setor].',
'[
  {"id":"hora_obito","label":"Hora do óbito","tipo":"tempo"},
  {"id":"medico_responsavel","label":"Médico que decretou o óbito","tipo":"texto"},
  {"id":"causa_mortis","label":"Causa mortis","tipo":"opcoes","opcoes":["Declarada pelo médico no momento","Aguarda esclarecimento / investigação em curso","Não declarada — médico legista acionado"]},
  {"id":"procedimento_cirurgico","label":"Procedimento cirúrgico em curso","tipo":"texto"},
  {"id":"fase_cirurgia","label":"Fase da cirurgia no momento do óbito","tipo":"opcoes","opcoes":["Indução anestésica","Intraoperatório — início","Intraoperatório — meio","Intraoperatório — fase final","Pós-operatório imediato na sala cirúrgica","Recuperação anestésica (SRPA)"]},
  {"id":"cirurgiao_presente","label":"Cirurgião responsável","tipo":"opcoes","opcoes":["Presente durante todo o procedimento","Presente e notificado imediatamente","Ausente — notificado por telefone","Outro cirurgião assumiu o caso"]},
  {"id":"anestesiologista_presente","label":"Anestesiologista","tipo":"opcoes","opcoes":["Presente durante todo o procedimento","Presente e participou das manobras de ressuscitação","Ausente — substituto acionado"]},
  {"id":"familia_notificada","label":"Família notificada","tipo":"opcoes","opcoes":["Sim — presencial","Sim — por telefone","Não localizada — tentativas registradas","Não havia familiar identificado"]},
  {"id":"hora_notificacao_familia","label":"Horário da notificação à família","tipo":"tempo"},
  {"id":"quem_notificou_familia","label":"Notificação realizada por","tipo":"opcoes","opcoes":["Médico responsável","Médico cirurgião","Enfermeiro(a) do setor","Assistente social","Outro profissional da equipe"]},
  {"id":"comunicacao_adicional","label":"Comunicações adicionais realizadas","tipo":"multiplo","opcoes":["Médico assistente notificado (não estava presente)","SCIH notificada — suspeita de causa infecciosa","Assistência social acionada","CCIH notificada","Ouvidoria notificada","Nenhuma comunicação adicional necessária"]},
  {"id":"identificacao","label":"Identificação do corpo","tipo":"opcoes","opcoes":["Pulseira de identificação mantida e conferida","Etiqueta de identificação fixada no corpo e no invólucro","Pulseira + etiqueta — dupla identificação realizada","Identificação pendente — equipe responsável notificada"]},
  {"id":"dispositivos_retirados","label":"Dispositivos retirados","tipo":"multiplo","opcoes":["AVP — Acesso Venoso Periférico","CVC — Cateter Venoso Central","PICC","SVD — Sonda Vesical de Demora","SNE — Sonda Nasoenteral","SNG — Sonda Nasogástrica","Dreno cirúrgico","Dreno de tórax","Cateter de diálise","Cateter de pressão arterial invasiva","Traqueostomia (cânula retirada)","TOT — Tubo orotraqueal","Marca-passo externo","Eletrodos cirúrgicos removidos","Nenhum dispositivo presente","Outro"]},
  {"id":"materiais_utilizados","label":"Materiais utilizados nos cuidados pós-morte","tipo":"texto"},
  {"id":"destino_pertences","label":"Pertences do paciente","tipo":"opcoes","opcoes":["entregues à família mediante assinatura de recibo","inventariados e guardados aguardando familiar responsável","inventariados e encaminhados à administração do hospital — sem familiar presente","sem pertences identificados no setor"]},
  {"id":"cuidados_eticos","label":"Cuidados éticos observados","tipo":"multiplo","opcoes":["Privacidade e dignidade preservadas durante todo o procedimento","Acompanhamento espiritual/religioso providenciado a pedido da família","Família recebeu tempo para despedida com privacidade","Equipe orientada sobre sigilo e conduta adequada","Nenhum familiar presente — cuidados realizados com equipe mínima"]},
  {"id":"documentacao","label":"Documentação","tipo":"multiplo","opcoes":["DO — Declaração de Óbito emitida pelo médico","Relatório cirúrgico / anestésico registrado no prontuário","Prontuário encerrado e encaminhado ao arquivo","Boletim de ocorrência registrado (morte suspeita / violenta)","Documentação completa — sem pendências"]},
  {"id":"destino_corpo","label":"Destino do corpo","tipo":"opcoes","opcoes":["SVO — Serviço de Verificação de Óbito","IML — Instituto Médico Legal","Funerária autorizada pela família","Necrotério do hospital — aguardando familiar","Outro"]},
  {"id":"hora_saida_setor","label":"Horário de saída do setor","tipo":"tempo"}
]'::json
FROM ocorrencias o, contextos c
WHERE o.slug = 'obito' AND c.slug = 'centro_cirurgico';


-- ── 4. TEMPLATE MATERNIDADE ───────────────────────────────────────────
-- Campo tipo_obito controla visibilidade dos campos específicos via depende_de

INSERT INTO templates (ocorrencia_id, contexto_id, template, campos)
SELECT o.id, c.id,
'Tipo de óbito: [tipo_obito]. Óbito constatado às [hora_obito] pelo médico [medico_responsavel]. Causa mortis: [causa_mortis]. [campos_maternos][campos_neonatais] Família notificada: [familia_notificada], às [hora_notificacao_familia], por [quem_notificou_familia]. [comunicacao_adicional] Realizados cuidados pós-morte: [cuidados_corpo]. Identificação: [identificacao]. Dispositivos retirados: [dispositivos_retirados]. Materiais utilizados: [materiais_utilizados]. Pertences inventariados e [destino_pertences]. Cuidados éticos observados: [cuidados_eticos]. Documentação: [documentacao]. Destino do corpo: [destino_corpo]. Saída do setor às [hora_saida_setor].',
'[
  {"id":"tipo_obito","label":"Tipo de óbito","tipo":"opcoes","opcoes":["Óbito materno","Óbito neonatal"]},

  {"id":"hora_obito","label":"Hora do óbito","tipo":"tempo"},
  {"id":"medico_responsavel","label":"Médico que decretou o óbito","tipo":"texto"},
  {"id":"causa_mortis","label":"Causa mortis","tipo":"opcoes","opcoes":["Declarada pelo médico no momento","Aguarda esclarecimento / investigação em curso","Não declarada — médico legista acionado"]},

  {"id":"campos_maternos","label":"Situação obstétrica","tipo":"opcoes","opcoes":["Pré-parto — feto não nascido","Intraparto — durante o trabalho de parto","Pós-parto imediato (até 1h)","Pós-parto tardio (após 1h)","Pós-operatório de cesariana","Abortamento"],"depende_de":"tipo_obito","depende_valor":"Óbito materno"},
  {"id":"obito_fetal_associado","label":"Óbito fetal associado","tipo":"opcoes","opcoes":["Não","Sim — óbito fetal concomitante registrado separadamente"],"depende_de":"tipo_obito","depende_valor":"Óbito materno"},
  {"id":"comite_obito_materno","label":"Comitê de Mortalidade Materna","tipo":"opcoes","opcoes":["Notificado conforme protocolo institucional","Pendente de notificação — responsável avisado","Não se aplica"],"depende_de":"tipo_obito","depende_valor":"Óbito materno"},

  {"id":"campos_neonatais","label":"Idade do neonato","tipo":"opcoes","opcoes":["Óbito fetal (natimorto)","Neonato — menos de 24 horas de vida","Neonato — 1 a 6 dias de vida","Neonato — 7 a 27 dias de vida","Neonato — 28 dias ou mais"],"depende_de":"tipo_obito","depende_valor":"Óbito neonatal"},
  {"id":"peso_nascimento","label":"Peso ao nascimento","tipo":"texto","depende_de":"tipo_obito","depende_valor":"Óbito neonatal"},
  {"id":"idade_gestacional","label":"Idade gestacional","tipo":"texto","depende_de":"tipo_obito","depende_valor":"Óbito neonatal"},
  {"id":"manobras_reanimacao","label":"Manobras de reanimação realizadas","tipo":"opcoes","opcoes":["Sim — equipe neonatal presente","Sim — PCR revertido, óbito posterior","Não — óbito constatado ao nascimento","Não — decisão médica documentada em prontuário"],"depende_de":"tipo_obito","depende_valor":"Óbito neonatal"},
  {"id":"familia_presente_neo","label":"Família presente durante os cuidados","tipo":"opcoes","opcoes":["Sim — família acompanhou todo o processo","Sim — família chegou após o óbito","Não — família não localizada no momento"],"depende_de":"tipo_obito","depende_valor":"Óbito neonatal"},

  {"id":"familia_notificada","label":"Família notificada","tipo":"opcoes","opcoes":["Sim — presencial","Sim — por telefone","Não localizada — tentativas registradas","Não havia familiar identificado"]},
  {"id":"hora_notificacao_familia","label":"Horário da notificação à família","tipo":"tempo"},
  {"id":"quem_notificou_familia","label":"Notificação realizada por","tipo":"opcoes","opcoes":["Médico responsável","Enfermeiro(a) do setor","Assistente social","Outro profissional da equipe"]},
  {"id":"comunicacao_adicional","label":"Comunicações adicionais realizadas","tipo":"multiplo","opcoes":["Médico assistente notificado (não estava presente)","SCIH notificada — suspeita de causa infecciosa","Assistência social acionada","Comitê de Mortalidade Materna notificado","Comitê de Mortalidade Neonatal notificado","Ouvidoria notificada","Nenhuma comunicação adicional necessária"]},
  {"id":"cuidados_corpo","label":"Cuidados com o corpo realizados","tipo":"multiplo","opcoes":["Higienização do corpo","Posicionamento em decúbito dorsal com membros alinhados","Olhos e boca ocluídos","Corpo envolto em campo/lençol estéril","Identificação fixada no corpo e no invólucro","Cuidados especiais para neonato — envoltório adequado"]},
  {"id":"identificacao","label":"Identificação","tipo":"opcoes","opcoes":["Pulseira de identificação mantida e conferida","Etiqueta de identificação fixada no corpo e no invólucro","Pulseira + etiqueta — dupla identificação realizada","Identificação pendente — equipe responsável notificada"]},
  {"id":"dispositivos_retirados","label":"Dispositivos retirados","tipo":"multiplo","opcoes":["AVP — Acesso Venoso Periférico","CVC — Cateter Venoso Central","SVD — Sonda Vesical de Demora","SNE — Sonda Nasoenteral","TOT — Tubo orotraqueal","CPAP nasal","Dreno cirúrgico","Cateter umbilical","Nenhum dispositivo presente","Outro"]},
  {"id":"materiais_utilizados","label":"Materiais utilizados nos cuidados pós-morte","tipo":"texto"},
  {"id":"destino_pertences","label":"Pertences","tipo":"opcoes","opcoes":["entregues à família mediante assinatura de recibo","inventariados e guardados aguardando familiar responsável","inventariados e encaminhados à administração do hospital — sem familiar presente","sem pertences identificados no setor"]},
  {"id":"cuidados_eticos","label":"Cuidados éticos observados","tipo":"multiplo","opcoes":["Privacidade e dignidade preservadas durante todo o procedimento","Família recebeu tempo para despedida com privacidade","Acompanhamento espiritual/religioso providenciado a pedido da família","Apoio psicológico oferecido à família","Equipe orientada sobre sigilo e conduta adequada","Nenhum familiar presente — cuidados realizados com equipe mínima"]},
  {"id":"documentacao","label":"Documentação","tipo":"multiplo","opcoes":["DO — Declaração de Óbito emitida pelo médico","DNV — Declaração de Nascido Vivo emitida (natimorto com mais de 20 semanas)","Prontuário encerrado e encaminhado ao arquivo","Boletim de ocorrência registrado (morte suspeita / violenta)","SINASC notificado","Documentação completa — sem pendências"]},
  {"id":"destino_corpo","label":"Destino do corpo","tipo":"opcoes","opcoes":["SVO — Serviço de Verificação de Óbito","IML — Instituto Médico Legal","Funerária autorizada pela família","Necrotério do hospital — aguardando familiar","Outro"]},
  {"id":"hora_saida_setor","label":"Horário de saída do setor","tipo":"tempo"}
]'::json
FROM ocorrencias o, contextos c
WHERE o.slug = 'obito' AND c.slug = 'maternidade';
