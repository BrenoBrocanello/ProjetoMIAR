> Registro histórico anterior à reorganização no modelo da professora. A paginação e o checksum citados abaixo pertencem à versão auditada naquele momento. A revisão atual corrigiu o dicionário, a conclusão, a bibliografia e a apresentação, e retirou o apêndice de capturas. Consulte [REVISAO_MODELO.md](REVISAO_MODELO.md). Os testes e as pendências técnicas do aplicativo não foram reavaliados por esta edição documental.

# Parecer de entrega MIAR — auditoria de 11/11/2026

**Parecer: apto para demonstração local em Android; não aprovado como entrega integral e estritamente conforme à MASTER.**

Referência única: [MASTER](LabES_SistemaMIAR_1011.pdf), 82 páginas após o apêndice autorizado. As 46 páginas originais foram preservadas por comparação de texto e renderização. SHA-256 atual: `8df799ce277593a416a75e4edf56be663590f825b759630ef24a0b3614cb62b0`. Núcleo original: `d20641bd7dd5e44016c56e38ae5dc2db89b775835302618fc65fe45ee3555d06`. Regra expressamente escolhida pelo responsável: DER corrigido da página 25 para persistência; requisitos para comportamento. As imagens das páginas 38–46 governam a apresentação.

## Critério de aprovação

Apresentação acadêmica local em Android, entrega integral Android/iOS e publicação são situações distintas. Os resultados abaixo demonstram comportamentos e condições efetivamente ensaiados; não provam ausência absoluta de defeitos. Uma aprovação local não permite afirmar que iOS, serviços públicos ou precisão de identificação animal estejam validados.

## Matriz completa dos requisitos

“Verificado” significa comportamento exercitado pelos testes identificados, dentro do ambiente Android/local e das condições desta auditoria. Limitações transversais de plataforma, infraestrutura e validação estão explicitadas abaixo. Não se atribuiu percentual artificial de conformidade.

