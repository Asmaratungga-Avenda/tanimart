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

    expect(find.text('Masuk ke TokoTani'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Kata sandi'), findsOneWidget);

    await tester.tap(find.text('Belum punya akun? Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Buat Akun TokoTani'), findsOneWidget);
    expect(find.text('Nama'), findsOneWidget);
    expect(find.text('Ulangi kata sandi'), findsOneWidget);
  });
}
