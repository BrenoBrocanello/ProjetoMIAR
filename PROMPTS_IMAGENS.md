# MIAR — Prompts das fotografias dos protótipos

As áreas de fotografia dos protótipos (Etapa 10) estão preparadas para receber imagens reais,
exibindo marcador de posição na identidade visual enquanto elas não existem (pendência **P19**).

> **Situação: concluído.** As seis imagens abaixo já foram geradas e aplicadas aos protótipos,
> e estão em `prototipos/assets/img/`. Os prompts permanecem registrados para permitir
> regeneração ou substituição futura.

## Como aplicar uma imagem gerada

1. Salve o arquivo em `prototipos/assets/img/` com o nome indicado na tabela.
2. No HTML da tela, acrescente o `style` ao elemento `.photo` correspondente:

```html
<div class="photo photo-hero" style="background-image:url('assets/img/hero-cao-gato.jpg')">
```

O marcador de posição é ocultado automaticamente. Depois, regere as imagens:

```powershell
powershell -ExecutionPolicy Bypass -File prototipos\render.ps1
```

---

## Diretrizes comuns a todos os prompts

Acrescente ao final de qualquer prompt desta lista:

> Fotografia realista, luz natural suave e difusa, alta qualidade, cores suaves e pastel
> harmonizando com azul pastel, lilás, rosa claro e verde-menta. Fundo desfocado e claro.
> Sem texto, sem marca d'água, sem logotipo, sem moldura, sem pessoas. Enquadramento vertical.

**Evitar:** cores saturadas, contraste agressivo, iluminação dura, estética sombria, animais
visivelmente feridos ou em sofrimento, coleiras com marcas comerciais.

---

## Prompts

### 1. Herói da tela de Login — `hero-cao-gato.jpg`
Proporção 16:10 · Tela 01

> Um cão golden retriever e um gato rajado lado a lado, ambos olhando para cima com expressão
> serena e esperançosa, enquadrados do peito para cima, centralizados, fundo desfocado em tons
> pastel claros.

### 2. Cão de grande porte, perdido — `ocorrencia-cao-grande.jpg`
Proporção 4:3 · Telas 03, 05, 08

> Cão sem raça definida de pelo caramelo curto, porte grande, usando coleira azul simples,
> sentado ao ar livre, olhando para a câmera, expressão dócil.

### 3. Gato de pequeno porte, encontrado — `ocorrencia-gato-rajado.jpg`
Proporção 4:3 · Telas 03, 07, 08

> Gato rajado cinza de pelo curto, porte pequeno, sem coleira, sentado em calçada clara,
> olhando para a câmera.

### 4. Cão de médio porte, emergência — `ocorrencia-cao-medio.jpg`
Proporção 4:3 · Telas 03, 04, 07

> Cão de porte médio, pelo curto e claro, deitado em local sombreado, cabeça erguida,
> expressão calma. Sem ferimentos visíveis.

### 5. Gato filhote, aguardando adoção — `ocorrencia-gato-filhote.jpg`
Proporção 4:3 · Tela 03

> Gatinho filhote de pelo preto brilhante, saudável, sentado sobre superfície clara,
> olhando para a câmera, expressão curiosa.

### 6. Avatar de usuário — `avatar-usuario.jpg`
Proporção 1:1 · Tela 09 (opcional)

> Ilustração minimalista de avatar em degradê pastel azul, lilás e rosa, silhueta simples de
> pessoa, estilo plano e geométrico, sem traços faciais detalhados.

---

## Logo

O logotipo **já está aplicado** e não requer geração por IA. Os arquivos oficiais enviados pelo
projeto estão preservados, sem alteração, em `referencias/logo/`, e as versões recoloridas para
a paleta Pastel Aurora estão em `prototipos/assets/img/`.

A recoloração substitui **apenas as cores**, preservando integralmente a forma, as proporções e
o antialiasing do original. Para regerar:

```
python prototipos/recolor-logo.py
```

O mapeamento de cores está documentado em `DESIGN_SYSTEM.md` §8.1.
