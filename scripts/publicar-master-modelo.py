"""Publica o par Word/PDF conferido e atualiza as referências da documentação."""
from pathlib import Path
import os,json,hashlib,re,shutil
import pymupdf

ROOT=Path(__file__).resolve().parent.parent
stage=Path(os.environ['LOCALAPPDATA'])/'MiarDev/376eb84567/documentacao'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:p.read_text(encoding='utf-8-sig')
write=lambda p,s:p.write_text(s,encoding='utf-8')
data=json.loads(read(ROOT/'.runtime/revisao-modelo/geracao.json'))
qa=json.loads(read(ROOT/'.runtime/revisao-modelo/conferencia.json'))
word_qa=json.loads(read(ROOT/'.runtime/revisao-modelo/word-paginas.json'))
assert qa['paginas']==word_qa['paginas'] and qa['imagens']==12 and qa['tabelas']==26
assert not any(p['fora_da_margem'] for p in qa['detalhes'])
assert Path(data['backup_fonte']).is_file()
meta=json.loads(read(ROOT/'docs/MASTER.json'))
previous=meta['sha256']
old_audit='8df799ce277593a416a75e4edf56be663590f825b759630ef24a0b3614cb62b0'
pdf=ROOT/'docs/LabES_SistemaMIAR_1011.pdf'
docx=ROOT/'docs/LabES_SistemaMIAR_MASTER.docx'
shutil.copy2(stage/'LabES_SistemaMIAR_MASTER.docx',docx)
shutil.copy2(stage/'LabES_SistemaMIAR_MASTER.pdf',pdf)
pages=pymupdf.open(pdf)
sections={}
for number in ['1.1.3.','1.1.4.','1.1.5.','1.1.6.','1.1.7.','1.2.','1.3.1.','1.3.2.','1.3.3.','1.4.','1.5.','1.6.']:
    sections[number]=next(i+1 for i,p in enumerate(pages) if re.search(r'(?m)^'+re.escape(number)+r'\s',p.get_text()))
meta.update({'arquivo':'docs/LabES_SistemaMIAR_1011.pdf','sha256':sha(pdf),'paginas':len(pages),
 'editavel':'docs/LabES_SistemaMIAR_MASTER.docx','editavel_sha256':sha(docx),
 'atualizado_em':'2026-11-11','modelo_academico':{'arquivo_origem':Path(data['modelo']).name,'sha256':data['modelo_sha256'],'formato':'A5','margens_cm':2,'secoes':'1.1 a 1.6'},
 'precedencia_confirmada':{'persistencia':'DER corrigido da seção 1.3.2, originalmente na página 25 do PDF recebido em 10/11/2026','comportamento':'Requisitos e casos de uso da seção 1.1','visual':'Nove protótipos aprovados, reunidos na seção 1.4'},
 'secoes_pagina_inicial':sections,'imagens':{'diagramas':3,'prototipos':9,'capturas_de_testes':0},
 'revisao':'docs/REVISAO_MODELO.md','fonte_anterior_preservada':data['backup_fonte']})
meta.pop('apendice_visual',None)
write(ROOT/'docs/MASTER.json',json.dumps(meta,ensure_ascii=False,indent=2)+'\n')

