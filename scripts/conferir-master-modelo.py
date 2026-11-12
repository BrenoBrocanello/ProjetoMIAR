"""Inspeciona conteúdo e gera provas visuais da revisão acadêmica."""
from pathlib import Path
import os,json,re,hashlib
import pymupdf
from docx import Document
from PIL import Image,ImageOps,ImageDraw
from io import BytesIO
from collections import Counter

ROOT=Path(__file__).resolve().parent.parent
stage=Path(os.environ['LOCALAPPDATA'])/'MiarDev/376eb84567/documentacao'
out=ROOT/'.runtime/revisao-modelo/render';out.mkdir(exist_ok=True)
d=Document(stage/'LabES_SistemaMIAR_MASTER.docx')
pdf=pymupdf.open(stage/'LabES_SistemaMIAR_MASTER.pdf')
paragraphs=[p.text for p in d.paragraphs]
text='\n'.join(paragraphs+[c.text for t in d.tables for r in t.rows for c in r.cells])
assert not re.search('[\u2013\u2014\u2026\U0001f300-\U0001faff]',text)
assert not re.search(r'\b(XXX|Aluno 1|Concluindo|Lorem ipsum)\b',text,re.I)
assert len(d.inline_shapes)==12
def pixels(data):
    im=Image.open(BytesIO(data)).convert('RGB')
    return (im.size,hashlib.sha256(im.tobytes()).hexdigest())
sources=[ROOT/'docs/master-extraido/diagrama-casos-uso.png',ROOT/'docs/master-extraido/diagrama-24-0.png',ROOT/'docs/master-extraido/diagrama-25-0.png']
sources += [ROOT/f'evidencias/auditoria-2026-11-11/referencias-visuais/pagina-{i}.jpeg' for i in range(38,47)]
embedded=[d.part.related_parts[s._inline.graphic.graphicData.pic.blipFill.blip.embed].blob for s in d.inline_shapes]
assert Counter(pixels(p.read_bytes()) for p in sources)==Counter(pixels(b) for b in embedded),'Imagem alterada'
assert len(d.tables)==26
for prefix,n in [('RF',8),('RNF',6),('RD',7),('CU',12)]:
    assert all(re.search(rf'\b{prefix}{i:02}\b',text) for i in range(1,n+1))
model=Document(Path.home()/'Downloads/Aula01 - Modelo Projeto de LabES - 2º sem 2026.docx')
for original,current in zip(model.tables[:3],d.tables[:3]):
    assert [c.text for c in original.rows[0].cells]==[c.text for c in current.rows[0].cells]
case_labels=[r.cells[0].text for r in model.tables[3].rows]
for t in d.tables[3:15]:assert [r.cells[0].text for r in t.rows]==case_labels
source=json.loads((ROOT/'docs/fonte-academica.json').read_text(encoding='utf-8'))
norm=lambda s:''.join(s.split())
for t in d.tables[:3]:
    for row in t.rows[1:]:
        code,title,description=[c.text for c in row.cells]
        assert title==source['requisitos'][code][0]
        if code!='RNF01':assert description==source['requisitos'][code][1],code
for attr in ['page_width','page_height','top_margin','bottom_margin','left_margin','right_margin']:
    assert getattr(d.sections[0],attr)==getattr(model.sections[0],attr),attr
