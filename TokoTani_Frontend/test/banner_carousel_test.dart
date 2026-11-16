import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tokotani/core/theme/app_theme.dart';
import 'package:tokotani/services/api_service.dart';
import 'package:tokotani/widgets/banner_carousel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    ApiService.httpClient.close();
    ApiService.httpClient = http.Client();
    ApiService.authTokenReader = null;
  });

  testWidgets('loads backend banners and advances them automatically', (
    tester,
  ) async {
    var requestedBanners = false;
    ApiService.authTokenReader = () async => null;
    ApiService.httpClient = MockClient((request) async {
      requestedBanners = request.url.path.endsWith('/banners');
      return http.Response(
        jsonEncode({
          'status': 'sukses',
          'data': [
            {
              'judul': 'Banner pertama',
              'gambar': 'banners/first.png',
              'url': 'http://127.0.0.1:8000/storage/banners/first.png',
            },
            {
              'judul': 'Banner kedua',
              'gambar': 'banners/second.png',
              'url': 'http://127.0.0.1:8000/storage/banners/second.png',
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: BannerCarousel(onTap: () {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(requestedBanners, isTrue);
    expect(find.bySemanticsLabel('Banner 1 dari 2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.bySemanticsLabel('Banner 2 dari 2'), findsOneWidget);
  });
}
