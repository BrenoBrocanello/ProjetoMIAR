# MIAR Design System — Pastel Aurora

**Documento oficial e obrigatório de identidade visual do projeto MIAR**
Sistema de Mapeamento e Identificação de Animais de Risco
FATEC Jundiaí "Dep. Ary Fossen" — CST em Análise e Desenvolvimento de Sistemas · v1.0

---

## 0. Status deste documento

Este arquivo descreve os tokens de apoio visual do MIAR. A referência MASTER é
`docs/LabES_SistemaMIAR_1011.pdf`, especialmente as nove janelas das páginas 38–46.
Em qualquer divergência, as referências visuais da MASTER prevalecem sobre este arquivo.

> **Escopo estritamente visual.** Este documento define *como as coisas se parecem*.
> Ele **não cria, não autoriza e não justifica funcionalidades**. O comportamento do sistema é
> definido exclusivamente pelos Requisitos Funcionais, Não Funcionais, de Domínio, Diagrama de
> Casos de Uso, Diagrama de Classes e DER do documento acadêmico. Em conflito,
> **a documentação funcional prevalece**.

A imagem `referencias/Tela de Login para Resgate Animal.png` é o **alvo de design**: dela se
extrai linguagem visual (cor, forma, tipografia, composição) — **nunca funcionalidade**.
Elementos funcionais presentes nessa imagem que não tenham respaldo documental estão registrados
como pendência em `AUDITORIA_CONFORMIDADE.md` e **não** foram implementados.

---

## 1. Identidade visual

### 1.1. Estilos obrigatórios

A interface do MIAR é a combinação — e **somente** a combinação — destes seis estilos:

| Estilo | Como se manifesta no MIAR |
|---|---|
| **Pastel Gradient Minimalism** | Fundos em degradê pastel contínuo; pouquíssimos elementos por tela |
| **Aurora Gradient Design** | Manchas de cor orgânicas, difusas e sobrepostas, como uma aurora boreal |
| **Modern SaaS UI** | Hierarquia tipográfica clara, cards, espaçamento generoso, estados bem definidos |
| **Soft UI** | Superfícies claras levemente elevadas, sombras difusas, nada de relevo exagerado |
| **Neo-Minimalism** | Ausência de ornamento; cada elemento tem função |
| **Geometric Sans-Serif Typography** | Tipografia geométrica de peso alto para títulos |

### 1.2. Sensação de marca

Moderno · simples · acessível · acolhedor · confiável · premium.

O MIAR trata de animais em situação de risco. A interface deve ser **leve e esperançosa**,
nunca alarmista — mesmo em emergências, a sinalização é feita por cor e rótulo,
jamais por estética agressiva.

### 1.3. Proibições absolutas

É expressamente **proibido** na interface do MIAR:

- Material Design padrão sem personalização
- Bootstrap com aparência genérica
- Neumorfismo excessivo (relevo escavado/estampado)
- Glassmorphism exagerado (desfoque pesado, bordas de vidro espelhadas)
- Gradientes neon ou cores fluorescentes
- Estética cyberpunk
- Estética corporativa tradicional (azul-marinho + cinza + cantos retos)
- Sombras fortes, duras ou com deslocamento visível
- Bordas quadradas predominantes
- Fontes serifadas, manuscritas ou decorativas
- Qualquer elemento visual incompatível com a identidade aqui definida

---

## 2. Tokens de cor

### 2.1. Paleta base

| Token | Hex | Uso |
|---|---|---|
| `miar.blue` | `#8AB8FF` | Aurora, gradiente primário (início) |
| `miar.lilac` | `#B9A1FF` | Aurora, bordas secundárias, divisores |
| `miar.pink` | `#F2B5EB` | Aurora, gradiente primário (meio) |
| `miar.mint` | `#A4F4D4` | Aurora, gradiente primário (fim), sucesso |
| `miar.purple` | `#7C3AED` | Cor de ação: links, botão secundário, ênfase |
| `miar.ink` | `#180825` | Títulos e texto de alta ênfase |
| `miar.white` | `#FFFFFF` | Superfícies, texto sobre gradiente |
| `miar.lavenderGray` | `#77789C` | Texto secundário, placeholders, ícones inativos |

