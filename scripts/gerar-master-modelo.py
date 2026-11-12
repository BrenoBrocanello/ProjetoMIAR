"""Reorganiza a especificação MIAR no modelo acadêmico fornecido pelo responsável."""
from pathlib import Path
from copy import deepcopy
from datetime import datetime
import hashlib,json,os,re,shutil
from io import BytesIO
from PIL import Image
from docx import Document
from docx.shared import Cm,Pt,RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH,WD_TAB_ALIGNMENT
from docx.enum.table import WD_TABLE_ALIGNMENT,WD_CELL_VERTICAL_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

ROOT=Path(__file__).resolve().parent.parent
TEMPLATE=Path.home()/'Downloads/Aula01 - Modelo Projeto de LabES - 2º sem 2026.docx'
WORK=ROOT/'.runtime/revisao-modelo'
WORK.mkdir(parents=True,exist_ok=True)
STAGE=Path(os.environ['LOCALAPPDATA'])/'MiarDev/376eb84567/documentacao'
STAGE.mkdir(parents=True,exist_ok=True)
source=json.loads((ROOT/'docs/fonte-academica.json').read_text(encoding='utf-8'))
BASE=ROOT/'docs/LabES_SistemaMIAR_1011.pdf'
archive=STAGE/'fontes-preservadas';archive.mkdir(exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
oldsha='8df799ce277593a416a75e4edf56be663590f825b759630ef24a0b3614cb62b0'
snapshot=archive/f'MIAR-antes-modelo-{oldsha[:12]}.pdf'
if not snapshot.exists():
    assert sha(BASE)==oldsha,'A fonte original desta revisão deve ser preservada antes de regenerar.'
    shutil.copy2(BASE,snapshot)
assert sha(snapshot)==oldsha,'Fonte preservada alterada.'
d=Document(TEMPLATE)
for child in list(d.element.body):
    if child.tag!=qn('w:sectPr'):d.element.body.remove(child)
for rid,rel in list(d.part.rels.items()):
    if rel.reltype.endswith('/image'):d.part.drop_rel(rid)
section=d.sections[0]
section.different_first_page_header_footer=True
normal=d.styles['Normal'];normal.font.name='Calibri';normal.font.size=Pt(12)
normal.paragraph_format.line_spacing=1.5
normal.paragraph_format.space_after=Pt(0)
normal.paragraph_format.first_line_indent=Cm(1.25)
normal.paragraph_format.alignment=WD_ALIGN_PARAGRAPH.JUSTIFY
normal.paragraph_format.widow_control=True
heading=d.styles['Heading 1'];heading.font.name='Calibri';heading.font.size=Pt(14);heading.font.bold=True
heading.font.color.rgb=RGBColor(0,0,0)
heading.paragraph_format.keep_with_next=True
heading.paragraph_format.first_line_indent=Cm(0)
heading.paragraph_format.alignment=WD_ALIGN_PARAGRAPH.LEFT
heading.paragraph_format.space_before=Pt(6);heading.paragraph_format.space_after=Pt(4)
heading.paragraph_format.line_spacing=1
caption=d.styles['Caption'];caption.font.name='Calibri';caption.font.size=Pt(12);caption.font.italic=False
caption.font.bold=False;caption.font.color.rgb=RGBColor(0,0,0)
caption.paragraph_format.alignment=WD_ALIGN_PARAGRAPH.CENTER
caption.paragraph_format.first_line_indent=Cm(0);caption.paragraph_format.line_spacing=1
caption.paragraph_format.space_after=Pt(4)
footer=section.footer.paragraphs[0]
footer.alignment=WD_ALIGN_PARAGRAPH.CENTER
footer.paragraph_format.first_line_indent=Cm(0)
footer.paragraph_format.line_spacing=1
run=footer.add_run();run.font.name='Times New Roman';run.font.size=Pt(9)
fld=OxmlElement('w:fldSimple');fld.set(qn('w:instr'),'PAGE');run._r.addnext(fld)
settings=d.settings.element
compress=OxmlElement('w:doNotAutoCompressPictures');settings.append(compress)
lang=normal.element.get_or_add_rPr();el=OxmlElement('w:lang');el.set(qn('w:val'),'pt-BR');lang.append(el)
members=[('Adriel Martins de Souza','1140482422019'),('Any Caroline Bezerra','1140482422024'),
         ('Breno de Oliveira Brocanello','1140482422003'),('João Vitor Cavalcante Barros','1140482422035'),
         ('Maria Eduarda Marchezini Barbieri','1140482422004')]

def clean(s):
    return s.replace('—',', ').replace('–',', ').replace('\u00ad','').replace('\u00a0',' ')
def para(text='',bold=False,indent=True,size=None,align=None,keep=False):
    p=d.add_paragraph();p.paragraph_format.keep_with_next=keep
    if not indent:p.paragraph_format.first_line_indent=Cm(0)
    if align is not None:p.alignment=align
    r=p.add_run(clean(text));r.bold=bold
    if size:r.font.size=Pt(size)
    return p
def head(text,new=False):
    p=d.add_paragraph(clean(text),'Heading 1');p.paragraph_format.page_break_before=new
    if re.match(r'^1\.\d+\.\d+\.',text):
        for run in p.runs:run.font.size=Pt(12)
    return p
def cover(text,size=12,bold=False,before=0,after=0):
    p=d.add_paragraph(style='No Spacing');p.alignment=WD_ALIGN_PARAGRAPH.CENTER
    f=p.paragraph_format;f.first_line_indent=Cm(0);f.left_indent=Cm(0);f.space_before=Pt(before);f.space_after=Pt(after)
    r=p.add_run(text);r.font.name='Calibri';r.font.size=Pt(size);r.bold=bold
    return p
def table(headers,rows,widths=None,size=11):
    t=d.add_table(rows=1,cols=len(headers));t.alignment=WD_TABLE_ALIGNMENT.CENTER;t.autofit=False
    widths=widths or [10.8/len(headers)]*len(headers)
    for col,width in zip(t.columns,widths):col.width=Cm(width)
    borders=OxmlElement('w:tblBorders')
    for edge in ['top','left','bottom','right','insideH','insideV']:
        e=OxmlElement('w:'+edge);e.set(qn('w:val'),'single');e.set(qn('w:sz'),'4');e.set(qn('w:color'),'000000');borders.append(e)
    t._tbl.tblPr.append(borders)
    def cell_text(cell,text,header=False,col=0):
        cell.vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.TOP
        chunks=re.split(r'\s+(?=(?:\d+\.|A\d+\.)\s)',text) if re.match(r'^(\d+\.|A\d+\.)\s',text) else [text]
        cell.text=''
        for i,chunk in enumerate(chunks):
            p=cell.paragraphs[0] if i==0 else cell.add_paragraph()
            f=p.paragraph_format;f.first_line_indent=Cm(0);f.space_before=Pt(0);f.space_after=Pt(2);f.line_spacing=1.05
            p.alignment=WD_ALIGN_PARAGRAPH.LEFT
            r=p.add_run(clean(chunk));r.font.name='Calibri';r.font.size=Pt(size if not header else 10);r.bold=header
        return cell
    for i,(cell,text) in enumerate(zip(t.rows[0].cells,headers)):
        cell.width=Cm(widths[i]);cell_text(cell,text,True,i)
    repeat=OxmlElement('w:tblHeader');t.rows[0]._tr.get_or_add_trPr().append(repeat)
    for row in rows:
        rr=t.add_row()
        for i,(cell,text) in enumerate(zip(rr.cells,row)):
            cell.width=Cm(widths[i]);cell_text(cell,str(text),False,i)
        cant=OxmlElement('w:cantSplit');rr._tr.get_or_add_trPr().append(cant)
    return t
def image(path,width,caption_text):
    p=para('',indent=False,align=WD_ALIGN_PARAGRAPH.CENTER,keep=True)
    p.paragraph_format.left_indent=Cm(0);p.paragraph_format.right_indent=Cm(0)
    p.paragraph_format.line_spacing=1;p.paragraph_format.space_before=Pt(2);p.paragraph_format.space_after=Pt(2)
    im=Image.open(path);dpi=im.info.get('dpi',(96,96))
    if not dpi[0] or not dpi[1]:
        buffer=BytesIO();im.save(buffer,format='PNG',dpi=(96,96));buffer.seek(0)
        p.add_run().add_picture(buffer,width=Cm(width))
    else:p.add_run().add_picture(str(path),width=Cm(width))
    p=d.add_paragraph(caption_text,'Caption');p.paragraph_format.keep_with_next=False

# Capa: mesmos blocos do modelo, com os cinco integrantes do projeto original.
cover('CENTRO ESTADUAL DE EDUCAÇÃO',bold=True)
cover('TECNOLÓGICA PAULA SOUZA',bold=True)
cover('Faculdade de Tecnologia de Jundiaí, Dep. Ary Fossen',bold=True)
cover('Curso Superior de Tecnologia em Análise e')
cover('Desenvolvimento de Sistemas')
cover('PROJETO MIAR:',12,True,before=95)
cover('Mapeamento e identificação de animais de risco',11.5,True,after=60)
for name,ra in members:
    p=cover(name.upper()+'\t'+ra,10.5)
    p.alignment=WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.tab_stops.add_tab_stop(Cm(10.8),WD_TAB_ALIGNMENT.RIGHT)
cover('Prof.ª Me. Ângela Lühmann',12,before=39,after=54)
cover('Jundiaí',12,True)
cover('2026',12,True)

head('1. PROJETO MIAR: Mapeamento e identificação de animais de risco',True)
for name,_ in members:
    p=para(name,indent=False,size=10);p.paragraph_format.line_spacing=1
head('1.1. Requisitos do Sistema')
head('1.1.1. Escopo')
para('O MIAR é um aplicativo móvel para registrar e consultar ocorrências de animais perdidos, encontrados, em emergência ou disponíveis para adoção. Cidadãos, protetores independentes e ONGs podem publicar fotos, informar as condições do animal e registrar sua localização. A consulta é feita por uma galeria com filtros e, para protetores e ONGs, por um mapa de ocorrências.')
para('O projeto também contempla a comparação de fotografias com registros de animais perdidos e o aviso de possível correspondência ao responsável. O contato entre os usuários ocorre pelo WhatsApp. Conversas internas, envio automático de mensagens, favoritos e área administrativa não fazem parte do escopo.')
head('1.1.2. Descrição Textual do Sistema')
para('Para utilizar o MIAR, a pessoa cria uma conta, escolhe seu perfil e informa os dados de acesso e contato. Depois do login, pode consultar a galeria, abrir uma ocorrência e verificar suas fotografias, descrição, cidade, localização e situação atual. Os filtros por status, espécie, porte e cidade ajudam a encontrar registros de interesse.')
para('No cadastro de uma ocorrência, o usuário informa a descrição física do animal, sua espécie, porte, estado aparente de saúde e status. Também adiciona fotografias, registra a cidade, obtém as coordenadas pelo GPS e fornece um telefone brasileiro com DDD. A ocorrência fica vinculada a quem a cadastrou. Esse responsável pode alterar os dados, atualizar a situação e excluir o registro.')
para('As ocorrências assumem um dos seis status: Perdido, Encontrado, Emergência, Aguardando Adoção, Adotado ou Resgatado. Protetores e ONGs também têm acesso ao radar, que apresenta os registros por marcadores no mapa. A seleção de um marcador mostra o resumo da ocorrência.')
para('As fotografias de uma nova ocorrência são comparadas com as de animais perdidos. Quando há semelhança suficiente, o responsável pelo registro de animal perdido recebe um aviso e pode consultar as imagens relacionadas. O resultado indica uma possibilidade de correspondência e não confirma, por si só, que as fotos sejam do mesmo animal.')
para('Quando o contato público está disponível, o botão de WhatsApp abre o link para o número cadastrado. O usuário continua a conversa fora do MIAR. Ocorrências marcadas como Adotado ou Resgatado deixam de exibir esse contato para novos interessados, sem impedir que o responsável administre seu próprio registro.')

for section_title,prefix,count,headers in [
 ('1.1.3. Requisitos Funcionais','RF',8,['Requisito Funcional (RF)','Nome do Requisito Funcional','Descrição do Requisito Funcional']),
 ('1.1.4. Requisitos Não Funcionais','RNF',6,['Requisito Não Funcional (RNF)','Nome do Requisito Não Funcional','Descrição do Requisito Não Funcional']),
 ('1.1.5. Requisitos de Domínio','RD',7,['Requisito de Domínio (RD)','Nome do Requisito de Domínio','Descrição do Requisito de Domínio'])]:
    head(section_title)
    name={'RF':'Funcionais','RNF':'Não Funcionais','RD':'de Domínio'}[prefix]
    para('Na tabela a seguir, são apresentados os Requisitos '+name+' do Sistema:',indent=False)
    rows=[]
    for n in range(1,count+1):
        code=f'{prefix}{n:02}';title,body=source['requisitos'][code]
        if code=='RNF01':body='O sistema deve apresentar uma interface responsiva, adaptando-se aos diferentes tamanhos de tela de celulares e tablets.'
        rows.append([code,title,body])
    table(headers,rows,[1.8,3.1,5.9],10.5)
head('1.1.6. Diagrama de Casos de Uso',True)
para('O diagrama apresenta os três perfis de usuário e a API de reconhecimento de imagens. O cadastro de ocorrência inclui a análise das fotografias. A notificação é uma extensão dessa análise, executada quando existe uma possível correspondência. O radar é associado a protetores e ONGs, conforme o CU09. A notação adotada segue a UML (Object Management Group, 2017).')
image(ROOT/'docs/master-extraido/diagrama-casos-uso.png',10.2,'Diagrama de Casos de Uso do MIAR')
head('1.1.7. Documento de Casos de Uso',True)
para('Os quadros a seguir descrevem os atores e os cenários de cada caso de uso.')
for n,rows in enumerate(source['casos']):
    if n:
        p=para(' '.join(rows[0][1].split()),bold=True,indent=False,keep=True)
        p.paragraph_format.page_break_before=True
    cooked=[]
    for label,value in rows[1:]:
        label=' '.join(label.split());value=' '.join(value.split())
        if n==0 and label=='Cenário Normal':
            value='1. A pessoa acessa a opção de criação de cadastro. 2. Seleciona um dos três perfis e informa nome, e-mail, telefone, senha e, quando aplicável, documento. 3. O MIAR valida os dados e o telefone brasileiro com DDD. 4. O sistema registra o usuário e o habilita para autenticação.'
        cooked.append([label,value])
    table(['Caso de Uso',' '.join(rows[0][1].split())],cooked,[2.8,8.0],11)

head('1.2. Detalhamento Técnico',True)
para('Esta seção apresenta as linguagens, a plataforma, o banco de dados e a arquitetura adotados no MIAR.')
head('1.2.1. Linguagem de Programação')
para('O aplicativo foi desenvolvido em Dart com Flutter. A mesma base de código atende à proposta de execução em Android e iOS e permite organizar as janelas com os mesmos componentes visuais. O Flutter também oferece integração com recursos do aparelho, necessários à seleção de fotografias e à obtenção da localização (Flutter, s.d.).')
para('Na camada de serviços foi utilizado TypeScript com NestJS, executado em Node.js. Os módulos concentram as validações, a autenticação e o controle de acesso aos registros. A divisão entre controladores, serviços e acesso a dados segue a organização apresentada na documentação do framework (NestJS, s.d.).')
para('O processamento das imagens utiliza Python em um serviço interno. A implementação gera descritores visuais com MobileNetV3 e compara as imagens por similaridade. A arquitetura do modelo é apresentada por Howard et al. (2019), e sua implementação e seus pesos pré-treinados estão disponíveis no Torchvision (PyTorch, s.d.). O percentual apresentado no MIAR corresponde à semelhança calculada, não a uma probabilidade comprovada de identidade.')
head('1.2.2. Plataforma (Web/Desktop)')
para('O MIAR foi definido como aplicativo móvel, com Android 8.0 ou superior e iOS 13 ou superior como plataformas previstas. Não foi projetada uma versão web ou para computadores de mesa. A interface se adapta aos tamanhos de tela de celulares e tablets, conforme o RNF01.')
para('A implementação foi exercitada em emuladores Android. O projeto iOS está configurado, mas sua compilação e validação dependem de um ambiente macOS com Xcode.')
head('1.2.3. SGBD: Sistema Gerenciador de Banco de Dados')
para('O banco de dados escolhido foi o PostgreSQL 16. O modelo é relacional e utiliza chaves primárias e estrangeiras para vincular usuários, animais, ocorrências, cidades, localizações, fotos e contatos. As restrições de integridade ajudam a manter esses vínculos durante o cadastro, a alteração e a exclusão de registros (PostgreSQL Global Development Group, s.d.).')
para('As fotografias ficam em armazenamento de objetos compatível com S3. A tabela FOTO guarda o endereço de cada arquivo e sua ligação com a ocorrência. O banco mantém as nove entidades do DER, sem criar tabelas separadas para os três perfis de usuário.')
para('PostGIS e pgvector fazem parte da configuração prevista para consultas geográficas e por similaridade. No ambiente portátil utilizado no Windows, essas extensões não estão instaladas: o mapa utiliza as coordenadas armazenadas, e o cálculo de similaridade é executado na API. A configuração com as extensões ainda precisa ser validada antes da implantação definitiva.')
head('1.2.4. Arquitetura do Sistema e Interfaces Necessárias')
para('A arquitetura reúne o aplicativo Flutter, a API NestJS, o PostgreSQL e os serviços de armazenamento e análise de imagens. O aplicativo separa apresentação, domínio e acesso a dados. Na API, os módulos organizam as regras de cada funcionalidade.')
para('A autenticação utiliza token de sessão. As senhas são armazenadas por função de resumo criptográfico, e o servidor confere se o usuário é responsável pelo registro antes de permitir alteração, atualização de status ou exclusão. O bloqueio não depende apenas dos botões exibidos na interface.')
table(['Recurso do aparelho','Uso no MIAR'],[
 ['Câmera e galeria','Capturar ou selecionar fotografias da ocorrência.'],
 ['GPS','Obter latitude e longitude para o cadastro e o mapa.'],
 ['Conectividade','Consultar a API e informar falhas de comunicação.'],
 ['Armazenamento protegido','Manter o token da sessão no aparelho.'],
 ['Notificações','Apresentar avisos de possível correspondência.'],
 ['Acessibilidade','Oferecer rótulos de campos e adaptação à escala de texto.']], [3.5,7.3],11)
para('As interfaces externas utilizadas são descritas no quadro seguinte.',indent=False)
t=table(['Sistema ou serviço','Integração'],[
 ['WhatsApp','Abertura de um link para o número cadastrado. Não há envio automático nem leitura de conversas.'],
 ['OpenStreetMap','Obtenção das imagens cartográficas usadas no radar, com atribuição ao serviço.'],
 ['Armazenamento de objetos','Envio e recuperação dos arquivos de fotografia.'],
 ['Serviço de análise','Geração dos descritores utilizados na comparação das imagens.']], [3.5,7.3],11)
for row in t.rows[:-1]:
    for cell in row.cells:
        for p in cell.paragraphs:p.paragraph_format.keep_with_next=True
para('O mapa segue a política de uso do OpenStreetMap, com identificação da aplicação e atribuição da fonte (OpenStreetMap Foundation, s.d.). A implantação prevê HTTPS; o ambiente local utiliza HTTP.')

head('1.3. Projeto do Sistema',True)
para('Os diagramas representam as classes e a estrutura de dados do MIAR.')
head('1.3.1. Diagrama de Classes')
para('O usuário registra ocorrências vinculadas a animais, com localização, fotografias e contatos. As enumerações representam os perfis, os portes e os seis status da ocorrência. O diagrama apresenta essas classes e suas associações.')
image(ROOT/'docs/master-extraido/diagrama-24-0.png',10.2,'Diagrama de Classes do MIAR')
head('1.3.2. Diagrama Entidade-Relacionamento (DER)',True)
para('O DER contém nove entidades: USUARIO, ESPECIE, ANIMAL, OCORRENCIA_ANIMAL, CIDADE, LOCALIZACAC, FOTO, CONTATO e MENSAGEM_WHATSAPP. O atributo tipo_usuario distingue os três perfis, e documento reúne a identificação informada no cadastro. Não há tabelas de especialização para cidadão, protetor ou ONG.')
image(ROOT/'docs/master-extraido/diagrama-25-0.png',10.2,'Diagrama Entidade-Relacionamento do MIAR')
para('Ocorrências se vinculam ao responsável, ao animal, à localização, às fotos e aos contatos. A entidade de mensagem integra o DER, mas o CU10 limita o WhatsApp à abertura do link de contato.')
head('1.3.3. Dicionário de Dados',True)
para('O dicionário descreve os atributos presentes no DER corrigido. PK identifica a chave primária e FK identifica a chave estrangeira. Os tipos int, text, boolean, double e date foram mantidos conforme o diagrama. Tamanhos e restrições que não aparecem no modelo não são acrescentados como requisitos.')
entities=[
 ('USUARIO','Guarda os dados de acesso e identificação dos três perfis.',[
 ('id_usuario','int, PK','Identificador do usuário.'),('nome','text','Nome informado no cadastro.'),('email','text','Endereço de acesso ao sistema.'),('senha','text','Resumo criptográfico da senha.'),('telefone','text','Telefone brasileiro com DDD.'),('documento','text','Documento de identificação informado pelo usuário.'),('tipo_usuario','text','Cidadão, protetor independente ou ONG, conforme RD01.'),('ativo','boolean','Situação do cadastro do usuário.')]),
 ('ESPECIE','Identifica a espécie do animal.',[('id_especie','int, PK','Identificador da espécie.'),('nome','text','Nome da espécie.')]),
 ('ANIMAL','Reúne as características do animal e seu vínculo com a espécie.',[
 ('id_animal','int, PK','Identificador do animal.'),('id_especie','int, FK','Referência a ESPECIE.id_especie.'),('nome','text','Nome do animal, quando informado.'),('porte','text','Porte do animal.'),('descricao','text','Descrição das características físicas.'),('idade','text','Idade do animal, quando conhecida.'),('genero','text','Gênero registrado para o animal.'),('cor','text','Cor ou características da pelagem.'),('url_foto','text','Endereço da fotografia principal.'),('data_cadastro','date','Data de cadastro do animal.')]),
 ('OCORRENCIA_ANIMAL','Registra o caso e identifica o responsável por sua manutenção.',[
 ('id_ocorrencia','int, PK','Identificador da ocorrência.'),('id_usuario_responsavel','int, FK','Referência a USUARIO.id_usuario.'),('id_animal','int, FK','Referência a ANIMAL.id_animal.'),('status_ocorrencia','text','Um dos seis status definidos no RD02.'),('descricao','text','Dados descritivos do caso, incluindo descrição física e saúde apresentadas no cadastro.'),('data_registro','date','Data de registro da ocorrência.')]),
 ('CIDADE','Identifica o município associado à localização.',[('id_cidade','int, PK','Identificador da cidade.'),('nome','text','Nome do município.'),('estado','text','Estado correspondente à cidade.')]),
 ('LOCALIZACAC','Relaciona as coordenadas e o endereço à ocorrência e à cidade. A grafia do nome da entidade foi mantida conforme o DER.',[
 ('id_localizacao','int, PK','Identificador da localização.'),('id_ocorrencia','int, FK','Referência a OCORRENCIA_ANIMAL.id_ocorrencia.'),('id_cidade','int, FK','Referência a CIDADE.id_cidade.'),('latitude','double','Latitude da ocorrência.'),('longitude','double','Longitude da ocorrência.'),('endereco','text','Endereço de referência, quando informado.')]),
 ('FOTO','Identifica os arquivos de imagem associados à ocorrência.',[
 ('id_foto','int, PK','Identificador da fotografia.'),('id_ocorrencia','int, FK','Referência a OCORRENCIA_ANIMAL.id_ocorrencia.'),('url_storage','text','Endereço do arquivo no armazenamento de objetos.'),('descricao','text','Descrição da fotografia.'),('data_upload','date','Data de armazenamento da fotografia.')]),
 ('CONTATO','Mantém os dados de contato associados à ocorrência.',[
 ('id_contato','int, PK','Identificador do contato.'),('id_ocorrencia','int, FK','Referência a OCORRENCIA_ANIMAL.id_ocorrencia.'),('numero_whatsapp','text','Telefone brasileiro com DDD.'),('whatsapp_link','text','Link de abertura do contato no WhatsApp.'),('data_contato','date','Data de cadastro do contato.')]),
 ('MENSAGEM_WHATSAPP','Representa a estrutura de mensagem vinculada a um contato no DER. Sua presença no modelo não cria uma conversa interna no aplicativo.',[
 ('id_mensagem','int, PK','Identificador da mensagem.'),('id_contato','int, FK','Referência a CONTATO.id_contato.'),('texto','text','Conteúdo textual previsto na estrutura de mensagem.'),('remetente','text','Identificação textual do remetente.'),('data_envio','date','Data de envio prevista na estrutura de mensagem.')])]
for name,description,attrs in entities:
    para('Entidade '+name,bold=True,indent=False,keep=True)
    p=para(description);p.paragraph_format.keep_with_next=True
    t=table(['Atributo','Tipo e chave','Descrição'],attrs,[3.7,2.0,5.1],10.5)
    for row in t.rows[:-1]:
        for cell in row.cells:
            for p in cell.paragraphs:p.paragraph_format.keep_with_next=True
    for row in t.rows[1:]:
        for run in row.cells[0].paragraphs[0].runs:run.font.size=Pt(9.5)
para('A localização é única por ocorrência e obrigatória no cadastro. Fotos e contatos admitem vários registros por ocorrência, e cada contato admite várias mensagens. O status determina a disponibilidade do contato público, conforme o RD06.')
para('Resultados de análise e avisos permanecem em arquivos persistentes da camada de serviços, vinculados às ocorrências, sem uma tabela adicional. Descrição física e saúde integram os dados descritivos da ocorrência.')

head('1.4. Projeto de Interface do Sistema',True)
para('Os protótipos apresentam as nove janelas do MIAR e as funções previstas nos requisitos.')
screens=[
 ('Login','Na janela de Login, o usuário informa e-mail e senha para acessar o sistema. A opção Criar conta abre o cadastro (RF01 e CU02).'),
 ('Criação de Cadastro','A janela de Criação de Cadastro permite selecionar Cidadão, Protetor ou ONG e informar os dados pessoais e de acesso. O documento identifica o usuário, sem criar tabelas distintas para os perfis (RF01, RD01 e CU01).'),
 ('Galeria de Ocorrências','A Galeria de Ocorrências apresenta fotografias, espécie, porte, cidade, data e status. O usuário pode abrir um registro e aplicar filtros por status, espécie, porte e cidade (RF03, CU03 e CU04).'),
 ('Radar de Resgate','O Radar de Resgate apresenta as ocorrências em um mapa. A seleção de um marcador abre o resumo do caso. O acesso é destinado a protetores e ONGs, conforme o CU09 (RF04 e RD03).'),
 ('Detalhe da Ocorrência','A janela de Detalhe da Ocorrência reúne fotografias, descrição física, saúde, localização e data do registro. O contato via WhatsApp fica disponível enquanto o status permitir contato público (RF02, RF07 e RD06).'),
 ('Cadastro de Ocorrência','No Cadastro de Ocorrência são informados fotografias, espécie, porte, status, descrição física, saúde, cidade, GPS e telefone. A análise das imagens integra a conclusão do cadastro (RF02 e CU05).'),
 ('Gerenciamento de Ocorrências','O Gerenciamento de Ocorrências apresenta apenas os registros do usuário autenticado. O menu permite alterar os dados, selecionar um dos seis status e excluir uma ocorrência própria (RF02, RF08, RD04, CU07 e CU08).'),
 ('Possível Correspondência','A janela de Possível Correspondência apresenta as fotografias relacionadas, o percentual de semelhança e a data da análise. O responsável pode abrir a outra ocorrência para conferir seus dados (RF05, RF06, CU11 e CU12).'),
 ('Perfil do Usuário','O Perfil do Usuário apresenta os dados cadastrais, identifica o perfil e oferece as opções de atualização e encerramento da sessão (RF01, RD01 e CU02).')]
for i,(title,description) in enumerate(screens):
    p=para(description,keep=True)
    if i:p.paragraph_format.page_break_before=True
    image(ROOT/f'evidencias/auditoria-2026-11-11/referencias-visuais/pagina-{38+i}.jpeg',5.1,'Janela de '+title)

head('1.5. Conclusão',True)
para('O projeto MIAR reuniu o registro de ocorrências, a consulta de animais, o mapa e o contato com o responsável em um aplicativo móvel. Os requisitos e casos de uso ajudaram a definir as permissões de cada usuário e as informações necessárias em cada registro.')
para('A modelagem relacionou os dados de usuários, animais, ocorrências e contatos, enquanto os protótipos mostraram como essas informações seriam apresentadas nas nove janelas principais. Esse trabalho permitiu acompanhar uma funcionalidade desde sua descrição nos requisitos até sua representação no banco e na interface. Também evidenciou a necessidade de conferir esses elementos em conjunto para evitar regras diferentes para a mesma operação.')
para('A implementação foi exercitada no Android, incluindo fotografias, localização, atualização de status e avisos de correspondência. A comparação de imagens oferece uma indicação para conferência do responsável; ela não substitui essa verificação. Como continuidade do projeto, ficam a validação em iOS, a configuração da implantação definitiva e a avaliação da comparação com fotografias de animais previamente identificados.')
head('1.6. Bibliografia',True)
references=[
 'FLUTTER. Flutter architectural overview. Disponível em: https://docs.flutter.dev/resources/architectural-overview. Acesso em: 11 nov. 2026.',
 'HOWARD, Andrew et al. Searching for MobileNetV3. 2019. Disponível em: https://arxiv.org/abs/1905.02244. Acesso em: 11 nov. 2026.',
 'NESTJS. Documentation. Disponível em: https://docs.nestjs.com/. Acesso em: 11 nov. 2026.',
 'OBJECT MANAGEMENT GROUP. Unified Modeling Language, version 2.5.1. 2017. Disponível em: https://www.omg.org/spec/UML/2.5.1. Acesso em: 11 nov. 2026.',
 'OPENSTREETMAP FOUNDATION. Tile usage policy. Disponível em: https://operations.osmfoundation.org/policies/tiles/. Acesso em: 11 nov. 2026.',
 'POSTGRESQL GLOBAL DEVELOPMENT GROUP. PostgreSQL 16 documentation. Disponível em: https://www.postgresql.org/docs/16/. Acesso em: 11 nov. 2026.',
 'PYTORCH. mobilenet_v3_small. Torchvision documentation. Disponível em: https://docs.pytorch.org/vision/stable/models/generated/torchvision.models.mobilenet_v3_small.html. Acesso em: 11 nov. 2026.'
]
for item in references:
    p=para(item,indent=False,align=WD_ALIGN_PARAGRAPH.LEFT);p.paragraph_format.space_after=Pt(12);p.paragraph_format.line_spacing=1;p.paragraph_format.keep_together=True

d.core_properties.title='PROJETO MIAR: Mapeamento e identificação de animais de risco'
d.core_properties.author='; '.join(n for n,_ in members)
d.core_properties.last_modified_by='Equipe do projeto MIAR'
d.core_properties.subject='Laboratório de Engenharia de Software'
d.core_properties.comments=''
out=STAGE/'LabES_SistemaMIAR_MASTER.docx'
d.save(out)
texts=[p.text for p in d.paragraphs]+[c.text for t in d.tables for row in t.rows for c in row.cells]
assert not any(any(ch in t for ch in ['\u2013','\u2014','\u2026']) for t in texts), 'Sinal ou marcador indesejado.'
assert len(d.inline_shapes)==12
for prefix,n in [('RF',8),('RNF',6),('RD',7),('CU',12)]:
    assert all(any(f'{prefix}{i:02}' in t for t in texts) for i in range(1,n+1))
assert len(entities)==9 and len(screens)==9
result={'modelo':str(TEMPLATE),'modelo_sha256':sha(TEMPLATE),'fonte_pdf_sha256':oldsha,'backup_fonte':str(snapshot),
        'docx_rascunho':str(out),'integrantes':len(members),'requisitos':21,'casos_de_uso':12,'entidades':9,'janelas':9,
        'imagens':12,'alteracoes_semanticas':['RNF01 alinhado ao escopo movel, sem versao para computadores','Dicionario alinhado ao DER corrigido','Dados especificos de perfil centralizados no documento do usuario','Plataformas e tecnologias previstas distinguidas das validadas'],
        'referencias':references}
(WORK/'geracao.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print('DOCX gerado a partir do modelo: 21 requisitos, 12 casos de uso, nove entidades e nove prototipos.')
print(out)
