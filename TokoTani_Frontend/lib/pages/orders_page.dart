import 'package:flutter/material.dart';
import 'order_history_page.dart';

/// Compatibility entry point for the shared order-history screen.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OrderHistoryPage(showBackButton: true);
  }
}