| ID | Fonte | Resultado e evidência |
|---|---|---|
| RF01 | p. 3 | Verificado: cadastro dos três perfis, login, consulta/edição de dados, senha/e-mail, logout e revogação. API, widgets e ensaio nativo. |
| RF02 | p. 3 | Verificado: todos os dados obrigatórios, fotos/GPS, consulta, edição e exclusão próprias; dados inválidos e falhas não confirmam sucesso. Concorrência de fotos protegida por 409. |
| RF03 | p. 3 | Verificado: galeria, paginação, quatro filtros isolados/combinados, nenhum resultado e recuperação de erro. |
| RF04 | p. 3 | Verificado: mapa real, coordenadas gravadas, marcadores, seleção/resumo atualizado, filtros e nova tentativa de tiles. Acesso protetor/ONG segundo CU09. |
| RF05 | p. 4 | Implementado e exercitado com rede neural real: imagens iguais, alteração de brilho, outra espécie, ausência de correspondência e erro do serviço. **Precisão na identificação individual de animais não demonstrada por conjunto rotulado.** |
| RF06 | p. 4 | Estado de aviso persistido e acesso restrito ao responsável verificados. Entrega nativa depende da permissão; execução periódica depende do sistema operacional. Não equivale a push imediato com o app forçadamente encerrado. |
| RF07 | p. 4 | Link real `https://wa.me/55...` derivado do telefone validado; encerramento bloqueia link. Não há envio automático. Conversa real no WhatsApp não foi enviada nem usada como prova de teste. |
| RF08 | p. 4 | Verificados os seis estados, persistência, propagação e controle de titularidade. |
| RNF01 | p. 4 | Nove janelas e edições em 320×568, 393×852, 768×1024 e 1024×768, escalas de fonte 1 e 1,8, sem overflow nos testes. Sem versão web/desktop, conforme plataforma explicitamente definida na p. 20. |
| RNF02 | p. 4 | Verificado no ensaio local: 1.200 registros, 80 consultas HTTP, até cinco simultâneas, máximo 67,34 ms; limite documental 2.000 ms. Não extrapolado para redes/aparelhos não testados. |
| RNF03 | p. 4 | Verificados erro/retomada da galeria e mapa, falha da IA, rollback de banco/S3/resultados, migração e reinício. Período/SLA não quantificado no PDF; não se afirma disponibilidade contínua de produção. |
| RNF04 | p. 5 | Compressão JPEG real no dispositivo e servidor; tamanho reduzido, imagem válida e descritores utilizáveis. Qualidade visual humana da identificação não foi calibrada por estudo independente. |
| RNF05 | p. 5 | Autorização no servidor, três perfis, titularidade, rejeição de token inválido/revogado, hash Argon2 e token em armazenamento nativo protegido. Não constitui auditoria de invasão completa. Transporte local HTTP permanece uma diferença técnica da entrega de desenvolvimento. |
| RNF06 | p. 5 | Fluxos principais exercitados, rótulos de acessibilidade e texto ampliado verificados. Não houve estudo de usabilidade com usuários externos nem execução manual de VoiceOver/TalkBack. |
| RD01 | p. 5 | Exatamente Cidadão, Protetor independente e ONG; perfis desconhecidos/campos extras rejeitados. Documento centralizado em USUARIO segundo DER. |
| RD02 | p. 5 | Exatamente Perdido, Encontrado, Emergência, Aguardando Adoção, Adotado e Resgatado; demais valores rejeitados. |
| RD03 | p. 5 | Cidade e coordenadas obrigatórias; limites geográficos e valores inválidos testados; GPS nativo exercitado. |
| RD04 | p. 5 | Alteração de dados/status e exclusão de terceiros bloqueadas na API, inclusive acesso à projeção de edição e fotografias alheias. |
| RD05 | p. 6 | Telefone brasileiro normalizado/validado com DDD; entradas inválidas rejeitadas. |
| RD06 | p. 6 | Adotado/Resgatado ocultam telefone/link na lista, detalhe e radar; endpoint de contato retorna indisponível. O proprietário continua podendo editar. |
| RD07 | p. 6 | Nova ocorrência comparada a registros Perdido com fotos adequadas, inclusive dois registros distintos do mesmo responsável. Alteração de fotos/espécie invalida resultados antigos. |

## Matriz dos casos de uso

| ID | Página | Verificação |
|---|---|---|
| CU01 Cadastrar usuário | 7 | Três perfis, dados incompletos, telefone, e-mail repetido sem distinguir caixa e proibição de campos extras. |
| CU02 Fazer login/logout | 8 | Credenciais válidas/inválidas, sessão persistida e revogação efetiva no servidor. |
| CU03 Consultar animais | 9 | Galeria/detalhe reais, dados atuais, resultado vazio, erro recuperável. |
| CU04 Filtrar animal | 10 | Status, espécie, porte e cidade; combinação e limpeza. |
| CU05 Cadastrar ocorrência | 11 | Fotografias, compressão, GPS/cidade, dados físicos/saúde e contato; sem persistência parcial ao falhar. |
| CU06 Visualizar status | 12 | Rótulos dos seis estados na galeria/detalhe/radar e contato encerrado. |
| CU07 Alterar status | 13 | Responsável altera; terceiro recebe rejeição. Seis valores ensaiados pela interface. |
| CU08 Excluir ocorrência | 14 | Confirmação, exclusão própria, cascatas, arquivos e rejeição de terceiro. |
| CU09 Visualizar radar | 15 | Protetor/ONG autorizados; cidadão bloqueado no servidor. Mapa, marcador e resumo reais, recuperação e atualização de seleção. |
| CU10 Contatar responsável | 16 | Número/link verificados, bloqueio para encerradas; MENSAGEM_WHATSAPP não recebe conversa e não existe envio automático/chat. |
| CU11 Analisar imagem | 17 | Serviço Python/rede neural, comparação positiva/negativa, estado inválido/erro externo, registro e invalidação de resultados. Limite de precisão descrito abaixo. |
| CU12 Notificar possível correspondência | 18 | Responsável correto, consulta/abertura de comparação, permissão negada mantém Pendente, emissão confirma Emitida e persiste após reinício. Agendamento do sistema não assegura entrega imediata. |

