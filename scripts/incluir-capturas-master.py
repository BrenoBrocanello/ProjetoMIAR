"""Acrescenta o catálogo ao MASTER por autorização expressa; preserva as 46 páginas originais."""
from pathlib import Path
import hashlib, json, math, os
import pymupdf

ROOT = Path(__file__).resolve().parent.parent
assert not json.loads((ROOT/'docs/MASTER.json').read_text(encoding='utf-8')).get('modelo_academico'), 'A revisão acadêmica substituiu o apêndice de capturas. Não o restaurar.'
OUT = ROOT/'evidencias/auditoria-2026-11-11'
CAT = OUT/'catalogo-visual'
BASE_HASH = 'd20641bd7dd5e44016c56e38ae5dc2db89b775835302618fc65fe45ee3555d06'
MASTER = ROOT/'docs/LabES_SistemaMIAR_1011.pdf'
ORIGINAL = Path(os.environ['USERPROFILE'])/'Downloads/LabES_SistemaMIAR_1011.pdf'
hashof = lambda b: hashlib.sha256(b).hexdigest()
assert hashof(ORIGINAL.read_bytes()) == BASE_HASH, 'Original externo não corresponde à especificação aprovada.'
assert json.loads((OUT/'catalogo-visual.json').read_text(encoding='utf-8'))['exit_code'] == 0, 'Catálogo não aprovado.'

items=[]
for path in sorted(CAT.glob('*.json')):
    meta=json.loads(path.read_text(encoding='utf-8'))
    png=path.with_suffix('.png')
    assert png.is_file(), f'Captura ausente: {png.name}'
    items.append({**meta,'arquivo':png.relative_to(ROOT).as_posix(),'sha256':hashof(png.read_bytes())})
assert len(items)>=50, 'O catálogo integral deve conter ao menos 50 capturas identificadas.'
assert len({i['ordem'] for i in items})==len(items), 'Ordem duplicada.'
items.sort(key=lambda x:x['ordem'])
native=[]
for folder,filename in [(OUT,'android-ensaio.json'),(OUT/'android26','android-fotografia.json')]:
    report=folder/filename
    if not report.exists():continue
    state=json.loads(report.read_text(encoding='utf-8'))
    if state['exit_code']!=0:continue
    for step in state.get('steps',[]):
        path=folder/step.get('screenshot',f'seletor-nativo-{step["mode"]}.png')
        if path.exists() and not any(n['arquivo']==path.relative_to(ROOT).as_posix() for n in native):
            native.append({'titulo':f'Interface nativa — {step["mode"]} ({state["avd"]})',
                           'requisitos':'RF02, RF05, CU05','fonte':'Recurso real do Android de teste; não é janela adicional do MIAR',
                           'arquivo':path.relative_to(ROOT).as_posix(),'sha256':hashof(path.read_bytes())})
for i in native:i['ordem']=len(items)+1;items.append(i)
apk_view=OUT/'apk-final-tela.png'
if apk_view.exists():
    items.append({'ordem':len(items)+1,'titulo':'APK final instalado — tela de login',
                  'requisitos':'RF01, CU02','fonte':'Artefato de entrega 1.0.0+3; API principal na porta 3000',
                  'arquivo':apk_view.relative_to(ROOT).as_posix(),'sha256':hashof(apk_view.read_bytes())})

base=pymupdf.open(ORIGINAL)
assert len(base)==46
doc=pymupdf.open(ORIGINAL)
font=ROOT/'app/assets/fonts/Outfit-Regular.ttf'
bold=ROOT/'app/assets/fonts/Outfit-SemiBold.ttf'
W,H=595,842
ink=(.09,.045,.15);muted=(.38,.34,.46)
def put(page,rect,text,size=10,b=False,color=ink):
    name='MiarBold' if b else 'MiarRegular'
    result=page.insert_textbox(pymupdf.Rect(rect),text,fontsize=size,fontname=name,
                              fontfile=str(bold if b else font),color=color)
    if result<0:raise RuntimeError(f'Texto não coube: {text[:80]}')
def page(title):
    p=doc.new_page(width=W,height=H)
    put(p,(35,22,560,55),title,13,True)
    p.draw_line((35,59),(560,59),color=(.65,.56,.87),width=1)
    put(p,(35,805,560,827),f'MIAR • Apêndice visual da implementação • 11/11/2026 • página {len(doc)}',8,color=muted)
    return p