report=f'''# Revisão do documento conforme o modelo da professora

Em 11/11/2026, o responsável forneceu o modelo de Projeto de LabES e autorizou reorganizar o MASTER, retirar capturas desnecessárias, completar conclusão e bibliografia e corrigir a apresentação. Essa decisão substitui a solicitação anterior de incluir todas as capturas de testes no PDF.

Arquivos atuais: [PDF MASTER](LabES_SistemaMIAR_1011.pdf) e [Word editável](LabES_SistemaMIAR_MASTER.docx). São duas representações da mesma especificação.

## Organização

O documento mantém as seções e a ordem do modelo, de 1.1 a 1.6, o papel A5 e as quatro margens de 2 cm. A capa conserva os cinco integrantes, seus RAs, a professora e a instituição. Os ajustes de espaçamento acomodam os cinco autores sem criar uma segunda página de capa.

A seção 1.4 apresenta os nove protótipos aprovados, com descrição e legenda. As 63 capturas da auditoria foram retiradas do trabalho acadêmico e continuam em evidencias/auditoria-2026-11-11. Permanecem os três diagramas aprovados, sem alteração de pixels.

## Revisão de conteúdo

Foram preservados os identificadores dos 21 requisitos e dos 12 casos de uso. Vinte requisitos mantêm o texto recebido. O RNF01 foi ajustado para celulares e tablets, resolvendo sua contradição com a plataforma móvel, que já excluía web e desktop. O cenário normal do CU01 foi alinhado aos campos de cadastro do DER corrigido, sem tabelas de especialização de usuário.

O dicionário foi refeito a partir das nove entidades e dos 50 atributos do DER. A grafia LOCALIZACAC foi mantida para corresponder ao diagrama aprovado. A presença de MENSAGEM_WHATSAPP não autoriza chat interno ou envio automático. A conclusão descreve o trabalho realizado e as validações pendentes. A bibliografia reúne sete fontes primárias consultadas e citadas no texto.

O texto técnico distingue implementação local, plataformas previstas e recursos ainda não validados. Não foram acrescentadas funções de negócio ao aplicativo. Esta revisão documental não elimina as pendências de implementação registradas na auditoria anterior.

## Conferência

O PDF tem {len(pages)} páginas, sem páginas vazias, e o Word também foi paginado em {word_qa['paginas']} páginas pelo Microsoft Word. Foram conferidos os títulos e a ordem das seções, os cabeçalhos das três tabelas de requisitos e os nove rótulos de cada quadro de caso de uso contra o modelo. A fonte dos títulos é Calibri, com 14 pontos nas seções principais e 12 nos subtítulos. As legendas usam Calibri 12, em preto e sem negrito, conforme o modelo. O corpo usa Calibri 12 com espaçamento de 1,5 linha; os quadros recebem ajustes de tamanho para acomodar o conteúdo no papel A5.

A comparação do texto abrange todos os parágrafos e todas as células: o PDF contém o conteúdo do Word, desconsiderando apenas espaços e quebras de linha. As doze imagens do Word correspondem aos pixels das fontes. Foram verificados os limites das margens para texto e imagens, a integridade dos acentos, a ausência de campos provisórios, travessões e emojis no texto e os 50 atributos do dicionário. O corretor de português do Word apresentou somente candidatos associados a nomes próprios, identificadores e termos técnicos, revisados individualmente.

A revisão visual abrangeu todas as páginas renderizadas. Foram corrigidos trechos isolados, divisão inadequada de tabelas, separação entre títulos e figuras, vazamento dos diagramas na margem e a distribuição da conclusão e da bibliografia. O PDF foi exportado pelo LibreOffice 26.8.2.2; o Word foi aberto e repaginado no Microsoft Word 16.0.

PDF SHA-256: `{sha(pdf)}`.

Word SHA-256: `{sha(docx)}`.

## Histórico preservado

O PDF anterior de 82 páginas, SHA-256 `{old_audit}`, permanece fora da pasta do projeto em `{data['backup_fonte']}`. O original recebido em Downloads não foi alterado. Os relatórios de testes anteriores continuam associados aos arquivos e às condições avaliadas naquela ocasião.

Para reproduzir a preparação, executar gerar-master-modelo.py, exportar-master-modelo.ps1, conferir-master-modelo.py e, após revisar as renderizações, publicar-master-modelo.py, todos em scripts/. O modelo original e as fontes de imagem precisam estar nos caminhos registrados nesses scripts. Os scripts antigos de apêndice e encerramento da auditoria recusam sobrescrever esta revisão acadêmica.
'''
write(ROOT/'docs/REVISAO_MODELO.md',report)
write(ROOT/'docs/revisao-modelo.json',json.dumps({**data,'conferencia':qa,'pdf_sha256':sha(pdf),'docx_sha256':sha(docx),'secoes_pagina_inicial':sections,'paginacao_word':word_qa['paginas'],'correcao_ortografica_word':'Candidatos revisados; nomes próprios, identificadores e termos técnicos','texto_word_pdf':'Todos os parágrafos e todas as células presentes, desconsiderados espaços e quebras de linha'},ensure_ascii=False,indent=2)+'\n')

