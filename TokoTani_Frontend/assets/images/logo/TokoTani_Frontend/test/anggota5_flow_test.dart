import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tokotani/services/api_service.dart';

void main() {
  setUp(() {
    ApiService.authTokenReader = () async => null;
  });

  tearDown(() {
    ApiService.httpClient.close();
    ApiService.httpClient = http.Client();
    ApiService.authTokenReader = null;
  });

  test(
    '404 keranjang tetap menjadi error API, bukan keranjang kosong palsu',
    () async {
      ApiService.httpClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'status': 'gagal',
            'code': 404,
            'message': 'Keranjang tidak ditemukan.',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      await expectLater(
        ApiService.getCart(),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 404)
              .having(
                (error) => error.message,
                'message',
                'Keranjang tidak ditemukan.',
              ),
        ),
      );
    },
  );

  test(
    'Konfirmasi pembayaran menggunakan endpoint Laravel dan menampilkan kegagalan',
    () async {
      late http.Request capturedRequest;
      ApiService.httpClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'status': 'gagal',
            'code': 403,
            'message': 'Bukan pemilik pesanan.',
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      await expectLater(
        ApiService.confirmPayment(42, 3),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.url.path, endsWith('/api/pesanan/42/pembayaran'));
    },
  );
}
