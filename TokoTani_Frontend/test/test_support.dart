import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokotani/main.dart';
import 'package:tokotani/services/api_service.dart';

void configureUnavailableApi() {
  SharedPreferences.setMockInitialValues({});
  ApiService.httpClient = MockClient((_) async {
    return http.Response(
      jsonEncode({
        'status': 'gagal',
        'code': 503,
        'message': 'Server API tidak tersedia untuk pengujian.',
      }),
      503,
      headers: {'content-type': 'application/json'},
    );
  });
}

Widget testApp(Widget home) => TaniMartApp(home: home);
