import 'package:flutter/material.dart';

import 'app.dart';
import 'core/cache/hive_service.dart';
import 'core/queue/offline_queue_service.dart';
import 'providers/theme_provider.dart';

export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveCacheService.instance.init();
  await OfflineQueueService.instance.init();
  final mode = await ThemeProvider.loadSaved();
  runApp(TaniMartApp(initialThemeMode: mode));
}
