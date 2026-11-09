import 'package:flutter_test/flutter_test.dart';
import 'package:tokotani/pages/checkout_page.dart';

import 'test_support.dart';

void main() {
  setUp(configureUnavailableApi);

  testWidgets('Checkout tidak menampilkan tombol buat pesanan saat API gagal', (tester) async {
    await tester.pumpWidget(testApp(const CheckoutPage()));
    await tester.pumpAndSettle();

    expect(find.text('Checkout Pesanan'), findsOneWidget);
    expect(find.text('Server API tidak tersedia untuk pengujian.'), findsOneWidget);
    expect(find.text('Buat Pesanan'), findsNothing);
  });
}
