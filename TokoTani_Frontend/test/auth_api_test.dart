import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tokotani/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    ApiService.httpClient.close();
    ApiService.httpClient = http.Client();
    ApiService.authTokenReader = null;
  });

  test('sends the stored Sanctum token as a Bearer token', () async {
    ApiService.authTokenReader = () async => 'test-token';
    String? authorization;
    ApiService.httpClient = MockClient((request) async {
      authorization = request.headers.entries
          .firstWhere((entry) => entry.key.toLowerCase() == 'authorization')
          .value;
      return http.Response(
        jsonEncode({
          'status': 'sukses',
          'data': {
            'user': {'id': 1, 'email': 'pelanggan@example.test'},
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final user = await ApiService.currentUser();

    expect(user['email'], 'pelanggan@example.test');
    expect(authorization, 'Bearer test-token');
  });
}