## DER e diagrama de classes

A suíte da API compara as nove tabelas, todas as colunas/tipos, PKs, FKs e cardinalidades com a página 25. São **USUARIO, ESPECIE, ANIMAL, OCORRENCIA_ANIMAL, CIDADE, LOCALIZACAC, FOTO, CONTATO e MENSAGEM_WHATSAPP**. LOCALIZACAC mantém a grafia literal do DER. São permitidos animal compartilhado entre ocorrências, múltiplas fotos/contatos e múltiplas mensagens por contato; localização é no máximo uma por ocorrência no banco e obrigatória no cadastro pelo aplicativo. Datas são `date` conforme o DER.

Não foram acrescentadas tabelas CIDADAO/PROTETOR/ONG ou CORRESPONDENCIA_IA do modelo antigo. O estado técnico de correspondência/aviso fica em arquivos protegidos por banco/origem e exige backup próprio. Saúde e descrição física usam representação versionada no atributo `OCORRENCIA_ANIMAL.descricao`. São soluções para cumprir os requisitos sem alterar o DER; não constituem uma transação distribuída entre banco, S3 e arquivos. Uma queda abrupta entre operações pode exigir recuperação/reanálise.

As classes de domínio e enumerações da p. 24 estão representadas em `app/lib/domain/entidades.dart` e `modelo.dart`; as operações são distribuídas entre casos de uso/viewmodels, repositórios e serviços. Não é uma cópia literal de assinaturas UML: por exemplo, a senha não volta no objeto do usuário, exclusão segue CU08, e não se expõe CRUD independente de espécies/cidades nem inativação de usuário ausentes dos requisitos. `MensagemWhatsapp.enviar()` no desenho conflita com CU10/p. 23: não foi implementado envio/captura de conversas. A precedência comportamental foi respeitada.

Migração de modelo anterior, snapshot lógico completo com checksum, restauração em banco local vazio, manutenção de IDs/credenciais/fotos/contatos e rollback foram executados em bancos isolados. O banco principal não foi usado para inserir dados fictícios.

## Escopo e referências visuais

O inventário AST registra 21 endpoints: autenticação/usuários, ocorrências, fotos, radar/mapa, contato e correspondências. Os 11 caminhos Flutter correspondem às nove janelas, variante de edição da ocorrência e carga inicial. Edição do perfil/modal de status integram suas janelas originais.

Não foram encontrados painel administrativo/indicadores, autenticação social, recuperação de senha, chat interno, favoritos, avaliações de instituições ou histórico de adoções. Paginação, SSE, permissões, retry e background fetch são mecanismos para os requisitos existentes, sem novos módulos de negócio. A tabela MENSAGEM_WHATSAPP é mantida pelo DER e não cria uma função de conversa interna.

Há parâmetros operacionais escolhidos na implementação que o PDF não quantifica: até seis fotos por ocorrência, 10 MiB por arquivo recebido, imagem normalizada em JPEG até 1600×1600 com qualidade 85, comprimentos máximos dos campos, paginação, intervalos de atualização e limiar de similaridade 0,90. São decisões técnicas, incluindo restrições de entrada, e **não requisitos expressamente fornecidos pela professora**. Por isso também não se declara identidade literal entre todo comportamento possível e o documento.

As nove referências são Login, Criar Cadastro, Galeria, Radar, Detalhe, Cadastrar Ocorrência, Gerenciar, Possível Correspondência e Perfil. Conferir o comparativo visual e capturas vinculados às evidências. Paleta Pastel Aurora, gradientes, tipografia Outfit, marca, cartões e navegação seguem a referência. Fotos/dados são reais de teste, e não os registros fictícios impressos no protótipo. A moldura de telefone do PDF não é parte da interface. Campos do modelo anterior foram removidos conforme DER; mensagens de erro/vazio/permissão e adaptação à tela são necessárias aos casos alternativos. Isso não permite afirmar igualdade pixel a pixel em qualquer aparelho.

