/// 预设分类的稳定标识与三语名称。
///
/// 存储只信 [PresetCategorySpec.key]：分类展示名按当前语言从这张表取，
/// 换语言不会影响账目归属；用户自建分类没有 presetKey，名称保持原文。
class PresetCategorySpec {
  const PresetCategorySpec({
    required this.key,
    required this.type,
    required this.icon,
    required this.zh,
    required this.en,
    required this.ja,
  });

  /// 稳定标识（写入 `Category.presetKey` 与导出文件的 `categoryKey` 列）
  final String key;

  /// 0=支出，1=收入（对应 TransactionType.index）
  final int type;

  final String icon;
  final String zh;
  final String en;
  final String ja;

  String nameFor(String localeCode) => switch (localeCode) {
        'en' => en,
        'ja' => ja,
        _ => zh,
      };

  /// 名称别名：中文 / 英文 / 日文，导入时用来跨语言匹配
  Iterable<String> get allNames => [zh, en, ja];
}

class PresetCategories {
  PresetCategories._();

  static const List<PresetCategorySpec> data = [
    // 支出
    PresetCategorySpec(
      key: 'food',
      type: 0,
      icon: '🍜',
      zh: '餐饮',
      en: 'Food',
      ja: '食費',
    ),
    PresetCategorySpec(
      key: 'transport',
      type: 0,
      icon: '🚌',
      zh: '交通',
      en: 'Transport',
      ja: '交通費',
    ),
    PresetCategorySpec(
      key: 'shopping',
      type: 0,
      icon: '🛍️',
      zh: '购物',
      en: 'Shopping',
      ja: '買い物',
    ),
    PresetCategorySpec(
      key: 'housing',
      type: 0,
      icon: '🏠',
      zh: '居住',
      en: 'Housing',
      ja: '住居',
    ),
    PresetCategorySpec(
      key: 'entertainment',
      type: 0,
      icon: '🎮',
      zh: '娱乐',
      en: 'Entertainment',
      ja: '娯楽',
    ),
    PresetCategorySpec(
      key: 'health',
      type: 0,
      icon: '💊',
      zh: '医疗',
      en: 'Health',
      ja: '医療',
    ),
    PresetCategorySpec(
      key: 'education',
      type: 0,
      icon: '📚',
      zh: '教育',
      en: 'Education',
      ja: '教育',
    ),
    PresetCategorySpec(
      key: 'other_expense',
      type: 0,
      icon: '📦',
      zh: '其他',
      en: 'Other',
      ja: 'その他',
    ),
    // 收入
    PresetCategorySpec(
      key: 'salary',
      type: 1,
      icon: '💼',
      zh: '工资',
      en: 'Salary',
      ja: '給料',
    ),
    PresetCategorySpec(
      key: 'bonus',
      type: 1,
      icon: '🧧',
      zh: '奖金',
      en: 'Bonus',
      ja: 'ボーナス',
    ),
    PresetCategorySpec(
      key: 'part_time',
      type: 1,
      icon: '💻',
      zh: '兼职',
      en: 'Part-time',
      ja: 'アルバイト',
    ),
    PresetCategorySpec(
      key: 'investment',
      type: 1,
      icon: '📈',
      zh: '理财',
      en: 'Investment',
      ja: '投資',
    ),
    PresetCategorySpec(
      key: 'other_income',
      type: 1,
      icon: '📦',
      zh: '其他',
      en: 'Other',
      ja: 'その他',
    ),
  ];

  static PresetCategorySpec? specForKey(String key) {
    for (final s in data) {
      if (s.key == key) return s;
    }
    return null;
  }

  /// 预设分类在当前语言下的展示名
  static String? nameFor(String key, String localeCode) =>
      specForKey(key)?.nameFor(localeCode);

  /// 名称（任意语言）→ presetKey。同名的「其他」按 type 区分。
  static String? keyForName(String name, {int? type}) {
    final n = name.trim();
    if (n.isEmpty) return null;
    for (final s in data) {
      if (type != null && s.type != type) continue;
      if (s.allNames.any((alias) => alias == n)) return s.key;
    }
    return null;
  }

  /// 旧版本分类表只有中文名，迁移时按「类型 + 中文名」补 presetKey。
  static String? keyForLegacyCategory(int type, String name) {
    for (final s in data) {
      if (s.type == type && s.zh == name) return s.key;
    }
    return null;
  }
}
