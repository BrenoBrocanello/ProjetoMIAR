> Registro histórico anterior à reorganização no modelo da professora. A paginação e o checksum citados abaixo pertencem à versão auditada naquele momento. A revisão atual corrigiu o dicionário, a conclusão, a bibliografia e a apresentação, e retirou o apêndice de capturas. Consulte [REVISAO_MODELO.md](docs/REVISAO_MODELO.md). Os testes e as pendências técnicas do aplicativo não foram reavaliados por esta edição documental.

# MIAR — auditoria da MASTER de 10/11/2026



Fonte: [PDF MASTER](docs/LabES_SistemaMIAR_1011.pdf). As 46 páginas originais estão preservadas por texto e renderização. O apêndice autorizado em 11/11 contém 63 capturas reais; metadados em docs/master-apendice.json. O responsável determinou: DER da página 25 para persistência; requisitos para comportamento.



| Referência | Divergência interna | Tratamento |

|---|---|---|

| p. 25 × pp. 30–34 | Dicionário acrescenta espécie, porte e saúde na ocorrência, cidade na localização, contato público em CONTATO e duplica data_upload | Atributos do DER; saúde preservada em descricao e contato calculado pelo status |

| p. 25 × pp. 20, 36, 39 e 46 | Textos ainda mencionam especialização CIDADAO/PROTETOR/ONG | Documento/perfil centralizados em USUARIO; sem campos de instituição/fantasia |

| p. 25 × pp. 17–18 e 45 | CORRESPONDENCIA_IA ausente do DER, mas registro e aviso continuam exigidos | RF05/RF06 mantidos com estado técnico protegido, sem décima tabela |

| p. 25 × pp. 16 e 23 | MENSAGEM_WHATSAPP no DER; CU10 exclui registro de conversas internas | Tabela preservada; sem chat, captura ou envio automático |

| p. 25 × p. 34 | CONTATO 0..N no DER; dicionário afirma 1:1 | FK não única por ocorrência |

| p. 25 × pp. 30 e 33 | DER usa date; dicionário também usa datetime | date no banco |

| p. 36 | Observações negam entidades Animal/MensagemWhatsapp presentes no DER atual | A imagem corrigida prevalece |

| pp. 4 e 20 | RNF01 cita computadores; plataforma técnica exclui web/desktop | Interface móvel adaptável, sem plataforma adicional |

| pp. 3 e 15 | RF04 geral; CU09 associa radar a protetor/ONG | Associação específica do CU09 |



## Verificação da adaptação



O novo schema contém as nove entidades e seus atributos. Cadastro/perfil usam USUARIO.documento. Ocorrência se vincula a ANIMAL/ESPECIE e localização a CIDADE. FOTO/CONTATO refletem o DER. Os campos opcionais de Animal sem entrada prevista nas telas ficam sem valor; não são preenchidos com dados fictícios.



A migração preserva IDs, credenciais, registros, fotos e contatos. Saúde e resultados de análise anteriores são transferidos. Dados antigos sem campo de destino permanecem no backup completo. Datas passam para date conforme o DER; o backup preserva os horários originais.



Testes atuais verificam colunas, tipos, PKs, FKs, cardinalidades, fluxos, migração com dados, restauração e rollback. Estado final dos testes, capturas e limites em docs/IMPLEMENTACAO.md. Não usar as evidências antigas para afirmar conformidade com a MASTER.

