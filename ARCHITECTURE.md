# MIAR — arquitetura atual

Fonte: [PDF MASTER](docs/LabES_SistemaMIAR_1011.pdf), páginas 19–23. Este arquivo descreve a implementação, sem criar requisitos.

- app/: Flutter/Dart, Android 8+ e alvo iOS 13+, com apresentação, domínio e dados. Nove janelas das páginas 38–46.
- api/: NestJS/TypeScript, nos sete módulos previstos: autenticação, usuários, ocorrências, localizações, fotos, contatos e correspondências.
- ia/: Python/FastAPI, descritores reais MobileNetV3 e comparação por cosseno.
- PostgreSQL 16: nove tabelas do DER. PostGIS/pgvector previstos nos containers; o ambiente portátil não contém essas extensões.
- Fotografias em armazenamento compatível com S3; senhas Argon2id; token protegido no aparelho e revogável no servidor.
- Integrações: GPS, câmera/galeria, mapa, notificações do sistema e abertura de link WhatsApp.
- Estado técnico da análise em arquivos protegidos, por banco e origem, sem décima tabela. Volumes correspondentes em compose.yaml.

O escopo técnico da página 20 não prevê versão web/desktop. Interface móvel responsiva e tablet, sem criar plataforma adicional.

Não confundir configuração com verificação: iOS exige macOS/Xcode e os containers exigem Docker. Execução e limites em README.md; decisões em docs/IMPLEMENTACAO.md.