**Conformidade visual parcial:** [comparativo das nove janelas](../evidencias/auditoria-2026-11-11/comparativo-visual.jpg), construído com as imagens originais extraídas e capturas nativas atuais, conferido visualmente. Além de diferenças naturais de dados, viewport e moldura, existem diferenças efetivas de composição/controles:

| Referência | Diferença observada na implementação |
|---|---|
| Cadastro, p. 39 | Espaçamento/proporções fazem o botão de criação ficar abaixo da primeira área visível; documento é um campo único, conforme DER aprovado. |
| Radar, p. 41 | Cabeçalho/filtros têm disposição diferente do cartão do protótipo. Cartografia real OpenStreetMap substitui o desenho esquemático; o resumo selecionado funciona e foi capturado no ensaio completo. |
| Cadastro de ocorrência, p. 43 | Espécie/porte estão empilhados, status usa dropdown em vez de chips, saúde usa texto livre em vez das opções visuais, localização aparece em campos/GPS em vez de cartão compacto com “Ajustar”. Os dados funcionais estão presentes, mas a composição não é idêntica. |
| Gerenciamento, p. 44 | Os seis estados aparecem em chips, mas com distribuição/proporções diferentes no modal. |
| Correspondência, p. 45 | Ordem entre título/aviso diferente; não exibe distância entre registros nem horário junto à data como na imagem de referência. |
| Perfil, p. 46 | Avatar genérico em vez da ilustração e telefone exibido sem máscara; proporções/posições de elementos diferem. |

Essas diferenças não foram encobertas por um resultado “todos os testes passaram”. É necessária uma rodada de alinhamento visual para declarar fidelidade estrita às referências solicitadas pelo responsável. A comparação não confunde ausência de registros fictícios ou seleção de outro animal/status com defeito visual.

## Falhas encontradas e corrigidas nesta auditoria

1. Marcadores antigos faziam o inicializador afirmar que os serviços estavam ativos quando não estavam. Agora verifica processo proprietário e resposta real da API; não encerra PIDs alheios e preserva dados.
2. Duas edições simultâneas de fotografias podiam responder sucesso e deixar ocorrência sem fotos. Trava/revalidação retorna conflito 409 para a edição obsoleta. Falha anterior e regressão estão preservadas.
3. Campos expunham somente placeholder ao leitor de tela. Rótulos semânticos explícitos foram adicionados sem alterar a composição visual.
4. Inicialização do background fetch falhava no Android por ausência de ACCESS_NETWORK_STATE. Permissão normal adicionada e configuração nativa incluída na regressão.
5. “Tentar novamente” no mapa não refazia os downloads que falharam. A camada de tiles passa a ser recriada e a recuperação HTTP 503→200 foi verificada.
6. Resumo selecionado do mapa conservava uma versão antiga do registro. Agora resolve o registro atual pelo ID; atualização de status e exclusão são verificadas por eventos.

## Diferenças e pendências para entrega integral

- **Referências visuais:** divergências concretas nas pp. 39, 41 e 43–46, discriminadas acima. A identidade visual é próxima; não está comprovada a reprodução estrita solicitada.
- **iOS 13+:** projeto/configuração presentes, mas sem compilação, assinatura, instalação ou ensaio nativo por ausência de macOS/Xcode. Não há IPA aprovado.
- **PostGIS/pgvector (p. 21):** ausentes do PostgreSQL portátil executado. Mapa usa coordenadas; similaridade usa cosseno na API. Configuração de containers existe, mas não foi executada, pois não há Docker instalado. Aderência tecnológica integral não comprovada.
- **Protocolos seguros (p. 23):** ambiente de desenvolvimento usa HTTP local para API, S3 e IA. Não foi validada implantação com TLS, certificados e assinatura de distribuição. Nenhum backend público foi entregue.
- **IA:** MobileNetV3/ImageNet gera descritores reais de 576 dimensões; limiar técnico 0,90 não foi especificado pela professora. Percentual é similaridade de cosseno, não probabilidade calibrada de identidade. Os testes comprovam execução e alguns pares controlados; não comprovam acurácia em animais individuais variados.
- **WhatsApp:** validação de link/telefone e passagem ao sistema não comprovam uma conversa autenticada em aplicativo WhatsApp real. Nenhuma mensagem foi enviada.
- **Documento:** a p. 46 contém literalmente “Concluindo...” e Bibliografia sem entradas. Persistem textos do modelo antigo e divergências documentadas em [AUDITORIA_CONFORMIDADE.md](../AUDITORIA_CONFORMIDADE.md). Se o PDF também for entregue, esses pontos precisam de revisão autoral; a MASTER não foi alterada pela auditoria.

