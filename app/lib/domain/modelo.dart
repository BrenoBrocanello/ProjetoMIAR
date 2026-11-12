// Tipos do diagrama de classes (MASTER p.24) e projeções das relações do DER p.25.
// Sem dependência de Flutter, HTTP, banco ou interfaces de usuário.
enum TipoUsuario {
  cidadao('Cidadão'),
  protetor('Protetor independente'),
  ong('ONG');

  final String rotulo;
  const TipoUsuario(this.rotulo);
}

enum Porte {
  pequeno('Pequeno'),
  medio('Médio'),
  grande('Grande');

  final String rotulo;
  const Porte(this.rotulo);
}

enum StatusOcorrencia {
  perdido('Perdido'),
  encontrado('Encontrado'),
  emergencia('Emergência'),
  aguardandoAdocao('Aguardando Adoção'),
  adotado('Adotado'),
  resgatado('Resgatado');

  final String rotulo;
  const StatusOcorrencia(this.rotulo);
  bool get encerrado => this == adotado || this == resgatado;
}

class Especie {
  final Map<String, dynamic> dados;
  Especie(this.dados);
  int? get id => dados['id_especie'] as int?;
  String get nome => dados['nome'] as String;
}

class Cidade {
  final Map<String, dynamic> dados;
  Cidade(this.dados);
  int? get id => dados['id_cidade'] as int?;
  String get nome => dados['nome'] as String;
  String? get estado => dados['estado'] as String?;
}

class Animal {
  final Map<String, dynamic> dados;
  final Especie especie;
  Animal(this.dados, this.especie);
  int? get id => dados['id_animal'] as int?;
  String? get nome => dados['nome'] as String?;
  Porte get porte => Porte.values.firstWhere((p) => p.rotulo == dados['porte']);
  String get descricao => dados['descricao'] as String;
  String? get idade => dados['idade'] as String?;
  String? get genero => dados['genero'] as String?;
  String? get cor => dados['cor'] as String?;
  String? get urlFoto => dados['url_foto'] as String?;
  DateTime? get dataCadastro => dados['data_cadastro'] == null
      ? null
      : DateTime.parse(dados['data_cadastro'] as String);
}

class Localizacao {
  final Map<String, dynamic> dados;
  Localizacao(this.dados);
  int? get id => dados['id_localizacao'] as int?;
  double get latitude => (dados['latitude'] as num).toDouble();
  double get longitude => (dados['longitude'] as num).toDouble();
  String? get endereco => dados['endereco'] as String?;
  Cidade get cidade => Cidade({
    'id_cidade': dados['id_cidade'],
    'nome': dados['cidade'],
    'estado': dados['estado'],
  });
}

class Foto {
  final Map<String, dynamic> dados;
  Foto(this.dados);
  int get id => dados['id_foto'] as int;
  String get url => dados['url_storage'] as String;
  String? get descricao => dados['descricao'] as String?;
  DateTime? get dataUpload => dados['data_upload'] == null
      ? null
      : DateTime.parse(dados['data_upload'] as String);
}

class Contato {
  final Map<String, dynamic> dados;
  Contato(this.dados);
  int? get id => dados['id_contato'] as int?;
  String get telefone => dados['numero_whatsapp'] as String;
  Uri get whatsappLink => Uri.parse(
    dados['whatsapp_link'] as String? ?? 'https://wa.me/55$telefone',
  );
  DateTime? get dataContato => dados['data_contato'] == null
      ? null
      : DateTime.parse(dados['data_contato'] as String);
}

// Representação do modelo; CU10 não autoriza capturar/enviar conversas no MIAR.
class MensagemWhatsapp {
  final Map<String, dynamic> dados;
  MensagemWhatsapp(this.dados);
  int get id => dados['id_mensagem'] as int;
  int get contatoId => dados['id_contato'] as int;
  String? get texto => dados['texto'] as String?;
  String? get remetente => dados['remetente'] as String?;
  DateTime? get dataEnvio => dados['data_envio'] == null
      ? null
      : DateTime.parse(dados['data_envio'] as String);
}

class Busca {
  final String? especie, porte, cidade, status;
  const Busca({this.especie, this.porte, this.cidade, this.status});
  factory Busca.fromJson(Map<String, dynamic> data) => Busca(
    especie: data['especie'] as String?,
    porte: data['porte'] as String?,
    cidade: data['cidade'] as String?,
    status: data['status'] as String?,
  );
  Map<String, dynamic> toJson() => {
    for (final item in {
      'especie': especie,
      'porte': porte,
      'cidade': cidade,
      'status': status,
    }.entries)
      if (item.value?.trim().isNotEmpty == true) item.key: item.value!.trim(),
  };
}
