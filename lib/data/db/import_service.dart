import '../../core/io/import_parser.dart';
import '../../data/preset_categories.dart';
import '../models/transaction.dart';
import 'database.dart';

/// 预演结果：实际会写入的条目 + 统计。
class ImportDryRun {
  const ImportDryRun({
    required this.toImport,
    required this.duplicates,
    required this.unmatchedCategories,
  });

  final List<ImportCandidate> toImport;

  /// 与现有账目（或文件内互相）重复而跳过的条数
  final int duplicates;

  /// 分类在现有分类中找不到、将落为「未分类」的条数
  final int unmatchedCategories;
}

class ImportOutcome {
  const ImportOutcome({
    required this.imported,
    required this.duplicates,
    required this.unmatchedCategories,
  });

  final int imported;
  final int duplicates;
  final int unmatchedCategories;
}

/// 分类索引（构建一次，供 preview / commit 共用）。
class _CategoryIndex {
  /// presetKey → 现有分类 id
  final Map<String, int> byPresetKey = {};

  /// 'type|名称' → 现有分类 id（名称包括旧版本的中文名）
  final Map<String, int> byName = {};

  /// 分类 id → 中性标识（presetKey 优先，自建分类用名称）
  final Map<int, String> tokenById = {};
}

/// 一条候选的分类解析结果：落库用的 id 与去重用的中性标识。
typedef _ResolvedCategory = ({int? id, String token});

/// 导入服务：负责去重、分类标识映射与落库，解析交给 `import_parser`。
class ImportService {
  const ImportService();

  static const String _sep = '\u0001';

  _CategoryIndex _index() {
    final index = _CategoryIndex();
    for (final c in Db.categories.values) {
      final id = c.key as int;
      index.byName['${c.type}|${c.name}'] = id;
      index.tokenById[id] = c.presetKey ?? c.name;
      final presetKey = c.presetKey;
      if (presetKey != null) index.byPresetKey[presetKey] = id;
    }
    return index;
  }

  /// 去重键：类型 + 金额 + 币种 + 日期 + 备注 + 分类中性标识。
  /// 不含 createdAt 与 id：同一天同金额同备注同分类的重复导入应被判重。
  /// 分类用 presetKey 而不是展示名，换语言后去重仍成立。
  String _keyOf(
    int type,
    int amount,
    String currency,
    String date,
    String? note,
    String categoryToken,
  ) {
    return [
      '$type',
      '$amount',
      currency,
      date,
      note ?? '',
      categoryToken,
    ].join(_sep);
  }

  /// 解析候选的分类：先按中性 key，再按名称（含预设分类的三种语言别名）。
  _ResolvedCategory _resolve(ImportCandidate c, _CategoryIndex index) {
    final type = c.transaction.type;
    final key = c.categoryKey;
    if (key != null && key.isNotEmpty) {
      final id = index.byPresetKey[key];
      if (id != null) return (id: id, token: index.tokenById[id] ?? key);
    }

    final name = c.categoryName;
    if (name == null || name.isEmpty) {
      return (id: null, token: key ?? '');
    }

    // 1) 直接命中现有分类名称（自建分类、以及预设分类的存储名）
    final byName = index.byName['$type|$name'];
    if (byName != null) {
      return (id: byName, token: index.tokenById[byName] ?? name);
    }

    // 2) 名称是预设分类的另一种语言 → 换成 presetKey 再找
    final preset = PresetCategories.keyForName(name, type: type);
    if (preset != null) {
      final id = index.byPresetKey[preset];
      if (id != null) return (id: id, token: index.tokenById[id] ?? preset);
      return (id: null, token: preset);
    }

    // 3) 用户自建分类名：保持名称作为标识
    return (id: null, token: name);
  }

  /// 现有账目的去重键集合。
  Set<String> _existingKeys(_CategoryIndex index) {
    return {
      for (final t in Db.transactions.values)
        _keyOf(
          t.type,
          t.amount,
          t.currency,
          t.date,
          t.note,
          t.categoryId == null ? '' : (index.tokenById[t.categoryId] ?? ''),
        ),
    };
  }

  /// 预演：不改动数据，只计算将写入的条目与统计。
  ImportDryRun preview(List<ImportCandidate> candidates) {
    final index = _index();
    final existing = _existingKeys(index);
    final toImport = <ImportCandidate>[];
    var duplicates = 0;
    var unmatched = 0;

    for (final c in candidates) {
      final resolved = _resolve(c, index);
      final key = _keyOf(
        c.transaction.type,
        c.transaction.amount,
        c.transaction.currency,
        c.transaction.date,
        c.transaction.note,
        resolved.token,
      );
      if (existing.contains(key)) {
        duplicates++;
        continue;
      }
      existing.add(key); // 同一文件内的重复也跳过
      if ((c.categoryKey != null || c.categoryName != null) &&
          resolved.id == null) {
        unmatched++;
      }
      toImport.add(c);
    }

    return ImportDryRun(
      toImport: toImport,
      duplicates: duplicates,
      unmatchedCategories: unmatched,
    );
  }

  /// 某个币种当前对 SGD 的汇率；缺失按 1 处理。
  double _rateOf(String code) {
    final c = Db.currencies.get(code);
    return c?.rateToSgd ?? 1.0;
  }

  /// 落库：按标识/名称映射到 categoryId（找不到则未分类），逐条追加。
  Future<ImportOutcome> commit(ImportDryRun dryRun) async {
    final index = _index();
    var imported = 0;
    var unmatched = 0;

    for (final c in dryRun.toImport) {
      final src = c.transaction;
      final resolved = _resolve(c, index);
      if (resolved.id == null && (c.categoryKey != null || c.categoryName != null)) {
        unmatched++;
      }
      await Db.transactions.add(
        Transaction(
          type: src.type,
          amount: src.amount,
          categoryId: resolved.id,
          date: src.date,
          note: src.note,
          createdAt: src.createdAt,
          currency: src.currency,
          // v3.4.1：备份带汇率快照就沿用；没有则按导入时的汇率锁定
          rateToSgd: src.rateToSgd ?? _rateOf(src.currency),
        ),
      );
      imported++;
    }

    return ImportOutcome(
      imported: imported,
      duplicates: dryRun.duplicates,
      unmatchedCategories: unmatched,
    );
  }
}
