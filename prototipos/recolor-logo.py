# -*- coding: utf-8 -*-
"""
Recolore os arquivos oficiais do logo MIAR para a paleta Pastel Aurora.

A forma dos arquivos originais é preservada integralmente: apenas os valores
de cor são substituídos, mantendo-se o canal alfa (e, portanto, o antialiasing)
de cada pixel. Ver DESIGN_SYSTEM.md §8.1.

Origem:  referencias/logo/           (arquivos originais, não modificados)
Destino: prototipos/assets/img/
"""
import os
from PIL import Image

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(PROJ, "referencias", "logo")
OUT = os.path.join(PROJ, "prototipos", "assets", "img")
os.makedirs(OUT, exist_ok=True)

# Mapeamento de cor: original -> Pastel Aurora
MAP = [
    ((0x23, 0x10, 0x34), (0x18, 0x08, 0x25)),  # roxo escuro  -> miar.ink
    ((0xEC, 0xA9, 0x5B), (0xB9, 0xA1, 0xFF)),  # laranja      -> miar.lilac
    ((0xEC, 0x9F, 0x5B), (0xB9, 0xA1, 0xFF)),  # laranja (var)-> miar.lilac
    ((0xEC, 0xD5, 0xBB), (0xF2, 0xB5, 0xEB)),  # bege claro   -> miar.pink
]

# Versão monocromática branca, para uso sobre fundo colorido ou fotografia
WHITE = (0xFF, 0xFF, 0xFF)

ARQUIVOS = [
    ("logo_Miar_variação.png", "miar-wordmark.png"),
    ("logo_Miar.png", "miar-wordmark-manuscrito.png"),
    ("icone Miar Variacao.png", "miar-icon.png"),
    ("icone Miar.png", "miar-icon-solido.png"),
]


def dist2(a, b):
    return (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2


def recolor(img, mono=None):
    """Substitui as cores preservando o canal alfa de cada pixel."""
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if mono is not None:
                px[x, y] = (mono[0], mono[1], mono[2], a)
                continue
            # duas cores de origem mais próximas, interpoladas pela distância
            ds = sorted(((dist2((r, g, b), src), src, dst) for src, dst in MAP))
            d0, _, dst0 = ds[0]
            d1, _, dst1 = ds[1]
            if d0 == 0 or d1 == 0 or d0 * 9 < d1:
                novo = dst0
            else:
                t = d0 ** 0.5 / (d0 ** 0.5 + d1 ** 0.5)
                novo = tuple(int(round(dst0[i] * (1 - t) + dst1[i] * t)) for i in range(3))
            px[x, y] = (novo[0], novo[1], novo[2], a)
    return img


for origem, destino in ARQUIVOS:
    caminho = os.path.join(SRC, origem)
    if not os.path.exists(caminho):
        print("  ausente:", origem)
        continue
    base = Image.open(caminho)
    recolor(base.copy()).save(os.path.join(OUT, destino))
    alvo_branco = destino.replace(".png", "-branco.png")
    recolor(base.copy(), mono=WHITE).save(os.path.join(OUT, alvo_branco))
    print("  %-28s -> %s (+ versão branca)" % (origem, destino))

print("Concluído.")
