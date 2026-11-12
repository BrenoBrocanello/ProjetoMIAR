import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:miar/data/api_repository.dart';
import 'package:miar/domain/entidades.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Galeria e câmera nativas retornam fotos válidas e persistem pela API',
    (tester) async {
      if (!apiUrl.endsWith(':3301')) throw StateError('Use a API isolada.');
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Auditoria de fotografia nativa')),
        ),
      );
      final repo = ApiRepository();
      final tag = DateTime.now().millisecondsSinceEpoch;
      await repo.cadastrar({
        'nome': 'Fotografia nativa',
        'email': 'fotografia-$tag@example.test',
        'senha': 'Fotografia!42',
        'telefone': '11987654321',
        'tipo_usuario': 'ONG',
      });
      await repo.entrar('fotografia-$tag@example.test', 'Fotografia!42');
      final restaurado = await ApiRepository().restaurarSessao();
      expect(restaurado?.email, 'fotografia-$tag@example.test');
      final ids = <int>[];
      try {
        for (final source in [ImageSource.gallery, ImageSource.camera]) {
          debugPrint(
            source == ImageSource.camera
                ? 'MIAR_AUDIT_CAMERA'
                : 'MIAR_AUDIT_GALERIA',
          );
          final photo = await tester.runAsync(
            () => ImagePicker().pickImage(
              source: source,
              maxWidth: 1600,
              maxHeight: 1600,
              imageQuality: 90,
            ),
          );
          expect(
            photo,
            isNotNull,
            reason: 'O seletor precisa retornar uma fotografia real.',
          );
          final bytes = await photo!.readAsBytes();
          final codec = await tester.runAsync(
            () => ui.instantiateImageCodec(bytes),
          );
          final frame = await codec!.getNextFrame();
          expect(frame.image.width, greaterThanOrEqualTo(32));
          expect(frame.image.height, greaterThanOrEqualTo(32));
          frame.image.dispose();
          codec.dispose();
          final saved = await repo.salvarOcorrencia(
            {
              'especie': 'Cão',
              'porte': 'Grande',
              'descricao_fisica': 'Foto de ensaio nativo',
              'estado_saude': 'Ensaio',
              'status_ocorrencia': 'Encontrado',
              'localizacao': {
                'latitude': -23.1857,
                'longitude': -46.8978,
                'cidade': 'Jundiaí',
              },
              'numero_whatsapp': '11987654321',
            },
            [FotografiaEnvio('nativa.jpg', bytes)],
          );
          ids.add(saved.id);
          expect(saved.fotos, isNotEmpty);
          debugPrint('MIAR_AUDIT_ETAPA=FOTOGRAFIA_${source.name}_APROVADA');
        }
      } finally {
        for (final id in ids) {
          await repo.excluir(id);
        }
        await repo.sair();
        await tester.pumpWidget(const SizedBox());
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
