import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/navigation_provider.dart';
import 'ui.dart';

/// Menambah produk ke keranjang lewat API dan menampilkan hasil sebenarnya dari server.
/// Mengembalikan true bila server menerima.
Future<bool> addProductToCart(
  BuildContext context,
  Product product, {
  int quantity = 1,
  bool announce = true,
}) async {
  final cart = context.read<CartProvider>();
  final nav = context.read<NavigationProvider>();
  final navigator = Navigator.of(context);
  final error = await cart.addItem(product.id, quantity);
  if (!context.mounted) return error == null;
  if (error != null) {
    showAppSnack(context, error, error: true);
    return false;
  }
  if (announce) {
    showAppSnack(
      context,
      '${product.nama} masuk ke keranjang',
      actionLabel: 'Lihat',
      onAction: () {
        navigator.popUntil((route) => route.isFirst);
        nav.select(AppTab.cart);
      },
    );
  }
  return true;
}
