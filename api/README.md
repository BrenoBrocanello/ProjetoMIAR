# MIAR API

API NestJS da [especificação MASTER](../docs/LabES_SistemaMIAR_1011.pdf). Execução completa em [README da raiz](../README.md).

Os sete módulos são autenticação, usuários, ocorrências, localizações, fotos, contatos e correspondências. Banco em database/schema.sql, com as nove entidades do DER da página 25.

- POST /usuarios/cadastro; GET/PATCH /usuarios/me.
- POST /auth/login; POST /auth/logout.
- GET/POST /ocorrencias; GET /ocorrencias/minhas; GET /ocorrencias/eventos (SSE).
- GET /ocorrencias/:id; GET /ocorrencias/:id/editar; PUT/DELETE /ocorrencias/:id; PATCH /ocorrencias/:id/status.
- GET /localizacoes/radar; GET /mapa/:z/:x/:y.
- GET /fotos/:key; GET /contatos/:id.
- GET /correspondencias; GET /correspondencias/:id; POST /correspondencias/:id/notificacao-emitida.

Cadastro/perfil usam documento, sem subtipos físicos de usuário. Upload multipart contém dados (JSON) e fotos. A API projeta espécie/porte/cidade e saúde para as janelas; o contrato HTTP não acrescenta colunas ao DER.

Configuração privada em .env; não compartilhar credenciais ou .runtime. Resultados de IA e backups têm persistência própria: consultar ../docs/IMPLEMENTACAO.md.

npm run build e npm test verificam fluxos reais e migração/restauração com banco isolado. Nenhum teste acessa banco remoto.
