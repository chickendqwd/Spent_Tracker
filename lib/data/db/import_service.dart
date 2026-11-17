import '../../core/io/import_parser.dart';
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

  /// 分类名在现有分类中找不到、将落为「未分类」的条数
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

/// 导入服务：负责去重、分类名映射与落库，解析交给 `import_parser`。
class ImportService {
  const ImportService();

  /// 去重键：类型 + 金额 + 币种 + 日期 + 备注 + 分类名。
  /// 不含 createdAt 与 id：同一天同金额同备注同分类的重复导入应被判重。
  String _keyOf(
    int type,
    int amount,
    String currency,
    String date,
    String? note,
    String? categoryName,
  ) {
    return [
      '$type',
      '$amount',
      currency,
      date,
      note ?? '',
      categoryName ?? '',
    ].join('\u0001');
  }

  String _key(ImportCandidate c) {
    final t = c.transaction;
    return _keyOf(t.type, t.amount, t.currency, t.date, t.note, c.categoryName);
  }

  Map<String, int> _categoryIndex() => {
        for (final c in Db.categories.values) '${c.type}|${c.name}': c.key as int,
      };

  /// 现有账目的去重键集合。分类名先建一次 id 表，避免每条账目都全量遍历分类。
  Set<String> _existingKeys() {
    final nameById = <int, String>{
      for (final c in Db.categories.values) c.key as int: c.name,
    };
    return {
      for (final t in Db.transactions.values)
        _keyOf(
          t.type,
          t.amount,
          t.currency,
          t.date,
          t.note,
          nameById[t.categoryId],
        ),
    };
  }

  /// 预演：不改动数据，只计算将写入的条目与统计。
  ImportDryRun preview(List<ImportCandidate> candidates) {
    final existing = _existingKeys();
    final categoryIndex = _categoryIndex();
    final toImport = <ImportCandidate>[];
    var duplicates = 0;
    var unmatched = 0;

    for (final c in candidates) {
      final key = _key(c);
      if (existing.contains(key)) {
        duplicates++;
        continue;
      }
      existing.add(key); // 同一文件内的重复也跳过
      final name = c.categoryName;
      if (name != null && categoryIndex['${c.transaction.type}|$name'] == null) {
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

  /// 落库：按分类名映射到 categoryId（找不到则未分类），逐条追加。
  Future<ImportOutcome> commit(ImportDryRun dryRun) async {
    final categoryIndex = _categoryIndex();
    var imported = 0;
    var unmatched = 0;

    for (final c in dryRun.toImport) {
      final src = c.transaction;
      final name = c.categoryName;
      int? categoryId;
      if (name != null) {
        categoryId = categoryIndex['${src.type}|$name'];
        if (categoryId == null) unmatched++;
      }
      await Db.transactions.add(
        Transaction(
          type: src.type,
          amount: src.amount,
          categoryId: categoryId,
          date: src.date,
          note: src.note,
          createdAt: src.createdAt,
          currency: src.currency,
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
