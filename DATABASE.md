# MIAR — modelo de dados MASTER

Fonte: [PDF MASTER, página 25](docs/LabES_SistemaMIAR_1011.pdf#page=25). O responsável confirmou a precedência do DER sobre o dicionário em 10/11/2026.

| Entidade | Atributos no DER |
|---|---|
| USUARIO | id_usuario (PK, int), nome, email, senha, telefone, documento, tipo_usuario (string), ativo (boolean) |
| ESPECIE | id_especie (PK, int), nome (string) |
| ANIMAL | id_animal (PK, int), id_especie (FK, int), nome, porte, descricao, idade, genero, cor, url_foto (string), data_cadastro (date) |
| OCORRENCIA_ANIMAL | id_ocorrencia (PK, int), id_usuario_responsavel (FK, int), id_animal (FK, int), status_ocorrencia, descricao (string), data_registro (date) |
| CIDADE | id_cidade (PK, int), nome, estado (string) |
| LOCALIZACAC | id_localizacao (PK, int), id_ocorrencia (FK, int), id_cidade (FK, int), latitude, longitude (double), endereco (string) |
| FOTO | id_foto (PK, int), id_ocorrencia (FK, int), url_storage, descricao (string), data_upload (date) |
| CONTATO | id_contato (PK, int), id_ocorrencia (FK, int), numero_whatsapp, whatsapp_link (string), data_contato (date) |
| MENSAGEM_WHATSAPP | id_mensagem (PK, int), id_contato (FK, int), texto, remetente (string), data_envio (date) |

USUARIO, ESPECIE, ANIMAL e CIDADE possuem relações 1 : 0..N com seus dependentes. OCORRENCIA_ANIMAL possui 0..1 LOCALIZACAC, 0..N FOTO e 0..N CONTATO. CONTATO possui 0..N MENSAGEM_WHATSAPP. O cadastro exige localização e foto por RD03/CU05; a FK de CONTATO não é única.

LOCALIZACAC preserva a grafia da imagem aprovada. Tipos físicos: integer, text, double precision, boolean e date. Não existem as tabelas de especialização do modelo anterior. O documento fica em USUARIO; a espécie/porte vêm de ANIMAL/ESPECIE; cidade/UF vêm de CIDADE.

Definição executável: api/database/schema.sql. Contrato de conferência independente: api/database/schema-master.json. A API fornece projeções próprias de consulta sem acrescentar colunas ao DER.

Saúde é preservada na descrição da ocorrência; contato público é calculado pelo status; resultados de IA e avisos possuem estado técnico em arquivos protegidos. Detalhes e limites em docs/IMPLEMENTACAO.md.

Migração automática com snapshot lógico, checksum, transação e conferência de contagens. Backup inclui também os campos antigos que não têm destino no DER atual. Restauração em banco local vazio pelo script api/scripts/restaurar-backup.mjs; nenhum banco existente é apagado.
