"""Consolida somente resultados comprovados, metadados do APK e documentação de entrega."""
from pathlib import Path
import hashlib,json,re

ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'evidencias/auditoria-2026-11-11'
def read(path):
    data=path.read_bytes()
    return data.decode('utf-16' if data[:2] in (b'\xff\xfe',b'\xfe\xff') else 'utf-8-sig',errors='replace')
def save(path,text):path.write_text(text,encoding='utf-8')
meta=json.loads(read(ROOT/'docs/MASTER.json'))
assert not meta.get('modelo_academico'), 'Relatório histórico: não sobrescrever a revisão acadêmica atual.'
visual=json.loads(read(ROOT/'docs/master-apendice.json'))
assert meta['paginas']>46 and visual['total_imagens']>=50
assert hashlib.sha256((ROOT/meta['arquivo']).read_bytes()).hexdigest()==meta['sha256']
assert 'pass 35' in read(OUT/'api-testes.txt')
assert '+26: All tests passed!' in read(OUT/'flutter-testes.txt')
assert 'No issues found!' in read(OUT/'flutter-analyze.txt')
assert '1 passed' in read(OUT/'ia-testes.txt')
reports=['android-ensaio.json','android-integracao.json','android-dispositivo.json',
         'android26/android-dispositivo.json','android26/android-fotografia.json','catalogo-visual.json','apk-instalacao-final.json']
results={name:json.loads(read(OUT/name)) for name in reports}
assert all(r['exit_code']==0 for r in results.values()), 'Há validação final não aprovada.'
assert json.loads(read(OUT/'inicializacao.json'))['reinicio_com_marcadores_obsoletos'] is True
assert json.loads(read(OUT/'banco-principal-pos-auditoria.json'))['preservado'] is True
apk=ROOT/'entrega/MIAR-android.apk'
assert 'Verifies' in read(OUT/'apk-assinatura.txt')
assert "versionCode='3'" in read(OUT/'apk-manifesto.txt')
count=visual['total_imagens']
version={'especificacao':meta['arquivo'],'master_sha256':meta['sha256'],
 'master_original_sha256':meta['original_sha256'],'arquivo':apk.name,
 'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'versao':'1.0.0+3','tipo':'debug',
 'api':'http://10.0.2.2:3000','validado_em':'2026-11-11',
 'plataforma_validada':'Android API35: fluxo completo e APK final; Android8 API26: GPS, fotos, compressao, sessao protegida e notificacoes em testes dedicados',
 'ios':'nao compilado ou validado neste Windows','imagens_no_master':count,
 'parecer':'docs/PARECER_DE_ENTREGA.md','conformidade_integral_aprovada':False}
save(ROOT/'entrega/versao.json',json.dumps(version,ensure_ascii=False,indent=2)+'\n')

path=ROOT/'docs/PARECER_DE_ENTREGA.md';text=read(path)
text=text.replace('**EM CONSOLIDAÇÃO — consultar o resultado final ao término da auditoria.**',
 '**Parecer: apto para demonstração local em Android; não aprovado como entrega integral e estritamente conforme à MASTER.**')
text=text.replace('46 páginas, SHA-256 `d20641bd7dd5e44016c56e38ae5dc2db89b775835302618fc65fe45ee3555d06`. O PDF foi preservado.',
 f'{meta["paginas"]} páginas após o apêndice autorizado. As 46 páginas originais foram preservadas por comparação de texto e renderização. SHA-256 atual: `{meta["sha256"]}`. Núcleo original: `{meta["original_sha256"]}`.')
extra=(f'\n## Catálogo completo no próprio MASTER\n\n'
 f'O apêndice começa na página 47 e incorpora **{count} imagens**, com índice clicável, legendas e vínculo aos requisitos. '
 'Documenta as nove janelas, inicialização, três cadastros/perfis, edição, formulários em partes, filtros, resultados vazios, menus, status, confirmação de exclusão, contato encerrado e erros. '
 'As imagens são embutidas no PDF e não dependem de pastas externas para aparecer. Vazios/falhas induzidos no cliente estão identificados. '
 'As páginas 38–46 continuam sendo os protótipos de referência, sem substituir alvos por capturas que fariam a comparação se validar sozinha.\n\n'
 'O manifesto `docs/master-apendice.json` relaciona cada imagem, checksum e página e registra a igualdade das 46 páginas originais. '
 'Os relatórios funcionais que registram o checksum original referem-se a esse núcleo preservado. O apêndice não acrescenta requisitos de negócio.\n\n'
 'Android API35: ensaio completo da UI, nove janelas e recursos nativos aprovados. Android API26/8.0: GPS, compressão, negação/permissão de notificação, agendamento, galeria, câmera, persistência das fotos e leitura da sessão protegida aprovados em testes dedicados. '
 'O roteiro amplo no API26 foi interrompido na preparação inicial da câmera do emulador e não é apresentado como aprovado; a fotografia foi verificada separadamente após o preparo. '
 'Isso é distinto de teste em aparelho físico ou iOS.\n')
if '## Catálogo completo no próprio MASTER' not in text:text+=extra
save(path,text)

