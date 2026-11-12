import 'modelo.dart';
export 'modelo.dart' hide Foto;

const perfis = ['Cidadão', 'Protetor independente', 'ONG'];
const portes = ['Pequeno', 'Médio', 'Grande'];
const statusOcorrencia = [
  'Perdido',
  'Encontrado',
  'Emergência',
  'Aguardando Adoção',
  'Adotado',
  'Resgatado',
];
typedef Json = Map<String, dynamic>;

class Usuario {
  final Json dados;
  Usuario(this.dados);
  int get id => dados['id_usuario'] as int;
  String get nome => dados['nome'] as String;
  String get email => dados['email'] as String;
  String get telefone => dados['telefone'] as String;
  String? get documento => dados['documento'] as String?;
  bool get ativo => dados['ativo'] == true;
  String get perfil => dados['tipo_usuario'] as String;
  TipoUsuario get tipo =>
      TipoUsuario.values.firstWhere((t) => t.rotulo == perfil);
  bool get podeVerRadar => tipo != TipoUsuario.cidadao;
}

class OcorrenciaAnimal {
  final Json dados;
  OcorrenciaAnimal(this.dados);
  int get id => dados['id_ocorrencia'] as int;
  int get responsavelId => dados['id_usuario_responsavel'] as int;
  String get especie => dados['especie'] as String;
  String get porte => dados['porte'] as String;
  String get status => dados['status_ocorrencia'] as String;
  String get descricao => dados['descricao_fisica'] as String;
  String get saude => dados['estado_saude'] as String;
  Animal get animal => Animal(
    dados['animal'] is Map
        ? Json.from(dados['animal'] as Map)
        : {'porte': porte, 'descricao': descricao},
    Especie({
      'id_especie': (dados['animal'] as Map?)?['id_especie'],
      'nome': especie,
    }),
  );
  Localizacao get local => Localizacao(Json.from(dados['localizacao'] as Map));
  Json get localizacao => local.dados;
  String get cidade => local.cidade.nome;
  double get latitude => local.latitude;
  double get longitude => local.longitude;
  DateTime get data =>
      DateTime.parse(dados['data_registro'] as String).toLocal();
  List<Foto> get fotografias =>
      (dados['fotos'] as List).map((f) => Foto(Json.from(f as Map))).toList();
  List<Json> get fotos => fotografias.map((f) => f.dados).toList();
  String? get foto =>
      fotos.isEmpty ? null : fotos.first['url_storage'] as String;
  StatusOcorrencia get situacao =>
      StatusOcorrencia.values.firstWhere((s) => s.rotulo == status);
  bool get encerrada => situacao.encerrado;
  Contato? get contato => dados['contato'] is Map
      ? Contato(Json.from(dados['contato'] as Map))
      : null;
  bool get podeContatar => !encerrada && contato != null;
}

typedef Ocorrencia = OcorrenciaAnimal;

class Correspondencia {
  final Json dados;
  Correspondencia(this.dados);
  int get id => dados['id_correspondencia'] as int;
  bool get pendente => dados['status_notificacao'] == 'Pendente';
  double get confianca => (dados['percentual_confianca'] as num).toDouble();
}

class PaginaOcorrencias {
  final List<Ocorrencia> items;
  final int total;
  PaginaOcorrencias(this.items, this.total);
}

class FotografiaEnvio {
  final String nome;
  final List<int> bytes;
  FotografiaEnvio(this.nome, this.bytes);
}