p=ROOT/'README.md';text=read(p)
text=re.sub(r'A única referência \*\*MASTER\*\* é .*?(?=\n)',
 'A especificação **MASTER** está em [PDF](docs/LabES_SistemaMIAR_1011.pdf) e [Word editável](docs/LabES_SistemaMIAR_MASTER.docx), reorganizada em 11/11/2026 no modelo de LabES fornecido pela professora. O DER corrigido da seção 1.3.2 governa a persistência; os requisitos e casos de uso governam o comportamento. A seção 1.4 reúne os nove protótipos aprovados. Detalhes em [revisão do documento](docs/REVISAO_MODELO.md) e [implementação](docs/IMPLEMENTACAO.md).',text,count=1)
text=re.sub(r'\*\*Auditoria de 11/11/2026:\*\*.*?(?=\n)',
 '**Auditoria de 11/11/2026:** versão Android local demonstrada; aderência integral do aplicativo ainda não aprovada. O [parecer de entrega](docs/PARECER_DE_ENTREGA.md) preserva a avaliação da versão anterior da documentação. As capturas de testes permanecem nas evidências, fora do trabalho acadêmico. A revisão do documento não representa nova validação do aplicativo.',text,count=1)
write(p,text)

p=ROOT/'docs/IMPLEMENTACAO.md';text=read(p)
rest=text.split('## Alterações decorrentes do DER',1)[1]
rest=rest.replace('O PDF original ainda contém conclusão/bibliografia por completar.','A conclusão, a bibliografia e o dicionário foram revisados no documento atual; isso não elimina as pendências técnicas anteriores.')
write(p,'''# MIAR: implementação da MASTER

Fonte atual: [PDF MASTER](LabES_SistemaMIAR_1011.pdf), com [Word editável](LabES_SistemaMIAR_MASTER.docx). Os hashes estão em MASTER.json. A revisão acadêmica de 11/11/2026 segue o modelo da professora, sem apêndice de capturas. Consulte REVISAO_MODELO.md.

Precedência confirmada pelo responsável: DER corrigido da seção 1.3.2 para persistência; requisitos e casos de uso da seção 1.1 para comportamento; nove protótipos da seção 1.4 para interface. O DER é o mesmo que estava na página 25 do PDF recebido em 10/11/2026.

As referências de páginas abaixo registram a paginação do PDF original, antes da revisão de formato. A implementação e o APK não foram alterados nesta revisão documental.

## Alterações decorrentes do DER'''+rest)

historical='> Registro histórico anterior à reorganização no modelo da professora. A paginação e o checksum citados abaixo pertencem à versão auditada naquele momento. A revisão atual corrigiu o dicionário, a conclusão, a bibliografia e a apresentação, e retirou o apêndice de capturas. Consulte [REVISAO_MODELO.md]({link}). Os testes e as pendências técnicas do aplicativo não foram reavaliados por esta edição documental.\n\n'
for name,link in [('docs/PARECER_DE_ENTREGA.md','REVISAO_MODELO.md'),('AUDITORIA_CONFORMIDADE.md','docs/REVISAO_MODELO.md')]:
    p=ROOT/name;text=read(p)
    if not text.startswith('> Registro histórico'):write(p,historical.format(link=link)+text)

