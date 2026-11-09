import 'package:flutter/material.dart';
import 'product_catalog_page.dart';

class CatalogPage extends StatelessWidget {
  final bool showBackButton;

  const CatalogPage({super.key, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    return ProductCatalogPage(showBackButton: showBackButton);
  }
}