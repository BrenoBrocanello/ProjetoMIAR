import 'entidades.dart';

abstract class MiarRepository {
  Stream<void> mudancas();
  String fotoUrl(String caminho);
  Future<Usuario?> restaurarSessao();
  Future<Usuario> entrar(String email, String senha);
  Future<void> sair();
  Future<Usuario> cadastrar(Json dados);
  Future<Usuario> atualizarPerfil(Json dados);
  Future<PaginaOcorrencias> ocorrencias({
    Json filtros = const {},
    bool minhas = false,
    bool radar = false,
    int pagina = 0,
  });
  Future<Ocorrencia> ocorrencia(int id, {bool editar = false});
  Future<Ocorrencia> salvarOcorrencia(
    Json dados,
    List<FotografiaEnvio> fotos, {
    int? id,
  });
  Future<Ocorrencia> alterarStatus(int id, String status);
  Future<void> excluir(int id);
  Future<Uri> contato(int id);
  Future<List<Correspondencia>> correspondencias();
  Future<Correspondencia> correspondencia(int id);
  Future<void> confirmarAviso(int id);
}