**Nenhuma outra cor cromática** pode ser introduzida sem autorização explícita do responsável
pelo projeto, com a única exceção das cores semânticas da seção 2.3.

### 2.2. Tokens derivados

Derivados por opacidade sobre as cores base — nunca por valores arbitrários novos.

| Token | Valor | Uso |
|---|---|---|
| `surface.primary` | `#FFFFFF` a 92% | Card principal, folha de conteúdo |
| `surface.secondary` | `#FFFFFF` a 72% | Cards internos, inputs, chips |
| `surface.sunken` | `#FFFFFF` a 55% | Áreas de fundo dentro de um card |
| `border.subtle` | `#180825` a 8% | Borda padrão de input e card |
| `border.focus` | `#7C3AED` a 45% | Borda de campo em foco |
| `border.secondaryAction` | `#B9A1FF` | Borda do botão secundário |
| `text.primary` | `#180825` | Títulos, valores, rótulos |
| `text.secondary` | `#77789C` | Apoio, legendas, placeholders |
| `text.onGradient` | `#FFFFFF` | Texto sobre botão primário |
| `overlay.scrim` | `#180825` a 32% | Fundo de modal e bottom sheet |

### 2.3. Cores semânticas

Usadas **exclusivamente** para comunicar estado do sistema, derivadas da paleta pastel.

| Token | Texto / Fundo | Uso |
|---|---|---|
| `semantic.success` | `#2F9E78` sobre `#A4F4D4` 35% | Confirmações; status *Adotado* / *Resgatado* |
| `semantic.info` | `#3B6FD4` sobre `#8AB8FF` 35% | Avisos neutros; status *Encontrado* |
| `semantic.warning` | `#9A6A1F` sobre `#F7E2A8` 45% | Atenção; status *Aguardando Adoção* |
| `semantic.danger` | `#C2437A` sobre `#F2B5EB` 40% | Erros; status *Emergência* |
| `semantic.neutral` | `#77789C` sobre `#FFFFFF` 70% | Status *Perdido*; estados inertes |

### 2.4. Gradientes

Assinatura do MIAR. Sempre **diagonais**, **suaves e contínuos**, nunca com paradas abruptas.

```
gradient.aurora        135°: #8AB8FF 0% → #B9A1FF 38% → #F2B5EB 70% → #A4F4D4 100%
                       Uso: fundo de tela cheia

gradient.primaryAction 100°: #8AB8FF 0% → #B9A1FF 30% → #F2B5EB 62% → #A4F4D4 100%
                       Uso: botão primário, chip ativo, marcador de mapa

gradient.surfaceVeil   160°: #FFFFFF 94% → #FFFFFF 78%
                       Uso: folha branca translúcida sobre a aurora

gradient.headerFade    180°: transparente → #FFFFFF 85%
                       Uso: transição entre foto e conteúdo
```

### 2.5. Blobs de aurora

O fundo não é um degradê linear puro: recebe **manchas orgânicas** sobrepostas, como no alvo de design.

- 3 a 5 blobs por tela, nunca mais
- Forma: elipse irregular (`border-radius` assimétrico, ex.: `58% 42% 47% 53% / 43% 51% 49% 57%`)
- Uma cor da paleta por blob · Opacidade 28–45% · Desfoque `blur(48px)` a `blur(80px)`
- Nunca animados em loop; no máximo deslocamento lento de ±8px em transição de tela

---

## 3. Tipografia

### 3.1. Famílias

| Papel | Família | Fallback |
|---|---|---|
| Principal | **Outfit** | Satoshi → Poppins → system-ui → sans-serif |
| Alternativa aprovada | **Satoshi** | Outfit → Poppins |
| Fallback final | **Poppins** | sans-serif |

Nenhuma outra família é permitida. **Jamais serifadas, manuscritas ou decorativas.**

### 3.2. Escala tipográfica

| Token | Tamanho | Peso | Linha | Tracking | Uso |
|---|---|---|---|---|---|
| `display` | 34 | 700 | 1.15 | -0.6px | Título herói |
| `h1` | 28 | 700 | 1.20 | -0.4px | Título de tela |
| `h2` | 22 | 600 | 1.25 | -0.2px | Título de seção |
| `h3` | 18 | 600 | 1.30 | 0 | Título de card |
| `bodyLarge` | 16 | 400 | 1.55 | 0 | Texto corrido principal |
| `body` | 15 | 400 | 1.55 | 0 | Texto padrão |
| `label` | 14 | 600 | 1.30 | 0 | Rótulo de campo |
| `button` | 16 | 600 | 1.00 | 0.2px | Texto de botão |
| `caption` | 13 | 400 | 1.45 | 0 | Legenda, apoio |
| `overline` | 11 | 600 | 1.20 | 1.6px (maiúsculas) | Tagline, rótulo de grupo |