## Evidências e reprodução

Diretório desta rodada: [evidencias/auditoria-2026-11-11](../evidencias/auditoria-2026-11-11/). Relatórios anteriores estão separados e não substituem os resultados atuais.

- `api-testes.txt`: 35 testes aprovados, incluindo migração/restauração, falhas e concorrência.
- `desempenho.json`: distribuição de consultas local com volume/simultaneidade explicitados.
- `flutter-testes.txt`: 26 testes aprovados, incluindo matriz de telas/fontes e semântica.
- `flutter-analyze.txt`: análise estática.
- `ia-testes.txt`: teste do modelo Python com pesos reais; `dependencias-python.txt`: consistência de dependências.
- `dependencias-api.json`: auditoria npm das dependências de produção sem vulnerabilidades conhecidas reportadas nesta execução; não inclui avaliação de invasão.
- `escopo-e-acesso.json`: inventário de rotas/classes e guardas; comportamento de autorização também exercitado pela API.
- `inicializacao.json`: marcadores antigos, identificação de processo, idempotência e reinício.

API: `cd api`, `npm.cmd run build`, `npm.cmd test` com infraestrutura local e sem outro servidor de testes usando 3301. Flutter: SDK 3.38.9 fixado, `flutter analyze --no-pub`, `flutter test --no-pub`. Ensaio nativo: API isolada em 3301, staging sem acentos atualizado pelo gerador, `python scripts/ensaiar-app.py` e `python scripts/validar-android.py dispositivo`. Somente AVDs de auditoria e banco `miar_test`; não usar banco de terceiros. Os scripts guardam os códigos de saída reais.

O APK em `entrega/` é de desenvolvimento e depende do servidor deste computador, com `10.0.2.2:3000` para o emulador. Copiar esse APK para outro computador/celular não fornece automaticamente o backend. Versão e checksum devem corresponder a `entrega/versao.json`.

## Catálogo completo no próprio MASTER

O apêndice começa na página 47 e incorpora **63 imagens**, com índice clicável, legendas e vínculo aos requisitos. Documenta as nove janelas, inicialização, três cadastros/perfis, edição, formulários em partes, filtros, resultados vazios, menus, status, confirmação de exclusão, contato encerrado e erros. As imagens são embutidas no PDF e não dependem de pastas externas para aparecer. Vazios/falhas induzidos no cliente estão identificados. As páginas 38–46 continuam sendo os protótipos de referência, sem substituir alvos por capturas que fariam a comparação se validar sozinha.

O manifesto `docs/master-apendice.json` relaciona cada imagem, checksum e página e registra a igualdade das 46 páginas originais. Os relatórios funcionais que registram o checksum original referem-se a esse núcleo preservado. O apêndice não acrescenta requisitos de negócio.

Android API35: ensaio completo da UI, nove janelas e recursos nativos aprovados. Android API26/8.0: GPS, compressão, negação/permissão de notificação, agendamento, galeria, câmera, persistência das fotos e leitura da sessão protegida aprovados em testes dedicados. O roteiro amplo no API26 foi interrompido na preparação inicial da câmera do emulador e não é apresentado como aprovado; a fotografia foi verificada separadamente após o preparo. Isso é distinto de teste em aparelho físico ou iOS.