path=ROOT/'docs/IMPLEMENTACAO.md';text=read(path)
text=text.replace('recebido em 10/11/2026, 46 páginas.',f'núcleo recebido em 10/11/2026 com 46 páginas; atualizado por autorização em 11/11/2026 para {meta["paginas"]} páginas com {count} capturas no apêndice.')
text=text.replace('SHA-256: '+meta['original_sha256']+'.','SHA-256 atual: '+meta['sha256']+'. Núcleo original: '+meta['original_sha256']+'.')
text=text.replace('O PDF não foi editado.','O apêndice de capturas foi acrescentado por solicitação expressa; as 46 páginas originais não tiveram texto ou aparência alterados.')
validation=('## Validação e limites\n\n'
 'Auditoria concluída em 11/11/2026: **35 testes da API, 26 de widgets/domínio e um teste Python aprovados; análise estática limpa**. '
 'Inclui modelo/PK/FK/cardinalidades, migração e restauração, rollback, titularidade, seis status, filtragem, concorrência de fotos, recuperação de mapa e acessibilidade de campos. '
 'Consultas locais com 1.200 registros, 80 requisições e cinco simultâneas: máximo 67,34 ms.\n\n'
 'Ensaio completo pela interface Android API35 aprovado, com os três perfis, fotografia da galeria e câmera, GPS, edição, seis status, radar, IA e exclusão. '
 'No Android8/API26, testes dedicados aprovaram GPS, compressão, sessão protegida, galeria/câmera, persistência de fotos, notificações negadas/permitidas e agendamento. '
 'Roteiro amplo do API26 interrompido na preparação do aplicativo de câmera; não é declarado aprovado. '
 'São emuladores, sem equivalência automática a aparelhos físicos/iOS.\n\n'
 f'O MASTER contém {count} imagens no apêndice e conserva suas 46 páginas originais. APK de desenvolvimento 1.0.0+3, assinatura verificada, instalado e aberto, API local 10.0.2.2:3000. '
 'Resultados e metadados em `../evidencias/auditoria-2026-11-11/` e `../entrega/versao.json`.\n\n'
 '**Aderência integral não aprovada.** A comparação visual encontrou diferenças efetivas, listadas no [parecer](PARECER_DE_ENTREGA.md). '
 'iOS13+ está configurado, sem build/ensaio. PostGIS/pgvector não estão disponíveis no PostgreSQL portátil; containers não foram executados. '
 'HTTP local de desenvolvimento não comprova os protocolos seguros da p.23. O PDF original ainda contém conclusão/bibliografia por completar.\n\n'
 'MobileNetV3/ImageNet usa pesos e descritores reais; percentual é similaridade de cosseno e não probabilidade calibrada de identidade. '
 'Não existe conjunto rotulado para afirmar precisão em animais individuais, nem critério quantitativo definido pelo PDF. '
 'Notificações dependem de permissão/agendamento do sistema e não garantem entrega imediata com app forçadamente encerrado. '
 'O link WhatsApp foi verificado sem enviar mensagens ou afirmar teste de uma conversa autenticada real.\n')
text=text.split('## Validação e limites')[0]+validation
save(path,text)
path=ROOT/'AUDITORIA_CONFORMIDADE.md';text=read(path).replace('Preservado byte a byte.',f'As 46 páginas originais estão preservadas por texto e renderização. O apêndice autorizado em 11/11 contém {count} capturas reais; metadados em docs/master-apendice.json.')
save(path,text)
path=ROOT/'README.md';text=read(path)
note=(f'**Auditoria de 11/11/2026:** versão Android local demonstrada; aderência integral ao documento ainda não aprovada. '
 f'O próprio PDF MASTER recebeu {count} capturas no apêndice, preservando os requisitos e protótipos originais. '
 'Veja o [parecer de entrega](docs/PARECER_DE_ENTREGA.md) para testes, diferenças visuais e pendências.\n\n')
if '**Auditoria de 11/11/2026:**' not in text:text=text.replace('## Executar neste Windows',note+'## Executar neste Windows',1)
save(path,text)
save(ROOT/'RETOMADA.md',f'# MIAR — auditoria concluída em 11/11/2026\n\nMASTER único: docs/LabES_SistemaMIAR_1011.pdf, {meta["paginas"]} páginas e {count} capturas no apêndice autorizado. Primeiras46 páginas preservadas. DER p25 para persistência, requisitos para comportamento; protótipos pp38–46 continuam sendo os alvos visuais.\n\nAndroid local funcional e ensaiado; 35 testes API, 26 Flutter e um Python aprovados. Android API35: UI completa e APK final; API26: recursos nativos em testes dedicados. Parecer detalhado: docs/PARECER_DE_ENTREGA.md. APK1.0.0+3 em entrega/MIAR-android.apk, checksum em entrega/versao.json.\n\nNão declarar conformidade integral: diferenças visuais, iOS sem build, extensões PostGIS/pgvector e TLS não validados no ambiente portátil. O texto original da conclusão/bibliografia do PDF ainda requer revisão autoral. Nada foi publicado.\n')
for prefix,total in [('RF',8),('RNF',6),('RD',7),('CU',12)]:
    assert all(f'{prefix}{i:02}' in read(ROOT/'docs/PARECER_DE_ENTREGA.md') for i in range(1,total+1))
final={'data':'2026-11-11','veredito':'apto_demonstracao_android_local; conformidade_integral_nao_aprovada',
       'master_sha256':meta['sha256'],'master_requisitos_original_sha256':meta['original_sha256'],
       'apk_sha256':version['apk_sha256'],'capturas_no_master':count,'paginas_master':meta['paginas'],
       'api_pass':35,'flutter_pass':26,'python_pass':1,'evidencias_nativas':results,
       'limites':'Parecer de entrega; sem iOS, publicacao, precisao individual calibrada ou protocolo seguro comprovado.'}
save(OUT/'resultado-final.json',json.dumps(final,ensure_ascii=False,indent=2)+'\n')
print(f'Auditoria consolidada: {count} imagens no MASTER; APK1.0.0+3; parecer e metadados atualizados.')