pages=[];thumbs=[]
for i,p in enumerate(pdf):
    spans=[s for b in p.get_text('dict')['blocks'] if 'lines' in b for l in b['lines'] for s in l['spans']]
    meaningful=[s for s in spans if s['text'].strip() and not s['text'].strip().isdigit()]
    drawn=p.get_image_info()
    assert meaningful or drawn,f'Página vazia: {i+1}'
    chars=[c for b in p.get_text('rawdict')['blocks'] if 'lines' in b for l in b['lines'] for s in l['spans'] for c in s['chars'] if c['c'].strip()]
    outside=[c['c'] for c in chars if c['bbox'][0]<56 or c['bbox'][2]>p.rect.width-56]
    assert not any(ch in p.get_text() for ch in ['\ufffd','\u25a1']),f'Glifo ausente na página {i+1}'
    assert not outside,f'Texto fora da margem na página {i+1}: {outside}'
    for span in meaningful:
        assert span['bbox'][1]>=55.8 and span['bbox'][3]<=p.rect.height-55.8,f'Texto fora das margens verticais na página {i+1}'
    for im in drawn:
        x0,y0,x1,y1=im['bbox']
        assert x0>=56 and x1<=p.rect.width-56 and y0>=56 and y1<=p.rect.height-56,f'Imagem fora da margem na página {i+1}'
    pix=p.get_pixmap(matrix=pymupdf.Matrix(1.5,1.5));pix.save(out/f'pagina-{i+1:02}.png')
    im=Image.open(out/f'pagina-{i+1:02}.png').convert('RGB');im.thumbnail((275,395))
    tile=Image.new('RGB',(295,425),'#dedede');tile.paste(im,((295-im.width)//2,18));ImageDraw.Draw(tile).text((12,407),str(i+1),fill='black');thumbs.append(tile)
    pages.append({'pagina':i+1,'inicio':p.get_text()[:130],'imagens':len(drawn),'fora_da_margem':outside})
assert sum(p['imagens'] for p in pages)==12
assert sum(len(t.rows)-1 for t in d.tables[-9:])==50
headers=[p.text for p in d.paragraphs if p.style.name=='Heading 1']
assert len(headers)==21
assert headers[-3:]==['1.4. Projeto de Interface do Sistema','1.5. Conclusão','1.6. Bibliografia']
model_headers=[' '.join(p.text.split()) for p in model.paragraphs if p.style.name=='Heading 1' and p.text.strip()]
for expected,current in zip(model_headers,headers):
    number=expected.split()[0]
    assert current.startswith(number+' ')
    if number not in {'1.','1.2.3.','1.2.4.'}:assert expected==current,(expected,current)
model_heading_paragraphs=[p for p in model.paragraphs if p.style.name=='Heading 1' and p.text.strip()]
current_heading_paragraphs=[p for p in d.paragraphs if p.style.name=='Heading 1']
for original,current in zip(model_heading_paragraphs,current_heading_paragraphs):
    original_run=next(r for r in original.runs if r.text.strip())
    current_run=next(r for r in current.runs if r.text.strip())
    assert (current_run.font.size or current.style.font.size)==original_run.font.size
    assert (current_run.font.name or current.style.font.name)=='Calibri'
assert d.styles['Caption'].font.bold is False
assert str(d.styles['Caption'].font.color.rgb)=='000000'
# Ignora apenas os números do rodapé, que não fazem parte das frases.
body_pdf=''.join(''.join(s['text'] for b in p.get_text('dict')['blocks'] if 'lines' in b for l in b['lines'] for s in l['spans'] if not(s['text'].strip()==str(i+1) and s['bbox'][1]>p.rect.height-70)) for i,p in enumerate(pdf))
compact_pdf=norm(body_pdf)
all_texts=paragraphs+[c.text for t in d.tables for row in t.rows for c in row.cells]
missing=[p for p in all_texts if p.strip() and norm(p) not in compact_pdf]
assert not missing,f'Texto do Word ausente ou alterado no PDF: {missing}'
for start in range(0,len(thumbs),12):
    sheet=Image.new('RGB',(295*4,425*3),'white')
    for n,tile in enumerate(thumbs[start:start+12]):sheet.paste(tile,((n%4)*295,(n//4)*425))
    sheet.save(out/f'contato-{start//12+1}.jpg',quality=88)
(out.parent/'conferencia.json').write_text(json.dumps({'paginas':len(pdf),'imagens':12,'tabelas':len(d.tables),'requisitos':21,'casos':12,'margens_e_formato_iguais_ao_modelo':True,'texto_word_pdf_igual':True,'imagens_pixels_iguais':True,'fontes_titulos_iguais_ao_modelo':True,'detalhes':pages},ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'paginas':len(pdf),'imagens':12,'tabelas':len(d.tables),'fora_da_margem':[(p['pagina'],p['fora_da_margem']) for p in pages if p['fora_da_margem']]},ensure_ascii=False))