### 3.3. Regras de uso

- Títulos sempre em `text.primary`, peso 600–700, nunca em cor pastel
- Texto secundário sempre em `text.secondary`, peso 400
- Máximo **dois** níveis hierárquicos visíveis num mesmo bloco
- Maiúsculas apenas em `overline` · Nunca itálico

---

## 4. Espaçamento, grade, raios e elevação

### 4.1. Escala de espaçamento (base 4)

`xs` 4 · `sm` 8 · `md` 12 · `lg` 16 · `xl` 20 · `2xl` 24 · `3xl` 32 · `4xl` 40 · `5xl` 56

### 4.2. Grade

- **Margem lateral da tela:** 24px · **Gutter entre cards:** 12px
- **Entre campos de formulário:** 16px · **Entre seções:** 32px
- Largura de conteúdo fluida, limite de 480px centralizado em telas largas

### 4.3. Raios de borda

| Token | px | Uso |
|---|---|---|
| `radius.sm` | 12 | Chips, badges, ícones em caixa |
| `radius.md` | 16 | Inputs, botões pequenos |
| `radius.lg` | 20 | Botões primários/secundários, cards internos |
| `radius.xl` | 28 | Cards de conteúdo, imagens |
| `radius.2xl` | 36 | Folha principal, bottom sheet (topo) |
| `radius.full` | 999 | Avatares, pílulas, FAB |

**Nenhum elemento com raio 0.** Bordas retas são proibidas na identidade MIAR.

### 4.4. Elevação (sombras suaves)

Sempre difusas, baixa opacidade, na cor `miar.ink`. Nunca pretas puras.

| Token | Valor | Uso |
|---|---|---|
| `elevation.1` | `0 2px 10px rgba(24,8,37,.05)` | Input, chip |
| `elevation.2` | `0 8px 24px rgba(24,8,37,.07)` | Card |
| `elevation.3` | `0 16px 40px rgba(24,8,37,.10)` | Folha principal, bottom sheet |
| `elevation.4` | `0 20px 48px rgba(24,8,37,.14)` | Modal, FAB |
| `elevation.glow` | `0 10px 28px rgba(124,58,237,.22)` | Botão primário em repouso |

---

## 5. Componentes

### 5.1. Botão primário
Pílula com `gradient.primaryAction` — assinatura da marca.
- Altura **56px** · Raio `radius.lg` · Largura 100% do container
- Texto `button` em branco, com sombra `0 1px 2px rgba(24,8,37,.35)` (ver §10)
- Ícone opcional (seta) à direita, 20px, gap 8px · Sombra `elevation.glow`
- **Estados:** repouso · pressionado (escala 0.98, sombra `elevation.2`) ·
  desabilitado (opacidade 45%, sem sombra) · carregando (spinner branco de 20px no lugar do rótulo)

### 5.2. Botão secundário
- Altura 56px · Raio `radius.lg` · Fundo `surface.primary`
- Borda 1.5px `border.secondaryAction` · Texto `button` em `miar.purple`
- **Estados:** pressionado (fundo `#7C3AED` 6%) · desabilitado (opacidade 45%)

### 5.3. Botão terciário / link
Sem fundo nem borda. Texto `button` em `miar.purple`; sublinhado apenas em link inline
(ex.: "Esqueceu sua senha?" — `caption` 13px, alinhado à direita).

### 5.4. Input de texto
- Altura **58px** · Raio `radius.md` · Fundo `surface.secondary` · Borda 1px `border.subtle`
- Padding horizontal 16px · Gap ícone→texto 12px
- Ícone à esquerda 22px (traço 1.8px) em `text.secondary`; ação à direita opcional (ex.: revelar senha)
- Placeholder `body` em `text.secondary`; valor em `text.primary`
- **Rótulo** `label` 8px acima do campo, alinhado à esquerda
- **Estados:** foco (borda 1.5px `border.focus` + halo `0 0 0 4px rgba(124,58,237,.10)`) ·
  erro (borda 1.5px `semantic.danger` + mensagem `caption` 6px abaixo) ·
  desabilitado (fundo `surface.sunken`, texto 45%)

