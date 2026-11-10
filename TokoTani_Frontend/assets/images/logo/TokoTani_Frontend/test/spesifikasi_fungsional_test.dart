import 'package:flutter_test/flutter_test.dart';
import 'package:tokotani/models/courier.dart';
import 'package:tokotani/models/order.dart';
import 'package:tokotani/models/payment_method.dart';
import 'package:tokotani/models/product.dart';
import 'package:tokotani/pages/cart_page.dart';
import 'package:tokotani/pages/checkout_page.dart';
import 'package:tokotani/pages/order_detail_page.dart';
import 'package:tokotani/pages/order_history_page.dart';
import 'package:tokotani/pages/product_catalog_page.dart';
import 'package:tokotani/pages/product_detail_page.dart';
import 'package:tokotani/services/api_service.dart';

import 'test_support.dart';

void main() {
  setUp(configureUnavailableApi);

  testWidgets(
    'Katalog menunjukkan kegagalan API tanpa mengganti dengan data contoh',
    (tester) async {
      await tester.pumpWidget(testApp(const ProductCatalogPage()));
      await tester.pumpAndSettle();

      expect(
        find.text('Server API tidak tersedia untuk pengujian.'),
        findsOneWidget,
      );
      expect(find.text('Semua Produk'), findsOneWidget);
    },
  );

  testWidgets(
    'Rincian produk menampilkan data yang diberikan dan tombol keranjang',
    (tester) async {
      const product = Product(
        id: 10,
        nama: 'Produk Uji Sayuran',
        kategori: 'Sayuran',
        harga: 12000,
        stok: 4,
        satuanJual: 'ikat',
        tersedia: true,
        mudahRusak: true,
      );

      await tester.pumpWidget(
        testApp(
          const ProductDetailPage(productId: 10, initialProduct: product),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Produk Uji Sayuran'), findsWidgets);
      expect(find.text('Tambah ke Keranjang'), findsOneWidget);
    },
  );

  testWidgets('Keranjang menampilkan error server, bukan daftar contoh', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const CartPage()));
    await tester.pumpAndSettle();

    expect(find.text('Keranjang'), findsOneWidget);
    expect(
      find.text('Server API tidak tersedia untuk pengujian.'),
      findsOneWidget,
    );
  });

  testWidgets('Checkout tetap tersedia tetapi tidak mengarang opsi server', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const CheckoutPage()));
    await tester.pumpAndSettle();

    expect(find.text('Checkout'), findsOneWidget);
    expect(
      find.text('Server API tidak tersedia untuk pengujian.'),
      findsOneWidget,
    );
    expect(find.text('Buat Pesanan'), findsNothing);
  });

  testWidgets(
    'Detail pesanan menawarkan konfirmasi melalui endpoint pembayaran',
    (tester) async {
      const order = OrderModel(
        id: 101,
        namaPenerima: 'Penerima Uji',
        alamatPenerima: 'Alamat Uji',
        kurirId: 1,
        paymentMethodId: 1,
        subtotal: 12000,
        ongkir: 5000,
        totalHarga: 17000,
        status: 'menunggu_pembayaran',
        tanggalAntar: '2025-01-01',
        courier: Courier(id: 1, nama: 'Kurir Uji', tarif: 5000, aktif: true),
        paymentMethod: PaymentMethod(
          id: 1,
          nama: 'Metode Uji',
          deskripsi: 'Metode pengujian',
          aktif: true,
        ),
      );

      await tester.pumpWidget(
        testApp(const OrderDetailPage(orderId: 101, initialOrder: order)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pesanan #101'), findsWidgets);
      expect(find.text('Konfirmasi Pembayaran'), findsOneWidget);
    },
  );

  testWidgets('Riwayat pesanan menampilkan kegagalan API', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const OrderHistoryPage()));
    await tester.pumpAndSettle();
    expect(find.text('Pesanan Saya'), findsOneWidget);
    expect(
      find.text('Server API tidak tersedia untuk pengujian.'),
      findsOneWidget,
    );
  });

  test('API error classifications remain available to the screens', () {
    expect(ApiErrorType.values, contains(ApiErrorType.connection));
    expect(ApiErrorType.values, contains(ApiErrorType.timeout));
    expect(ApiErrorType.values, contains(ApiErrorType.validation));
    expect(ApiErrorType.values, contains(ApiErrorType.conflict));
    expect(ApiErrorType.values, contains(ApiErrorType.server));
  });
}
