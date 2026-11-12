# MIAR: implementação da MASTER

Fonte atual: [PDF MASTER](LabES_SistemaMIAR_1011.pdf), com [Word editável](LabES_SistemaMIAR_MASTER.docx). Os hashes estão em MASTER.json. A revisão acadêmica de 11/11/2026 segue o modelo da professora, sem apêndice de capturas. Consulte REVISAO_MODELO.md.

Precedência confirmada pelo responsável: DER corrigido da seção 1.3.2 para persistência; requisitos e casos de uso da seção 1.1 para comportamento; nove protótipos da seção 1.4 para interface. O DER é o mesmo que estava na página 25 do PDF recebido em 10/11/2026.

As referências de páginas abaixo registram a paginação do PDF original, antes da revisão de formato. A implementação e o APK não foram alterados nesta revisão documental.

## Alterações decorrentes do DER



- Nove tabelas: USUARIO, ESPECIE, ANIMAL, OCORRENCIA_ANIMAL, CIDADE, LOCALIZACAC, FOTO, CONTATO e MENSAGEM_WHATSAPP.

- Documento centralizado em USUARIO; os três perfis continuam os mesmos do RD01. Cadastro e perfil não incluem instituição/nome fantasia do modelo antigo.

- Espécie e porte projetados de ANIMAL/ESPECIE, cidade e UF de CIDADE; a API apresenta esses dados nas mesmas janelas.

- Porte segue Pequeno/Médio/Grande do diagrama de classes. UF é opcional, sem deduzir um estado para cidades antigas.

- Campos de Animal sem entrada prevista nos protótipos (nome, idade, gênero, cor) permanecem opcionais. Foto principal usa a primeira fotografia real.

- LOCALIZACAC mantém a grafia da imagem. Uma localização por ocorrência; vários contatos/fotos por ocorrência e várias mensagens por contato são permitidos pelo modelo.

- Datas do DER são date. Notificação e análise conservam sua data/hora no estado técnico.

- MENSAGEM_WHATSAPP é criada com seus atributos e FK, mas o aplicativo não registra conversas nem envia mensagens, conforme CU10 e p. 23.



## Compatibilidade entre requisitos e persistência



RF02 exige descrição física e estado aparente de saúde, mas o DER tem apenas descricao na ocorrência. Esse atributo text guarda uma representação JSON versionada com os dois valores. A descrição física também integra ANIMAL.descricao. A projeção da API devolve campos legíveis separados para a janela de detalhe e edição, sem acrescentar coluna.



RD06 é aplicado na consulta do servidor: para Adotado/Resgatado, a resposta não contém contato, link ou telefone. A disponibilidade é derivada de status_ocorrencia; não existe permite_contato_publico no modelo atual.



CU11/CU12 exigem registrar ocorrências relacionadas, resultado, data e situação do aviso, embora o DER não ofereça tabela correspondente. Esses resultados do processamento ficam em arquivos protegidos, separados por banco e ocorrência de origem, em CORRESPONDENCIAS_DIR (padrão .runtime/correspondencias). Isso é uma decisão técnica para cumprir os requisitos sem acrescentar entidade SQL. Os arquivos também precisam de persistência e backup; não são descartáveis.



Arquivos são publicados por substituição atômica e alterações concorrentes usam trava PostgreSQL por origem. Falha durante a transação compensa a gravação do resultado. A consulta confere se ambas as ocorrências ainda existem e se as assinaturas de espécie/fotografias ainda correspondem à análise. Banco e arquivos são dois mecanismos de persistência; não há transação distribuída. Uma interrupção abrupta entre gravações pode exigir reanálise/restauração. Não há declaração de tolerância a falhas de produção.



## Migração e preservação



Na inicialização, o modelo anterior é reconhecido por suas tabelas, bloqueado para outra migração concorrente e exportado em snapshot lógico REPEATABLE READ, com schema, dados, constraints, índices e SHA-256, antes de qualquer alteração. A transformação ocorre em transação; contagens são comparadas antes de retirar as tabelas antigas. Falha reverte o banco inteiro.



IDs, credenciais, documentos, ocorrências, coordenadas, fotografias, contatos e resultados de análise são preservados. Campos antigos sem destino no novo DER (instituição/nome fantasia) ficam no backup integral. Datas são convertidas para date; o backup retém os horários originais.



Snapshots privados em .runtime/backups; não incluem cópia concorrente da especificação. Restauração: api/scripts/restaurar-backup.mjs, somente em banco local vazio, verificando checksum e restaurando chaves/índices. Nenhum banco existente é apagado.



## Referências visuais e escopo



As nove imagens das páginas 38–46 são a referência de composição; estão extraídas em master-extraido/. Paleta Pastel Aurora, Outfit estática e marca oficial preservadas. Fotos de protótipos não são inseridas na galeria real.



Gerenciamento de registros próprios para qualquer perfil (p. 37); radar protetor/ONG conforme CU09. Sem telas adicionais, autenticação social, recuperação de senha, favoritos ou painel administrativo.



## Validação e limites

Auditoria concluída em 11/11/2026: **35 testes da API, 26 de widgets/domínio e um teste Python aprovados; análise estática limpa**. Inclui modelo/PK/FK/cardinalidades, migração e restauração, rollback, titularidade, seis status, filtragem, concorrência de fotos, recuperação de mapa e acessibilidade de campos. Consultas locais com 1.200 registros, 80 requisições e cinco simultâneas: máximo 67,34 ms.

Ensaio completo pela interface Android API35 aprovado, com os três perfis, fotografia da galeria e câmera, GPS, edição, seis status, radar, IA e exclusão. No Android8/API26, testes dedicados aprovaram GPS, compressão, sessão protegida, galeria/câmera, persistência de fotos, notificações negadas/permitidas e agendamento. Roteiro amplo do API26 interrompido na preparação do aplicativo de câmera; não é declarado aprovado. São emuladores, sem equivalência automática a aparelhos físicos/iOS.

O MASTER contém 63 imagens no apêndice e conserva suas 46 páginas originais. APK de desenvolvimento 1.0.0+3, assinatura verificada, instalado e aberto, API local 10.0.2.2:3000. Resultados e metadados em `../evidencias/auditoria-2026-11-11/` e `../entrega/versao.json`.

**Aderência integral não aprovada.** A comparação visual encontrou diferenças efetivas, listadas no [parecer](PARECER_DE_ENTREGA.md). iOS13+ está configurado, sem build/ensaio. PostGIS/pgvector não estão disponíveis no PostgreSQL portátil; containers não foram executados. HTTP local de desenvolvimento não comprova os protocolos seguros da p.23. A conclusão, a bibliografia e o dicionário foram revisados no documento atual; isso não elimina as pendências técnicas anteriores.

MobileNetV3/ImageNet usa pesos e descritores reais; percentual é similaridade de cosseno e não probabilidade calibrada de identidade. Não existe conjunto rotulado para afirmar precisão em animais individuais, nem critério quantitativo definido pelo PDF. Notificações dependem de permissão/agendamento do sistema e não garantem entrega imediata com app forçadamente encerrado. O link WhatsApp foi verificado sem enviar mensagens ou afirmar teste de uma conversa autenticada real.