### 5.5. Card
- Raio `radius.xl` · Fundo `surface.primary` · Borda 1px `border.subtle` ·
  Sombra `elevation.2` · Padding 16px

### 5.6. Folha principal (content sheet)
Folha branca que sobe sobre a aurora/foto — padrão do alvo de design.
- Raio superior `radius.2xl` · Fundo `gradient.surfaceVeil` · Sombra `elevation.3`
- Padding 32px 24px · Safe area inferior sempre respeitada

### 5.7. Badge de status
Pílula que representa o status da ocorrência. Altura 26px · Raio `radius.full` ·
Padding 0 12px · Texto 12/600.

Mapeamento **obrigatório** — exatamente os seis estados previstos no domínio do sistema,
nem mais, nem menos:

| Status | Fundo | Texto |
|---|---|---|
| Perdido | `#FFFFFF` 70% | `#77789C` |
| Encontrado | `#8AB8FF` 35% | `#3B6FD4` |
| Emergência | `#F2B5EB` 40% | `#C2437A` |
| Aguardando Adoção | `#F7E2A8` 45% | `#9A6A1F` |
| Adotado | `#A4F4D4` 35% | `#2F9E78` |
| Resgatado | `#A4F4D4` 35% | `#2F9E78` |

### 5.8. Chip de filtro
- Altura 38px · Raio `radius.full` · Padding 0 16px · Texto 14/600
- **Inativo:** `surface.secondary`, borda 1px `border.subtle`, texto `text.secondary`
- **Ativo:** `gradient.primaryAction`, sem borda, texto branco
- Linha com rolagem horizontal, gap 8px

### 5.9. Barra de navegação inferior
- Altura 64px + safe area · Fundo `#FFFFFF` 88% · Borda superior 1px `border.subtle` ·
  Raio superior `radius.2xl`
- Ícones 24px (traço 1.8px) · Rótulo 11/600
- **Inativo** `text.secondary` · **Ativo** `miar.purple` com ponto de 4px em
  `gradient.primaryAction` abaixo do rótulo
- Área de toque mínima 48×48px

> O número e o destino dos itens desta barra são determinados pelos casos de uso documentados,
> **nunca** por conveniência visual.

### 5.10. Cabeçalho de tela
- Altura 56px + safe area · Fundo transparente sobre a aurora
- Voltar: chevron 24px em `miar.purple`, toque 48×48px
- Título `h2` em `text.primary` · Ação à direita opcional, ícone 24px em `miar.purple`

### 5.11. Bottom sheet
- Raio superior `radius.2xl` · Fundo `surface.primary` · Sombra `elevation.4` · Scrim `overlay.scrim`
- Handle: pílula 40×4px em `border.subtle`, centralizada, 12px do topo
- Entrada: deslizar de baixo, 280ms `easeOutCubic`

### 5.12. Modal / diálogo
- Largura `100% − 48px` (máx. 400px) · Raio `radius.xl` · Padding 24px ·
  Fundo `surface.primary` · Sombra `elevation.4` · Scrim `overlay.scrim`
- Título `h3`, corpo `body`, ações empilhadas (primária acima) com gap 12px

### 5.13. Indicador de carregamento
- **Spinner:** anel de 28px, traço 3px, arco em `gradient.primaryAction`, rotação 900ms linear
- **Skeleton:** blocos em `surface.secondary` com o raio do elemento real e varredura de brilho
  `#FFFFFF` 60% em 1200ms
- Nunca spinner de página inteira com fundo opaco: a aurora permanece visível

### 5.14. Toast / notificação
- Topo, abaixo da safe area, margem lateral 24px · Altura mín. 56px · Raio `radius.lg`
- Fundo `surface.primary` · Sombra `elevation.4` · Faixa de 4px à esquerda na cor semântica
- Ícone 20px + texto `body` · Duração 4s · Entrada: deslizar de cima + fade, 240ms

