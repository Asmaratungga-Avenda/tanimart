import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokotani/pages/login_page.dart';

import 'test_support.dart';

void main() {
  setUp(configureUnavailableApi);

  testWidgets('login page offers real sign-in and registration forms', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const LoginPage()));
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Masuk ke akun TaniMart Anda'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.bySemanticsLabel('Logo TaniMart'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);

    await tester.tap(find.text('Belum memiliki akun? Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Buat Akun TaniMart'), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Ulangi Kata Sandi'), findsOneWidget);
  });

  testWidgets('login form stays scrollable on compact screens', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp(const LoginPage()));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Selamat Datang'), findsOneWidget);
  });
}
