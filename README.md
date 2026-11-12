<p align="center">
  <img src="app/assets/img/miar-icon.png" alt="MIAR" width="140">
</p>

<h1 align="center">MIAR</h1>

<p align="center">
  Aplicativo móvel para registrar animais perdidos, encontrados, em emergência ou para adoção,<br>
  com galeria, mapa, comparação de fotos por IA e contato via WhatsApp.
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.38.9-02569B?logo=flutter">
  <img alt="NestJS" src="https://img.shields.io/badge/API-NestJS-E0234E?logo=nestjs">
  <img alt="PostgreSQL" src="https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql">
  <img alt="Python" src="https://img.shields.io/badge/IA-FastAPI%20%2B%20MobileNetV3-3776AB?logo=python">
  <img alt="Plataforma" src="https://img.shields.io/badge/testado%20em-Windows%20%2B%20Android-3DDC84?logo=android">
</p>

---

## Sumário

- [Como o projeto funciona](#como-o-projeto-funciona)
- [Antes de começar](#antes-de-começar)
- [Caminho A — testar rápido com o APK pronto](#caminho-a--testar-rápido-com-o-apk-pronto-recomendado)
- [Caminho B — compilar o app com Flutter](#caminho-b--compilar-o-app-com-flutter)
- [Testar em um celular de verdade](#testar-em-um-celular-de-verdade)
- [Roteiro de teste sugerido](#roteiro-de-teste-sugerido)
- [Problemas comuns](#problemas-comuns)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Documentação e limitações conhecidas](#documentação-e-limitações-conhecidas)
- [Para quem for mexer no código](#para-quem-for-mexer-no-código)

---

## Como o projeto funciona

O MIAR tem **duas partes**, e as duas precisam estar rodando para o app funcionar:

```
┌──────────────────────┐         HTTP          ┌──────────────────────────────────────────┐
│  App Android         │  ───────────────────▶ │  Servidor local (no seu computador)      │
│  (emulador ou        │     porta 3000        │  • API NestJS ............ porta 3000    │
│   celular)           │                       │  • PostgreSQL 16 ......... porta 55432   │
└──────────────────────┘                       │  • Armazenamento de fotos  porta 9000    │
                                               │  • IA de imagens (Python)  porta 8001    │
                                               └──────────────────────────────────────────┘
```

- O **servidor** sobe com um único script (`INICIAR-MIAR.cmd`). Banco de dados e armazenamento de fotos são instalados automaticamente via npm — **não é preciso instalar PostgreSQL nem Docker**.
- O **app** pode ser o APK pronto (Caminho A) ou compilado por você com Flutter (Caminho B).
- O banco começa **vazio**: não há contas nem animais de exemplo. Você cria tudo pelo próprio app.

> **Sistema operacional:** os scripts foram feitos e testados no **Windows 10/11**. Em macOS/Linux os scripts `.cmd`/`.ps1` não funcionam diretamente e esse caminho não foi validado.

---

## Antes de começar

### 1. Instale os programas

| Programa | Versão | Para quê | Necessário em |
|---|---|---|---|
| [Git](https://git-scm.com/download/win) | qualquer recente | baixar o projeto | A e B |
| [Node.js](https://nodejs.org/) | **20 LTS ou mais novo** | API, banco e armazenamento | A e B |
| [Python](https://www.python.org/downloads/) | **3.12** | serviço de IA e supervisor | A e B |
| [Android Studio](https://developer.android.com/studio) | recente | emulador Android | A e B |
| [Flutter](https://docs.flutter.dev/) | **3.38.9** (exatamente) | compilar o app | só B |
| Java (JDK) | 17 a 24 | compilar o app Android | só B |

Ao instalar o **Python**, marque a opção **"Add python.exe to PATH"**. Depois, confira num terminal novo:

```powershell
git --version
node --version     # deve mostrar v20 ou maior
python --version   # deve mostrar Python 3.12.x
```

### 2. Baixe o projeto

Clone em uma pasta **com caminho curto e sem acentos ou espaços** (ex.: `C:\dev`). Isso evita problemas com ferramentas do Android/Flutter.

```powershell
mkdir C:\dev -Force
cd C:\dev
git clone https://github.com/BrenoBrocanello/ProjetoMIAR.git
cd ProjetoMIAR
```

### 3. Crie um emulador Android

1. Abra o **Android Studio** → **More Actions** → **Virtual Device Manager**.
2. Clique em **Create Virtual Device**, escolha um celular (ex.: *Pixel 7*) e uma imagem de sistema **API 35** (*x86_64*, com Google APIs).
3. Finalize e clique em ▶ para ligar o emulador. Deixe-o aberto.

---

## Caminho A — testar rápido com o APK pronto (recomendado)

Não precisa instalar Flutter nem Java. Leva uns 15–30 minutos na primeira vez (a maior parte é download).

### Passo 1 — Inicie o servidor

Na pasta do projeto, dê **dois cliques em `INICIAR-MIAR.cmd`** (ou rode no PowerShell):

```powershell
.\INICIAR-MIAR.cmd
```

Na **primeira vez** o script:

- instala as dependências da API (`npm ci`);
- cria um ambiente Python em `ia/.venv` e instala o PyTorch (CPU) — **é um download grande, pode demorar vários minutos**;
- gera o arquivo `api/.env` com senhas aleatórias só para a sua máquina;
- baixa os pesos públicos da rede neural MobileNetV3 (sem chave de API, sem custo).

Espere aparecer:

```
MIAR iniciado. API: http://localhost:3000
```

Nas próximas vezes, a inicialização leva menos de um minuto. Se o Windows perguntar sobre o **Firewall**, permita o acesso em redes privadas.

### Passo 2 — Baixe o APK

Baixe o arquivo **`MIAR-android.apk`** na página de [**Releases**](https://github.com/BrenoBrocanello/ProjetoMIAR/releases/latest) do repositório (link direto: [MIAR-android.apk](https://github.com/BrenoBrocanello/ProjetoMIAR/releases/latest/download/MIAR-android.apk)).

> Esse APK é uma versão de **desenvolvimento (debug)** configurada para conversar com o servidor pelo endereço `10.0.2.2:3000`, que é o "localhost do computador" visto de dentro do **emulador**. Por isso ele **só funciona no emulador**. Para celular físico, veja [esta seção](#testar-em-um-celular-de-verdade).

### Passo 3 — Instale no emulador

Com o emulador ligado, **arraste o arquivo `.apk` para cima da janela do emulador**. Ele instala sozinho e o ícone do MIAR aparece na lista de apps.

Alternativa pelo terminal (o `adb` vem com o Android Studio):

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r "$env:USERPROFILE\Downloads\MIAR-android.apk"
```

### Passo 4 — Use o app

Abra o MIAR no emulador, toque em **Criar conta** e siga o [roteiro de teste](#roteiro-de-teste-sugerido).

### Passo 5 — Encerre

Quando terminar, dê dois cliques em **`PARAR-MIAR.cmd`**. Os dados (contas, ocorrências, fotos) **ficam salvos** para a próxima vez.

---

## Caminho B — compilar o app com Flutter

Use este caminho se quiser alterar o código do app ou gerar um APK para celular físico.

### Passo 1 — Instale o Flutter 3.38.9 no local esperado

O projeto fixa o Flutter **3.38.9** (arquivo `app/.fvmrc`) para preservar compatibilidade com iOS 13. Os scripts procuram o Flutter neste caminho exato, sem mexer em outro Flutter que você já tenha:

```powershell
git clone --depth 1 --branch 3.38.9 https://github.com/flutter/flutter.git "$env:LOCALAPPDATA\MiarDev\flutter-3.38.9"
& "$env:LOCALAPPDATA\MiarDev\flutter-3.38.9\bin\flutter.bat" --version
& "$env:LOCALAPPDATA\MiarDev\flutter-3.38.9\bin\flutter.bat" doctor
```

Resolva o que o `flutter doctor` apontar na seção **Android toolchain** (geralmente: aceitar licenças com `flutter doctor --android-licenses`). Verifique também que `java -version` mostra uma versão entre 17 e 24.

> ⚠️ Não rode `flutter pub upgrade` nem use outra versão do Flutter: isso pode quebrar a compatibilidade definida no projeto.

### Passo 2 — Inicie o servidor

Igual ao Caminho A: `INICIAR-MIAR.cmd` e espere `MIAR iniciado`.

### Passo 3 — Rode o app no emulador

Com o emulador ligado, descubra o identificador dele:

```powershell
& "$env:LOCALAPPDATA\MiarDev\flutter-3.38.9\bin\flutter.bat" devices
```

E execute (troque `emulator-5554` pelo identificador que apareceu):

```powershell
.\EXECUTAR-APP.cmd -Dispositivo emulator-5554
```

A primeira compilação demora alguns minutos. O script compila uma **cópia** do app em `%LOCALAPPDATA%\MiarDev\` (o compilador de shaders do Flutter falha em caminhos com acentos); o código que você edita continua em `app/`.

### Gerar o APK

```powershell
.\GERAR-APK.cmd
```

O arquivo sai em `entrega\MIAR-android.apk` (APKs não são versionados no git; ficam só na sua máquina).

---

## Testar em um celular de verdade

O celular precisa alcançar o servidor que está no seu computador:

1. Coloque **computador e celular na mesma rede Wi-Fi**.
2. Descubra o IP do computador: rode `ipconfig` e anote o **Endereço IPv4** do adaptador Wi-Fi (ex.: `192.168.0.15`).
3. Libere a **porta 3000** no Firewall do Windows para redes privadas (o script não altera o firewall). Exemplo, em um PowerShell **como administrador**:
   ```powershell
   New-NetFirewallRule -DisplayName "MIAR API 3000" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow -Profile Private
   ```
4. Gere um APK apontando para esse IP (exige o [Caminho B](#caminho-b--compilar-o-app-com-flutter)):
   ```powershell
   .\GERAR-APK.cmd -ApiUrl http://192.168.0.15:3000
   ```
5. Copie `entrega\MIAR-android.apk` para o celular e instale (o Android vai pedir para permitir "instalar apps desconhecidos").

Teste antes no navegador do celular: abrir `http://192.168.0.15:3000` deve dar alguma resposta da API (mesmo que seja um erro em JSON). Se não carregar, o problema é rede/firewall, não o app.

> Redes de faculdade e redes públicas costumam bloquear a comunicação entre aparelhos. Se não funcionar, use o roteador de casa ou o roteamento do próprio celular.

---

## Roteiro de teste sugerido

O app tem **três perfis** de usuário e **seis status** de ocorrência:

| Perfis | Status de ocorrência |
|---|---|
| Cidadão | Perdido · Encontrado · Emergência |
| Protetor independente | Aguardando Adoção · Adotado · Resgatado |
| ONG | |

Siga os passos abaixo para passar pelas principais funcionalidades:

1. **Cadastro e login** — crie uma conta como **Cidadão** (o telefone deve ser brasileiro, com DDD). Saia e entre de novo.
2. **Registrar ocorrência** — cadastre um animal com status **Perdido**: tire uma foto ou escolha da galeria, permita o acesso à localização, preencha espécie, porte, descrição, cidade/UF e o WhatsApp de contato.
   > No emulador, a câmera é simulada. Para usar fotos reais, arraste imagens para a janela do emulador (elas vão para a pasta *Downloads*) e escolha **"Escolher da galeria"**.
3. **Galeria e filtros** — veja a ocorrência na galeria e teste os filtros por status, espécie, porte e cidade.
4. **Detalhe e WhatsApp** — abra a ocorrência e toque no contato: o app abre um link do WhatsApp com o número cadastrado (no emulador, sem WhatsApp instalado, ele tenta abrir no navegador).
5. **Mapa (radar)** — crie uma segunda conta como **Protetor independente** ou **ONG**. Esses perfis têm acesso ao mapa (OpenStreetMap) com os marcadores das ocorrências. O perfil Cidadão não vê o mapa.
6. **Comparação por IA** — com a segunda conta, registre um animal **Encontrado**, **da mesma espécie**, usando uma foto do mesmo animal (ou uma muito parecida) da ocorrência Perdida. Ao salvar, o serviço de IA compara as fotos com as das ocorrências Perdidas daquela espécie e, se a similaridade passar do limite, o dono da ocorrência Perdida recebe um **aviso** e pode abrir a tela de correspondência.
7. **Gerenciar ocorrências** — edite, mude o status ou exclua suas ocorrências. Cada pessoa só altera os próprios registros.
8. **Contato encerrado** — mude uma ocorrência para **Adotado** ou **Resgatado**: o telefone deixa de aparecer publicamente.
9. **Perfil** — altere seus dados e faça logout.

Dica: para simular dois usuários ao mesmo tempo, faça login com uma conta, teste, saia e entre com a outra — ou use dois emuladores.

---

## Problemas comuns

| Sintoma | O que fazer |
|---|---|
| `python` não é reconhecido | Reinstale o Python 3.12 marcando **"Add python.exe to PATH"** e abra um terminal novo. |
| `npm` / `node` não é reconhecido | Instale o Node.js LTS e abra um terminal novo. |
| `INICIAR-MIAR` demora muito na primeira vez | Normal: o PyTorch e o modelo de IA são downloads grandes. Aguarde. |
| "Tempo excedido ao iniciar serviços" ou "Os serviços não iniciaram" | Veja os logs em `.runtime\` (principalmente `servicos-erro.log`). Rode `PARAR-MIAR.cmd` e tente de novo. |
| Erro de porta em uso | Algo já está usando a porta 3000, 8001, 9000 ou 55432. Feche o programa ou reinicie o computador. |
| App mostra erro de conexão | Confira se o servidor está rodando (abra `http://localhost:3000` no navegador do PC). No celular físico, veja [a seção específica](#testar-em-um-celular-de-verdade). |
| Instalação das dependências falhou no meio | Rode `.\iniciar-miar.ps1 -Preparar` no PowerShell para reinstalar tudo. |
| "Instale Flutter 3.38.9 via FVM..." ao rodar o app | O Flutter não está em `%LOCALAPPDATA%\MiarDev\flutter-3.38.9`. Veja o [Caminho B, passo 1](#passo-1--instale-o-flutter-3389-no-local-esperado). |
| PowerShell bloqueia a execução de scripts | Use os arquivos `.cmd` (eles já liberam a execução só para o script) em vez dos `.ps1`. |
| Notificação de correspondência não aparece | Permita notificações para o MIAR nas configurações do Android. Avisos em segundo plano dependem do sistema e podem atrasar; o aviso continua consultável no app. |

---

## Estrutura do repositório

```
ProjetoMIAR/
├── app/             App Flutter (Android/iOS) — telas em app/lib/presentation
├── api/             API NestJS + scripts do banco/armazenamento locais e testes
├── ia/              Serviço Python/FastAPI de análise de imagens (MobileNetV3)
├── infra/           Dockerfiles do banco (PostGIS + pgvector) e do armazenamento S3
├── docs/            Especificação MASTER (PDF e Word) e documentos técnicos
├── prototipos/      Os nove protótipos de interface (HTML + imagens)
├── evidencias/      Registros históricos de testes e auditoria
├── scripts/         Supervisor dos serviços e scripts de validação
├── INICIAR-MIAR.cmd     Sobe banco, armazenamento, IA e API
├── PARAR-MIAR.cmd       Encerra tudo sem apagar os dados
├── EXECUTAR-APP.cmd     Compila e roda o app (Caminho B)
├── GERAR-APK.cmd        Gera o APK em entrega/ (Caminho B)
└── compose.yaml         Alternativa com Docker (não validada)
```

---

## Documentação e limitações conhecidas

- **Especificação MASTER:** [PDF](docs/LabES_SistemaMIAR_1011.pdf) e [Word editável](docs/LabES_SistemaMIAR_MASTER.docx), no modelo de LabES. O DER da seção 1.3.2 governa o banco; requisitos e casos de uso da seção 1.1 governam o comportamento; a seção 1.4 traz os nove protótipos.
- Documentos técnicos: [modelo de dados](DATABASE.md), [implementação](docs/IMPLEMENTACAO.md), [arquitetura](ARCHITECTURE.md), [design system](DESIGN_SYSTEM.md), [matriz de rastreabilidade](MATRIZ_RASTREABILIDADE.md), [revisão do documento](docs/REVISAO_MODELO.md).
- Histórico de auditoria: [parecer de entrega](docs/PARECER_DE_ENTREGA.md) e [auditoria de conformidade](AUDITORIA_CONFORMIDADE.md).

**Situação atual (11/11/2026):** a versão Android local foi demonstrada (Android API 35 e API 26), mas a **aderência integral do app à especificação ainda não foi aprovada**. Pendências registradas: diferenças visuais em relação aos protótipos, iOS sem build, extensões PostGIS/pgvector no ambiente portátil e HTTPS/TLS. Nada foi publicado em lojas ou servidores.

**Sobre a IA:** usa pesos reais pré-treinados do MobileNetV3 (ImageNet). O percentual mostrado é **similaridade visual, não a probabilidade de ser o mesmo animal**. O limite inicial de 0,90 (`MATCH_THRESHOLD`) é técnico; não há métricas de precisão medidas com um conjunto de animais rotulado. Não existe confirmação automática de identidade.

**Sobre os avisos:** são notificações do próprio sistema operacional. Com o app aberto, chegam quando há atualização; em segundo plano, o Android pode atrasar ou impedir a verificação periódica. Não há push instantâneo com o app fechado. O estado `Emitida` significa que o sistema aceitou a notificação, não que foi lida.

### Funcionalidades implementadas

- **RF01** — cadastro dos três perfis, login, consulta/alteração dos próprios dados e logout com revogação no servidor.
- **RF02/RF08** — fotos de câmera/galeria com compressão, GPS, cadastro, consulta, edição, exclusão e os seis status; cada perfil gerencia apenas os próprios registros.
- **RF03** — galeria paginada com filtros por status, espécie, porte e cidade.
- **RF04** — mapa OpenStreetMap com marcadores e resumo da ocorrência (perfis Protetor e ONG, conforme CU09).
- **RF05/RD07** — extração de descritores MobileNetV3 e comparação com fotos de ocorrências perdidas.
- **RF06** — avisos do sistema, tela de correspondência e situação da notificação persistida.
- **RF07/RD06** — link do WhatsApp com telefone brasileiro validado; telefone oculto publicamente para Adotado/Resgatado. Não há chat interno nem envio automático de mensagens (CU10).
- Atualizações em tempo real por eventos SSE autenticados, com reconexão.

---

## Para quem for mexer no código

Antes de alterar o app, leia [DATABASE.md](DATABASE.md), [docs/IMPLEMENTACAO.md](docs/IMPLEMENTACAO.md) e [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md). Não altere cores/identidade visual da marca nem acrescente telas, perfis, entidades ou fluxos que não estejam na especificação.

### Testes da API

Com o servidor iniciado ao menos uma vez (dependências instaladas):

```powershell
cd api
npm.cmd run build
npm.cmd test
```

Os testes usam um banco separado (`miar_test`), uma API na porta 3301 e outra com IA indisponível na 3302 — **não tocam nos seus dados**. Cobrem autenticação, titularidade, integridade das nove entidades, upload inválido, comparação positiva/negativa, filtros, contato encerrado, erro de IA e revogação de sessão.

### Testes do app

Na pasta `app`, com o Flutter 3.38.9:

```powershell
& "$env:LOCALAPPDATA\MiarDev\flutter-3.38.9\bin\flutter.bat" analyze
& "$env:LOCALAPPDATA\MiarDev\flutter-3.38.9\bin\flutter.bat" test
```

Teste de integração Android das nove telas (rodar na cópia de compilação sem acentos, em `%LOCALAPPDATA%\MiarDev\<id>\app`):

```powershell
# Terminal 1, na pasta api:
node scripts/servidor-teste.mjs
# Terminal 2, na cópia de compilação do app:
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/fluxo_real_test.dart -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:3301
```

### Testes da IA

```powershell
cd ia
.venv\Scripts\python.exe -m pytest
```

### Dados e backup

Os dados locais ficam em `%LOCALAPPDATA%\MiarDev\<identificador-do-projeto>\` (o PostgreSQL não aceita acentos no caminho no Windows). `PARAR-MIAR.cmd` preserva os dados. A API faz migração automática com snapshot e checksum; para restaurar um backup em banco vazio, use `api/scripts/restaurar-backup.mjs`. Nenhum script apaga um banco existente.

### iOS

Exige macOS com Xcode e não foi compilado nem validado:

```sh
cd app
fvm flutter pub get
fvm flutter build ios --no-codesign --dart-define=API_URL=https://SUA-API
```

### Docker (alternativa não validada)

`compose.yaml` descreve a mesma aplicação com PostgreSQL 16 + PostGIS + pgvector, armazenamento S3 e IA. Copie `.env.example` para `.env` na raiz, preencha com valores aleatórios e rode `docker compose up --build`. Apenas a API (porta 3000) é exposta. Essa configuração ainda não foi testada em uma máquina com Docker.

> ⚠️ Os scripts antigos de apêndice e de encerramento de auditoria em `scripts/` são registros históricos e **não devem ser executados** contra a revisão acadêmica atual.