p=page('APÊNDICE A — Capturas reais do aplicativo MIAR')
put(p,(35,90,560,160),'Catálogo completo das janelas, formulários, modais e estados visuais da versão auditada',20,True)
intro=(
 'Versão 1.0.0+3, Android. Apêndice incluído por solicitação expressa do responsável pelo projeto.\n\n'
 'As páginas 1–46, seus requisitos, diagramas e nove protótipos originais permanecem preservados. '
 'Os protótipos das páginas 38–46 continuam sendo a referência aprovada; as imagens seguintes documentam o aplicativo implementado e não substituem os requisitos.\n\n'
 'São apresentados todos os caminhos de interface do aplicativo, as três opções de perfil, edição, filtros, menus, confirmação de exclusão, formulários com rolagem e estados de indisponibilidade/ausência de registros. '
 'O mesmo formulário aparece em partes sucessivas para que nenhum campo seja omitido.\n\n'
 'As capturas são do código Flutter executado no Android. Dados fictícios identificados como ensaio foram usados em banco isolado. '
 'Consultas normais usam PostgreSQL, fotos S3 e análise de imagens reais. Estados vazios ou falhas induzidas apenas no cliente de teste estão explicitamente identificados nas legendas.\n\n'
 'As interfaces nativas de fotografia do Android são apresentadas em complemento. Não representam novas funções de negócio.\n\n'
 'A existência de uma captura não declara conformidade integral. Há diferenças de composição frente aos protótipos e limitações de plataforma/infraestrutura descritas no parecer de entrega. '
 'Não foram enviados contatos ou mensagens reais pelo WhatsApp.\n\n'
 f'Total: {len(items)} imagens. A fonte original de 46 páginas permanece também nos Downloads com SHA-256:\n{BASE_HASH}'
)
put(p,(35,178,560,760),intro,11)

index_pages=math.ceil(len(items)/25)
first=46+1+index_pages+1
toc=doc.get_toc()+[[1,'Apêndice A — Capturas reais do aplicativo',47],[2,'Índice das capturas',48]]
links=[]
for k in range(index_pages):
    p=page(f'Índice das capturas — parte {k+1}/{index_pages}')
    for j,item in enumerate(items[k*25:(k+1)*25]):
        global_i=k*25+j
        target=first+global_i//2
        item['pagina_master']=target
        text=f'{global_i+1:03d}. {item["titulo"]}'
        put(p,(35,80+j*27,505,105+j*27),text,9)
        put(p,(510,80+j*27,560,105+j*27),f'p. {target}',9,True)
        links.append((len(doc)-1,pymupdf.Rect(35,80+j*27,560,105+j*27),target-1))
for offset in range(0,len(items),2):
    p=page(f'Capturas {offset+1:03d}–{min(offset+2,len(items)):03d} de {len(items)}')
    for col,item in enumerate(items[offset:offset+2]):
        x=35+col*274;w=251
        put(p,(x,73,x+w,112),f'{offset+col+1:03d}. {item["titulo"]}',10,True)
        path=ROOT/item['arquivo'];pix=pymupdf.Pixmap(str(path))
        h=min(566,w*pix.height/pix.width);width=h*pix.width/pix.height
        p.insert_image(pymupdf.Rect(x+(w-width)/2,117,x+(w+width)/2,117+h),filename=str(path))
        put(p,(x,128+h,x+w,151+h),item['requisitos'],8,True)
        put(p,(x,154+h,x+w,202+h),item['fonte'],8,color=muted)
        toc.append([2,f'{offset+col+1:03d} — {item["titulo"]}',len(doc)])
for source,rect,target in links:
    doc[source].insert_link({'kind':pymupdf.LINK_GOTO,'from':rect,'page':target})
doc.set_toc(toc)
data=doc.tobytes(garbage=4,deflate=True)
check=pymupdf.open(stream=data,filetype='pdf')
proof=[]
for i in range(46):
    assert base[i].get_text()==check[i].get_text(),f'Texto original alterado na página {i+1}'
    a=hashof(base[i].get_pixmap().samples);b=hashof(check[i].get_pixmap().samples)
    assert a==b,f'Aparência original alterada na página {i+1}'
    proof.append({'pagina':i+1,'render_sha256':a})
assert len(check)==46+1+index_pages+math.ceil(len(items)/2)
meta=json.loads((ROOT/'docs/MASTER.json').read_text(encoding='utf-8'))
meta.update({'sha256':hashof(data),'paginas':len(check),'atualizado_em':'2026-11-11',
             'original_sha256':BASE_HASH,'paginas_originais':46,
             'apendice_visual':{'pagina_inicial':47,'imagens':len(items),'manifesto':'docs/master-apendice.json'}})
manifest={'master_original_sha256':BASE_HASH,'master_atual_sha256':hashof(data),'total_imagens':len(items),
          'paginas_originais_preservadas':proof,'capturas':items}
temporary=ROOT/'.runtime/master-com-capturas.pdf'
temporary.write_bytes(data)
os.replace(temporary,MASTER)
(ROOT/'docs/MASTER.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(ROOT/'docs/master-apendice.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'MASTER atualizado: {len(check)} páginas; {len(items)} imagens; 46 páginas originais verificadas por texto e renderização.')
print(f'SHA-256: {meta["sha256"]}')
