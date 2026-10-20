// 注意：flutter/foundation 自带一个注解类 Category，与模型 Category 重名，
// 这里显式隐藏，避免类型解析冲突。
import 'package:flutter/foundation.dart' hide Category;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/category.dart';
import '../models/transaction.dart';

/// Hive 盒子访问入口。initDatabase 完成前不可使用。
class Db {
  Db._();

  static late Box<Category> categories;
  static late Box<Transaction> transactions;
}

/// 预设分类（首启写入，isPreset=true 禁止删除）。
class PresetCategories {
  static const List<({String name, int type, String icon})> data = [
    // 支出
    (name: '餐饮', type: 0, icon: '🍜'),
    (name: '交通', type: 0, icon: '🚌'),
    (name: '购物', type: 0, icon: '🛍️'),
    (name: '居住', type: 0, icon: '🏠'),
    (name: '娱乐', type: 0, icon: '🎮'),
    (name: '医疗', type: 0, icon: '💊'),
    (name: '教育', type: 0, icon: '📚'),
    (name: '其他', type: 0, icon: '📦'),
    // 收入
    (name: '工资', type: 1, icon: '💼'),
    (name: '奖金', type: 1, icon: '🧧'),
    (name: '兼职', type: 1, icon: '💻'),
    (name: '理财', type: 1, icon: '📈'),
    (name: '其他', type: 1, icon: '📦'),
  ];
}

/// 初始化本地数据库（在 runApp 前调用一次）。
Future<void> initDatabase() async {
  if (kIsWeb) {
    // Web：无需路径，Hive 自动使用浏览器存储
    Hive.initFlutter();
  } else {
    // IO 平台：使用应用文档目录
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
  }
  await _openBoxesAndSeed();
}

/// 供测试等场景注入存储目录（避免依赖 path_provider 插件）。
@visibleForTesting
Future<void> initDatabaseAt(String path) async {
  Hive.init(path);
  await _openBoxesAndSeed();
}

bool _adaptersRegistered = false;

Future<void> _openBoxesAndSeed() async {
  if (!_adaptersRegistered) {
    // Hive 的类型注册表是全局单例，重复注册会抛错；用标志位保证只注册一次
    _adaptersRegistered = true;
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(TransactionAdapter());
  }
  Db.categories = await Hive.openBox<Category>('categories');
  Db.transactions = await Hive.openBox<Transaction>('transactions');
  await _seedPresetCategoriesIfNeeded();
}

Future<void> _seedPresetCategoriesIfNeeded() async {
  if (Db.categories.isNotEmpty) return;
  for (final item in PresetCategories.data) {
    await Db.categories.add(
      Category(
        name: item.name,
        type: item.type,
        icon: item.icon,
        isPreset: true,
      ),
    );
  }
}
