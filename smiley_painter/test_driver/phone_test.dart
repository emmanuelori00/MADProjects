import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  await integrationDriver(
    timeout: const Duration(minutes: 3),
    responseDataCallback: (data) async {
      final pictures = data!['pictures'] as Map<String, dynamic>;
      for (final name in pictures.keys) {
        await File('docs/evidence/$name.png')
            .writeAsBytes(base64Decode(pictures[name] as String));
      }
    },
  );
}
