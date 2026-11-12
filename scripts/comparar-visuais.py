"""Comparativo factual entre as imagens da MASTER e capturas nativas da auditoria."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'evidencias/auditoria-2026-11-11'
assert json.loads((OUT/'android-integracao.json').read_text())['exit_code'] == 0
font = ImageFont.truetype(str(ROOT/'app/assets/fonts/Outfit-Medium.ttf'), 24)
small = ImageFont.truetype(str(ROOT/'app/assets/fonts/Outfit-Regular.ttf'), 20)
names = ['Login', 'Criar cadastro', 'Galeria', 'Radar', 'Detalhe', 'Cadastrar ocorrência',
         'Gerenciar', 'Possível correspondência', 'Perfil']
files = ['01-login', '02-criar-cadastro', '03-galeria', '04-radar', '05-detalhe',
         '06-cadastrar', '07-gerenciar', '08-correspondencia', '09-perfil']
canvas = Image.new('RGB', (1800, 2280), '#e9eaf0')
draw = ImageDraw.Draw(canvas)
for i, (name, file) in enumerate(zip(names, files)):
    x, y = (i % 3)*600, (i // 3)*760
    draw.rounded_rectangle((x+8,y+8,x+592,y+752), radius=18, fill='white')
    draw.text((x+24,y+20), f'{i+1}. {name}', font=font, fill='#180e27')
    draw.text((x+24,y+59), f'MASTER p. {38+i}', font=small, fill='#655b7f')
    draw.text((x+320,y+59), 'App Android', font=small, fill='#655b7f')
    for j, path in enumerate([OUT/'referencias-visuais'/f'pagina-{38+i}.jpeg',
                              OUT/'android-janelas'/f'{file}.png']):
        im = Image.open(path).convert('RGB')
        im.thumbnail((270,640), Image.Resampling.LANCZOS)
        canvas.paste(im,(x+18+j*295+(270-im.width)//2,y+94))
canvas.save(OUT/'comparativo-visual.jpg', quality=94)
print('Comparativo gerado com as nove referencias extraidas e nove capturas Android aprovadas.')