p=ROOT/'docs/master-apendice.json';old=json.loads(read(p));old['estado']='Histórico: apêndice retirado do MASTER por solicitação do responsável em 11/11/2026';old['substituido_por']='docs/REVISAO_MODELO.md';write(p,json.dumps(old,ensure_ascii=False,indent=2)+'\n')
p=ROOT/'entrega/versao.json';release=json.loads(read(p));release.update({'master_da_auditoria_sha256':old_audit,'master_sha256':sha(pdf),'imagens_no_master':12,'prototipos_de_interface_no_master':9,'documentacao_atualizada_em':'2026-11-11','revisao_documental':'docs/REVISAO_MODELO.md'});write(p,json.dumps(release,ensure_ascii=False,indent=2)+'\n')

write(ROOT/'CLAUDE.md','''# MIAR: orientações atuais

A especificação MASTER é docs/LabES_SistemaMIAR_1011.pdf, com versão editável pareada em docs/LabES_SistemaMIAR_MASTER.docx. Usar docs/MASTER.json para verificar os hashes. Em 11/11/2026, o responsável autorizou reorganizar e completar o trabalho no modelo da professora. A revisão substitui o apêndice de capturas; consultar docs/REVISAO_MODELO.md.

O DER corrigido da seção 1.3.2 governa as nove entidades, os atributos, as chaves e as cardinalidades. É o mesmo diagrama que estava na página 25 do PDF original. Requisitos e casos de uso da seção 1.1 governam o comportamento. Os nove protótipos da seção 1.4 são as referências visuais. A pilha técnica está na seção 1.2.

Não inventar funcionalidades, telas, perfis, entidades, relacionamentos ou fluxos. MENSAGEM_WHATSAPP não autoriza chat: o CU10 exclui envio automático e conversas internas. Manter os três perfis, os seis status, o telefone brasileiro, a titularidade no servidor e a supressão do contato público para Adotado e Resgatado.

O dicionário atual acompanha o DER. RNF01 foi alinhado ao escopo móvel, sem acrescentar web ou desktop. Saúde, correspondência e avisos continuam obrigatórios; consultar docs/IMPLEMENTACAO.md para suas representações técnicas.

Preservar dados por backup e migração. Testes anteriores e revisão documental não comprovam conformidade integral. docs/PARECER_DE_ENTREGA.md e AUDITORIA_CONFORMIDADE.md são registros históricos com pendências do aplicativo.

Consultar README.md, DATABASE.md, docs/IMPLEMENTACAO.md e DESIGN_SYSTEM.md antes de alterar o app. Não recolorir ou distorcer a marca nem criar nova identidade visual. A frase “Mais pessoas, mais histórias felizes” permanece excluída. Não executar os scripts antigos de apêndice ou encerramento de auditoria contra a revisão acadêmica.
''')
write(ROOT/'RETOMADA.md',f'''# MIAR: documentação revisada em 11/11/2026

MASTER em docs/LabES_SistemaMIAR_1011.pdf e docs/LabES_SistemaMIAR_MASTER.docx, com {len(pages)} páginas, 21 requisitos, 12 casos de uso, nove entidades e 50 atributos. A seção 1.4 contém nove protótipos, e o documento mantém os três diagramas aprovados. O modelo da professora orienta a capa, as margens e a ordem das seções. Conclusão, bibliografia e dicionário revisados. Não há apêndice de capturas.

DER corrigido da seção 1.3.2 para persistência; requisitos para comportamento; nove protótipos para interface. Histórico e conferência em docs/REVISAO_MODELO.md. Integridade: python scripts/verificar-master.py.

A revisão atual é documental. O APK 1.0.0+3 permanece em entrega/MIAR-android.apk, sem recompilação nesta etapa. A auditoria anterior registrou 35 testes API, 26 Flutter e um Python aprovados, com ensaios Android API35 e API26. Detalhes e limitações em docs/PARECER_DE_ENTREGA.md.

Não declarar conformidade integral do app: diferenças visuais, iOS sem build, extensões PostGIS/pgvector e TLS continuam pendentes. Nada foi publicado.
''')
print(json.dumps({'pdf':str(pdf),'word':str(docx),'paginas':len(pages),'sha256':sha(pdf),'secoes':sections},ensure_ascii=False))
