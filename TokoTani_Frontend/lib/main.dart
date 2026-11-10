import 'package:flutter/material.dart';

import 'app.dart';
import 'providers/theme_provider.dart';

export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final mode = await ThemeProvider.loadSaved();
  runApp(TaniMartApp(initialThemeMode: mode));
}
