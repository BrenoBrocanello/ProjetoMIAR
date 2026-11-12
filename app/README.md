# MIAR — Flutter Android/iOS

Aplicativo das nove janelas da [MASTER](../docs/LabES_SistemaMIAR_1011.pdf), páginas 38–46. Execução, APK e limites em [README da raiz](../README.md).

- lib/presentation: janelas, componentes e viewmodels.
- lib/domain: entidades/projeções e contrato do repositório.
- lib/data: API, sessão protegida e notificações.
- assets: marca oficial, fotografia e fonte Outfit estática com licença.
- test: verificações de interface e acesso.
- integration_test: nove janelas com API real; GPS, compressão e notificações nativos.

Flutter 3.38.9 fixado em .fvmrc. API definida por --dart-define=API_URL. A configuração padrão é o servidor do computador visto pelo emulador Android (10.0.2.2:3000). Não há backend público embutido.

Cadastro e perfil usam USUARIO.documento nos três perfis, conforme o DER corrigido. Campos de instituição/fantasia foram retirados. A aparência segue as referências da MASTER.
