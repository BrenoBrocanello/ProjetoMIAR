import 'dart:io';
import 'dart:convert';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final dir = Directory(
        Platform.environment['MIAR_EVIDENCIAS'] ?? '../evidencias/android',
      );
      await dir.create(recursive: true);
      await File('${dir.path}/$name.png').writeAsBytes(bytes);
      if (args != null) {
        await File('${dir.path}/$name.json').writeAsString(jsonEncode(args));
      }
      return true;
    },
  );
}
