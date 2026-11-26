// 注意：flutter/foundation 自带一个注解类 Category，与模型 Category 重名，
// 这里显式隐藏，避免类型解析冲突。
import 'package:flutter/foundation.dart' hide Category;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/budget.dart';
import '../models/category.dart';
import '../models/currency.dart';
import '../models/recurring_rule.dart';
import '../models/transaction.dart';

/// Hive 盒子访问入口。initDatabase 完成前不可使用。
class Db {
  Db._();

  static late Box<Category> categories;
  static late Box<Transaction> transactions;

  /// 预算盒（auto-increment int key）
  static late Box<Budget> budgets;

  /// 周期记账规则盒（auto-increment int key）
  static late Box<RecurringRule> recurringRules;

  /// 币种与汇率盒（key 为币种 code，如 'SGD' / 'CNY' / 'MYR'）
  static late Box<Currency> currencies;

  /// 轻量偏好设置盒（外观模式等非业务配置）
  static late Box<dynamic> settings;
}

/// 默认汇率（锚点为 SGD；SGD 自身 rate=1）。这些是手动默认值，可在「设置→货币与汇率」修改或联网更新。
/// 基准币种可由用户在货币页切换，切换只改 isBase 标记，不动这里的汇率。
class PresetCurrencies {
  static const List<({String code, String name, String symbol, double rate})>
      data = [
    (code: 'SGD', name: '新加坡元', symbol: 'S\$', rate: 1.0),
    (code: 'CNY', name: '人民币', symbol: '¥', rate: 0.186),
    (code: 'MYR', name: '马来西亚林吉特', symbol: 'RM', rate: 0.30),
    // JPY 的默认值只是量级占位（约 1 日元 ≈ 0.0086 新元），以联网或手填为准
    (code: 'JPY', name: '日元', symbol: '¥', rate: 0.0086),
  ];
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
    Hive.registerAdapter(BudgetAdapter());
    Hive.registerAdapter(RecurringRuleAdapter());
    Hive.registerAdapter(CurrencyAdapter());
  }
  Db.categories = await Hive.openBox<Category>('categories');
  Db.transactions = await Hive.openBox<Transaction>('transactions');
  Db.budgets = await Hive.openBox<Budget>('budgets');
  Db.recurringRules = await Hive.openBox<RecurringRule>('recurring_rules');
  Db.currencies = await Hive.openBox<Currency>('currencies');
  Db.settings = await Hive.openBox('settings');
  await _seedPresetCategoriesIfNeeded();
  await _seedPresetCurrenciesIfNeeded();
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

/// 首启写入默认币种与汇率（用 code 作 key，幂等）。
Future<void> _seedPresetCurrenciesIfNeeded() async {
  for (final item in PresetCurrencies.data) {
    if (Db.currencies.containsKey(item.code)) continue;
    await Db.currencies.put(
      item.code,
      Currency(
        code: item.code,
        name: item.name,
        symbol: item.symbol,
        rateToSgd: item.rate,
        isBase: item.code == 'SGD',
      ),
    );
  }
}
