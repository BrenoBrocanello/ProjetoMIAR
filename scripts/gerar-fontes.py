"""Instancia pesos Outfit da fonte variável oficial; preserva família, desenho e licença."""
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

root = Path(__file__).resolve().parent.parent
folder = root / 'app/assets/fonts'
original = folder / 'Outfit.ttf'
for weight, name in [(400, 'Regular'), (500, 'Medium'), (600, 'SemiBold'), (700, 'Bold')]:
    font = instantiateVariableFont(TTFont(original), {'wght': weight}, inplace=False)
    font.save(folder / f'Outfit-{name}.ttf')