### 5.15. Estado vazio
- Ícone/ilustração pastel de 96px centralizado (linhas finas, cores da paleta)
- Título `h3` + apoio `body` em `text.secondary`, centralizados
- Ação primária opcional 24px abaixo · Texto sempre orientado à ação

### 5.16. Mensagens de erro e sucesso
- **Inline (campo):** `caption` em `semantic.danger`, 6px abaixo do input, ícone de 14px
- **Bloco:** card raio `radius.md`, fundo semântico a 18%, borda 1px da mesma cor a 35%,
  ícone 20px + texto `body`
- Toda mensagem de erro diz **o que houve** e **o que fazer**

### 5.17. Mapa e marcadores geolocalizados
- Estilo claro customizado: água `#8AB8FF` 22%, áreas verdes `#A4F4D4` 25%, vias em branco,
  rótulos em `text.secondary`
- **Marcador:** pino 40×48px, corpo em `gradient.primaryAction`, miolo branco com ícone de pata
  18px, borda externa branca 2px, sombra `0 6px 14px rgba(24,8,37,.18)`
- **Marcador de emergência:** mesmo pino com halo pulsante em `#F2B5EB` 35%, 1600ms
- **Cluster:** círculo de 44px em `gradient.primaryAction`, número em branco 15/700
- **Card do marcador selecionado:** card padrão ancorado acima da barra inferior, margem lateral 24px

### 5.18. Card de animal / ocorrência
- Card padrão com imagem 4:3 no topo (raio superior `radius.xl`)
- Badge de status sobreposta no canto superior esquerdo, margem 12px
- Título `h3` · metadados `caption` em `text.secondary` separados por `·`
- Rodapé com cidade (ícone de pino 14px) e data

### 5.19. Galeria de ocorrências
- Grade de 2 colunas em telefones, gap 12px, margem lateral 24px
- Barra de chips de filtro fixa no topo com `gradient.headerFade` abaixo
- Rolagem contínua com 4 skeletons ao carregar

### 5.20. Perfil de usuário e de ONG
- Cabeçalho com aurora e avatar circular de 88px, borda branca 3px, sombra `elevation.2`
- Nome `h1` · Perfil (cidadão / protetor independente / ONG) em badge `radius.full`
  com fundo `surface.secondary` e texto `miar.purple`
- Dados em linhas: rótulo `caption` acima do valor `body`, divisor 1px `border.subtle`

### 5.21. Fotografias de animais
- Qualidade fotográfica real, iluminação clara e natural, fundo neutro ou desfocado
- Sempre com raio `radius.xl`, nunca com borda dura
- Integração com a aurora via `gradient.headerFade` quando a foto encostar em conteúdo
- Proporções permitidas: 4:3 (cards), 1:1 (avatares), 16:10 (herói)

---

## 6. Movimento

| Token | Duração | Curva | Uso |
|---|---|---|---|
| `motion.instant` | 120ms | `easeOut` | Cor, opacidade de ícone |
| `motion.fast` | 180ms | `easeOutCubic` | Pressionar botão, chip |
| `motion.base` | 240ms | `easeOutCubic` | Toast, fade de conteúdo |
| `motion.sheet` | 280ms | `easeOutCubic` | Bottom sheet, modal |
| `motion.page` | 320ms | `easeInOutCubic` | Transição entre telas |

- Transições **discretas**: deslizar horizontal de no máximo 24px + fade
- Nunca `bounce`, `elastic` ou rotações decorativas
- Respeitar "Reduzir movimento" do sistema: substituir por fade simples

---

## 7. Mobile first

O MIAR é um **aplicativo mobile** (Android e iOS). Toda interface nasce para o telefone.

- Base de projeto **390 × 844** (densidade lógica), escalando fluidamente
- **Safe areas** sempre respeitadas: topo (notch / Dynamic Island) e base (home indicator /
  barra de navegação Android). Nenhum elemento tocável nelas.
- **Área de toque mínima 48 × 48px**, com ao menos 8px entre alvos
- Ações primárias no terço inferior da tela (alcance do polegar)
- **Máximo de uma tarefa principal por tela**
- Formulários: um campo por linha, teclado adequado ao dado, botão de envio visível acima do teclado
- Listas longas com rolagem vertical única — nunca rolagem aninhada

---

## 8. Identidade do MIAR

### 8.1. Logo

