import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokotani/core/theme/app_theme.dart';
import 'package:tokotani/pages/location_picker_page.dart';

void main() {
  testWidgets('location picker does not invent an initial customer location', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LocationPickerPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pilih Lokasi Pengiriman'), findsOneWidget);
    expect(find.text('Lokasi saya'), findsOneWidget);
    expect(find.text('Gunakan Lokasi Ini'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
