# Revisão do documento conforme o modelo da professora

Em 11/11/2026, o responsável forneceu o modelo de Projeto de LabES e autorizou reorganizar o MASTER, retirar capturas desnecessárias, completar conclusão e bibliografia e corrigir a apresentação. Essa decisão substitui a solicitação anterior de incluir todas as capturas de testes no PDF.

Arquivos atuais: [PDF MASTER](LabES_SistemaMIAR_1011.pdf) e [Word editável](LabES_SistemaMIAR_MASTER.docx). São duas representações da mesma especificação.

## Organização

O documento mantém as seções e a ordem do modelo, de 1.1 a 1.6, o papel A5 e as quatro margens de 2 cm. A capa conserva os cinco integrantes, seus RAs, a professora e a instituição. Os ajustes de espaçamento acomodam os cinco autores sem criar uma segunda página de capa.

A seção 1.4 apresenta os nove protótipos aprovados, com descrição e legenda. As 63 capturas da auditoria foram retiradas do trabalho acadêmico e continuam em evidencias/auditoria-2026-11-11. Permanecem os três diagramas aprovados, sem alteração de pixels.

## Revisão de conteúdo

Foram preservados os identificadores dos 21 requisitos e dos 12 casos de uso. Vinte requisitos mantêm o texto recebido. O RNF01 foi ajustado para celulares e tablets, resolvendo sua contradição com a plataforma móvel, que já excluía web e desktop. O cenário normal do CU01 foi alinhado aos campos de cadastro do DER corrigido, sem tabelas de especialização de usuário.

O dicionário foi refeito a partir das nove entidades e dos 50 atributos do DER. A grafia LOCALIZACAC foi mantida para corresponder ao diagrama aprovado. A presença de MENSAGEM_WHATSAPP não autoriza chat interno ou envio automático. A conclusão descreve o trabalho realizado e as validações pendentes. A bibliografia reúne sete fontes primárias consultadas e citadas no texto.

O texto técnico distingue implementação local, plataformas previstas e recursos ainda não validados. Não foram acrescentadas funções de negócio ao aplicativo. Esta revisão documental não elimina as pendências de implementação registradas na auditoria anterior.

## Conferência

O PDF tem 45 páginas, sem páginas vazias, e o Word também foi paginado em 45 páginas pelo Microsoft Word. Foram conferidos os títulos e a ordem das seções, os cabeçalhos das três tabelas de requisitos e os nove rótulos de cada quadro de caso de uso contra o modelo. A fonte dos títulos é Calibri, com 14 pontos nas seções principais e 12 nos subtítulos. As legendas usam Calibri 12, em preto e sem negrito, conforme o modelo. O corpo usa Calibri 12 com espaçamento de 1,5 linha; os quadros recebem ajustes de tamanho para acomodar o conteúdo no papel A5.

A comparação do texto abrange todos os parágrafos e todas as células: o PDF contém o conteúdo do Word, desconsiderando apenas espaços e quebras de linha. As doze imagens do Word correspondem aos pixels das fontes. Foram verificados os limites das margens para texto e imagens, a integridade dos acentos, a ausência de campos provisórios, travessões e emojis no texto e os 50 atributos do dicionário. O corretor de português do Word apresentou somente candidatos associados a nomes próprios, identificadores e termos técnicos, revisados individualmente.

A revisão visual abrangeu todas as páginas renderizadas. Foram corrigidos trechos isolados, divisão inadequada de tabelas, separação entre títulos e figuras, vazamento dos diagramas na margem e a distribuição da conclusão e da bibliografia. O PDF foi exportado pelo LibreOffice 26.8.2.2; o Word foi aberto e repaginado no Microsoft Word 16.0.

PDF SHA-256: `176cdb5d0c834a41a00795bd0ffaa415f1453f4058205c499f295874cad6e4aa`.

Word SHA-256: `7a1daa5af997b9f91386a2552eb9fedff2da4204386dc457d7bb2343037855fd`.

## Histórico preservado

O PDF anterior de 82 páginas, SHA-256 `8df799ce277593a416a75e4edf56be663590f825b759630ef24a0b3614cb62b0`, permanece fora da pasta do projeto em `C:\Users\Breno\AppData\Local\MiarDev\376eb84567\documentacao\fontes-preservadas\MIAR-antes-modelo-8df799ce2775.pdf`. O original recebido em Downloads não foi alterado. Os relatórios de testes anteriores continuam associados aos arquivos e às condições avaliadas naquela ocasião.

Para reproduzir a preparação, executar gerar-master-modelo.py, exportar-master-modelo.ps1, conferir-master-modelo.py e, após revisar as renderizações, publicar-master-modelo.py, todos em scripts/. O modelo original e as fontes de imagem precisam estar nos caminhos registrados nesses scripts. Os scripts antigos de apêndice e encerramento da auditoria recusam sobrescrever esta revisão acadêmica.