A marca do MIAR é composta pelas peças oficiais do projeto, mantidas em
`prototipos/assets/img/`:

| Peça | Arquivo | Uso |
|---|---|---|
| **Wordmark** | `miar-wordmark.png` | Uso principal: telas de entrada, cabeçalhos de marca |
| Wordmark manuscrito | `miar-wordmark-manuscrito.png` | Variação, para peças com apelo mais afetivo |
| **Ícone** | `miar-icon.png` | Ícone do aplicativo, favicon, avatar, espaços reduzidos |
| Ícone sólido | `miar-icon-solido.png` | Variação preenchida |
| Versões brancas | `*-branco.png` | Sobre fundo colorido, gradiente ou fotografia |

O wordmark grafa `MIAR` com o **M em forma de cabeça de gato** e o ponto do **i** substituído por
uma **patinha**. O ícone isola esse mesmo M-gato.

**Adaptação cromática.** Os arquivos originais, preservados sem alteração em
`referencias/logo/`, empregam roxo escuro e laranja. Para a identidade Pastel Aurora, **apenas as
cores foram substituídas** — a forma, as proporções e o traço permanecem exatamente como no
original:

| Cor original | Cor Pastel Aurora | Onde ocorre |
|---|---|---|
| `#231034` roxo escuro | `#180825` `miar.ink` | Traço e contorno |
| `#ECA95B` / `#EC9F5B` laranja | `#B9A1FF` `miar.lilac` | Orelhas internas, preenchimento |
| `#ECD5BB` bege claro | `#F2B5EB` `miar.pink` | Tufos de pelo, focinho |

A conversão é reproduzível por `prototipos/recolor-logo.py`, que preserva o canal alfa de cada
pixel e, portanto, o antialiasing original.

**Regras de aplicação:**
- Wordmark e ícone **não devem ser usados juntos** no mesmo lockup: o wordmark já contém o gato
- Tagline opcional sob o wordmark: `MAPEAMENTO E IDENTIFICAÇÃO DE ANIMAIS DE RISCO`, token `overline`
- Área de proteção: metade da altura do ícone em todos os lados
- Altura mínima do wordmark: 32px · do ícone: 24px
- **Proibido** distorcer, inclinar, girar, aplicar sombra ou contorno
- **Proibido** recolorir fora da tabela acima sem autorização do responsável pelo projeto
- **Proibido** usar a frase "Mais pessoas, mais histórias felizes" em qualquer artefato do projeto

### 8.2. Perfis de usuário
A interface contempla os três perfis definidos no domínio — **cidadão**, **protetor independente**
e **ONG** — e nenhum outro. Cada perfil é identificado pela badge descrita em §5.20.
A diferença entre perfis é de **permissão**, nunca de identidade visual.

### 8.3. Fronteira entre estética e função
As telas do MIAR existem para atender às funcionalidades já documentadas.
**Nenhum botão, menu, aba, ação ou seção pode ser criado por razão estética.** Se um elemento
visual não encontra respaldo em Requisito Funcional ou Caso de Uso do documento acadêmico,
ele não entra no produto — ainda que apareça no alvo de design.

---

## 9. Implementação

A stack definida na Etapa 9 é **Flutter (Dart)** — ver `ARCHITECTURE.md`. Os tokens abaixo são a
implementação canônica para as duas superfícies em que o Design System é aplicado hoje:
os protótipos de interface (HTML/CSS) e, futuramente, o aplicativo.

### 9.1. Tokens em CSS — usados nos protótipos da Etapa 10

