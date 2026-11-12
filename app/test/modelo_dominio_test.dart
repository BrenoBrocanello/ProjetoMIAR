import 'package:flutter_test/flutter_test.dart';
import 'package:miar/domain/entidades.dart';

void main() {
  test(
    'DER: ocorrência projeta Animal/Especie, Localizacao/Cidade e fotografias sem perder relações',
    () {
      final o = Ocorrencia({
        'id_ocorrencia': 10,
        'id_usuario_responsavel': 2,
        'especie': 'Cão',
        'porte': 'Grande',
        'status_ocorrencia': 'Encontrado',
        'descricao_fisica': 'Caramelo',
        'estado_saude': 'Saudável',
        'data_registro': '2026-11-11',
        'animal': {
          'id_animal': 8,
          'id_especie': 3,
          'porte': 'Grande',
          'descricao': 'Caramelo',
          'nome': null,
        },
        'localizacao': {
          'id_localizacao': 9,
          'id_cidade': 5,
          'cidade': 'Jundiaí',
          'estado': 'SP',
          'latitude': -23.18,
          'longitude': -46.89,
        },
        'fotos': [
          {
            'id_foto': 7,
            'url_storage': '/fotos/exemplo.jpg',
            'data_upload': '2026-11-11',
          },
        ],
        'contato': {
          'numero_whatsapp': '11987654321',
          'whatsapp_link': 'https://wa.me/5511987654321',
        },
      });
      expect(o.animal.id, 8);
      expect(o.animal.especie.id, 3);
      expect(o.animal.especie.nome, 'Cão');
      expect(o.animal.porte, Porte.grande);
      expect(o.local.cidade.id, 5);
      expect(o.cidade, 'Jundiaí');
      expect(o.fotografias.single.id, 7);
      expect(o.fotos.single['url_storage'], o.foto);
      expect(o.contato!.whatsappLink.toString(), 'https://wa.me/5511987654321');
      for (final state in [
        'Perdido',
        'Encontrado',
        'Emergência',
        'Aguardando Adoção',
        'Adotado',
        'Resgatado',
      ]) {
        final changed = Ocorrencia({...o.dados, 'status_ocorrencia': state});
        expect(changed.podeContatar, !['Adotado', 'Resgatado'].contains(state));
      }
    },
  );
  test(
    'CU04: busca omite campos vazios e mantém exclusivamente os quatro critérios previstos',
    () {
      expect(const Busca().toJson(), isEmpty);
      expect(
        Busca.fromJson({
          'especie': ' Cão ',
          'porte': 'Grande',
          'cidade': ' Jundiaí ',
          'status': 'Perdido',
          'extra': 'não deve seguir',
        }).toJson(),
        {
          'especie': 'Cão',
          'porte': 'Grande',
          'cidade': 'Jundiaí',
          'status': 'Perdido',
        },
      );
    },
  );
}
