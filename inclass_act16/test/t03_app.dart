import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inclass_act16/main.dart' as app;

Future<void> main() async {
  if (!kDebugMode) throw StateError('Run T03 in debug mode.');
  final replies = [
    '{',
    jsonEncode({'response_code': 1, 'results': []}),
    jsonEncode({'response_code': 0, 'results': List.filled(9, {})}),
  ];
  var next = 0;
  await http.runWithClient(
      app.main,
      () => MockClient((request) async {
            final reply = replies[next];
            next = (next + 1) % replies.length;
            return http.Response(reply, 200);
          }));
}
