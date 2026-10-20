import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/db/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 本地数据库（Hive）：先初始化盒子与预设分类，再启动 UI
  await initDatabase();
  runApp(const ProviderScope(child: SpentTrackerApp()));
}