```css
:root {
  --miar-blue:#8AB8FF; --miar-lilac:#B9A1FF; --miar-pink:#F2B5EB; --miar-mint:#A4F4D4;
  --miar-purple:#7C3AED; --miar-ink:#180825; --miar-white:#FFFFFF; --miar-gray:#77789C;

  --surface-primary:rgba(255,255,255,.92);
  --surface-secondary:rgba(255,255,255,.72);
  --surface-sunken:rgba(255,255,255,.55);
  --border-subtle:rgba(24,8,37,.08);
  --scrim:rgba(24,8,37,.32);

  --gradient-aurora:linear-gradient(135deg,#8AB8FF 0%,#B9A1FF 38%,#F2B5EB 70%,#A4F4D4 100%);
  --gradient-action:linear-gradient(100deg,#8AB8FF 0%,#B9A1FF 30%,#F2B5EB 62%,#A4F4D4 100%);

  --radius-sm:12px; --radius-md:16px; --radius-lg:20px;
  --radius-xl:28px; --radius-2xl:36px; --radius-full:999px;

  --elev-1:0 2px 10px rgba(24,8,37,.05);
  --elev-2:0 8px 24px rgba(24,8,37,.07);
  --elev-3:0 16px 40px rgba(24,8,37,.10);
  --elev-4:0 20px 48px rgba(24,8,37,.14);
  --elev-glow:0 10px 28px rgba(124,58,237,.22);

  --font:'Outfit','Satoshi','Poppins',system-ui,sans-serif;
}
```

### 9.2. Tokens em Dart — referência para a implementação futura

> Trecho de referência de tokens. A implementação do aplicativo **não faz parte** da entrega
> das Etapas 8, 9 e 10 e só deve ser iniciada quando autorizada.

```dart
abstract final class MiarColors {
  static const blue         = Color(0xFF8AB8FF);
  static const lilac        = Color(0xFFB9A1FF);
  static const pink         = Color(0xFFF2B5EB);
  static const mint         = Color(0xFFA4F4D4);
  static const purple       = Color(0xFF7C3AED);
  static const ink          = Color(0xFF180825);
  static const white        = Color(0xFFFFFFFF);
  static const lavenderGray = Color(0xFF77789C);
}

abstract final class MiarGradients {
  static const aurora = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [MiarColors.blue, MiarColors.lilac, MiarColors.pink, MiarColors.mint],
    stops: [0.0, 0.38, 0.70, 1.0],
  );
  static const primaryAction = LinearGradient(
    begin: Alignment(-1, -0.2), end: Alignment(1, 0.2),
    colors: [MiarColors.blue, MiarColors.lilac, MiarColors.pink, MiarColors.mint],
    stops: [0.0, 0.30, 0.62, 1.0],
  );
}

abstract final class MiarRadius {
  static const sm = 12.0;  static const md = 16.0;  static const lg = 20.0;
  static const xl = 28.0;  static const xxl = 36.0; static const full = 999.0;
}
```

---

## 10. Acessibilidade

- **Contraste mínimo 4.5:1** para texto normal; 3:1 para texto ≥ 18px/600 e ícones funcionais
  - `#180825` sobre branco → 16.8:1 ✓
  - `#77789C` sobre branco → 4.6:1 ✓
  - `#7C3AED` sobre branco → 6.2:1 ✓
  - Branco sobre `gradient.primaryAction`: o trecho mint (`#A4F4D4`) **não** atinge 4.5:1.
    Por isso o texto do botão primário recebe sombra `0 1px 2px rgba(24,8,37,.35)`,
    **obrigatória**, garantindo legibilidade em toda a extensão do gradiente.
- **Nunca** comunicar estado apenas por cor: toda badge traz rótulo textual
- Todo ícone funcional tem rótulo acessível (`semanticsLabel` / `aria-label`)
- Tipografia escalável até 200% sem quebra de layout
- Ordem de foco segue a ordem visual; campos têm rótulo associado
- Suporte a "Reduzir movimento" (§6)

---

## 11. Governança

Regras permanentes, válidas para toda implementação futura do MIAR:

1. **`DESIGN_SYSTEM.md` deve ser consultado antes de qualquer implementação ou alteração visual.**
2. Todo novo componente deve usar exclusivamente os tokens e padrões aqui estabelecidos.
3. Nenhuma tela pode adotar identidade visual diferente da definida neste documento.
4. Componentes existentes devem ser reutilizados sempre que possível; criar variante apenas
   quando nenhum componente atender — e documentá-la aqui.
5. Divergências visuais encontradas devem ser identificadas e corrigidas para o padrão deste documento.
6. Alterações na identidade visual exigem **autorização explícita do responsável pelo projeto**.
7. A identidade visual **não pode ser substituída por preferências estéticas de uma IA** nem de
   qualquer colaborador.
8. Este Design System **não autoriza funcionalidades**: toda tela depende de respaldo em
   Requisito Funcional ou Caso de Uso documentado.

---

*MIAR Design System — Pastel Aurora · v1.0*
