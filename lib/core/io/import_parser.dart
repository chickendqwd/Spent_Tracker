import 'dart:convert';

import '../../data/models/transaction.dart';
import '../utils/date_util.dart';
import '../utils/money_util.dart';

/// 一条可导入的账目（分类尚未映射为 categoryId，先保留名称）。
class ImportCandidate {
  const ImportCandidate({
    required this.transaction,
    required this.categoryName,
    required this.rowNumber,
  });

  final Transaction transaction;

  /// 导出文件里的分类名；null 表示「未分类」
  final String? categoryName;

  /// 在源文件中的行号（CSV 含表头，从 1 开始计数），便于定位问题
  final int rowNumber;
}

class ImportIssue {
  const ImportIssue({required this.rowNumber, required this.reason});

  final int rowNumber;
  final String reason;
}

class ImportParseResult {
  const ImportParseResult({
    required this.candidates,
    required this.issues,
    required this.totalRows,
  });

  final List<ImportCandidate> candidates;
  final List<ImportIssue> issues;

  /// 参与解析的有效数据行数（不含表头）
  final int totalRows;
}

/// 解析 CSV / JSON 备份文件。只做格式与字段校验，不做去重与落库。
///
/// 支持本应用导出的两种格式（字段：type, amount, currency, category, date,
/// note, createdAt），`type` 兼容「支出/收入」与 0/1，`amount` 为「元」文本。
ImportParseResult parseImportContent(String content, {required String fileName}) {
  // 去掉 UTF-8 BOM，否则 CSV 首列表头会变成 "\uFEFFtype"
  if (content.startsWith('\uFEFF')) content = content.substring(1);
  final ext = fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : '';
  if (ext == 'json') return _parseJson(content);
  if (ext == 'csv') return _parseCsvContent(content);
  throw FormatException('不支持的文件类型：$fileName（仅支持 .csv / .json）');
}

ImportParseResult _parseJson(String content) {
  final Object? decoded;
  try {
    decoded = jsonDecode(content);
  } catch (e) {
    throw const FormatException('JSON 格式无法解析，请确认文件完整');
  }
  if (decoded is! List) {
    throw const FormatException('JSON 备份应为账目数组（[...]）');
  }

  final candidates = <ImportCandidate>[];
  final issues = <ImportIssue>[];
  for (final (i, item) in decoded.indexed) {
    final rowNumber = i + 1;
    if (item is! Map) {
      issues.add(ImportIssue(rowNumber: rowNumber, reason: '不是对象'));
      continue;
    }
    final map = item.map((k, v) => MapEntry(k.toString(), v));
    final row = _buildCandidate(map, rowNumber, issues);
    if (row != null) candidates.add(row);
  }
  return ImportParseResult(
    candidates: candidates,
    issues: issues,
    totalRows: decoded.length,
  );
}

ImportParseResult _parseCsvContent(String content) {
  final rows = _splitCsv(content);
  if (rows.isEmpty) {
    throw const FormatException('CSV 文件为空');
  }

  final header = rows.first.map((h) => h.trim().toLowerCase()).toList();
  final required = ['type', 'amount', 'date'];
  final missing = required.where((f) => !header.contains(f)).toList();
  if (missing.isNotEmpty) {
    throw FormatException(
      'CSV 缺少必需列：${missing.join('、')}（表头需包含 type, amount, date）',
    );
  }

  final candidates = <ImportCandidate>[];
  final issues = <ImportIssue>[];
  final dataRows = rows.sublist(1);
  for (final (i, cells) in dataRows.indexed) {
    final rowNumber = i + 2; // 表头占第 1 行
    if (cells.every((c) => c.trim().isEmpty)) continue; // 跳过空行
    final map = <String, Object?>{
      for (final (j, name) in header.indexed)
        name: j < cells.length ? cells[j] : '',
    };
    final row = _buildCandidate(map, rowNumber, issues);
    if (row != null) candidates.add(row);
  }

  return ImportParseResult(
    candidates: candidates,
    issues: issues,
    totalRows: dataRows.where((r) => r.any((c) => c.trim().isNotEmpty)).length,
  );
}

ImportCandidate? _buildCandidate(
  Map<String, Object?> row,
  int rowNumber,
  List<ImportIssue> issues,
) {
  ImportIssue fail(String reason) {
    final issue = ImportIssue(rowNumber: rowNumber, reason: reason);
    issues.add(issue);
    return issue;
  }

  // 类型
  final rawType = (row['type'] ?? '').toString().trim();
  final int type;
  if (rawType == '支出' || rawType == '0' || rawType == 'expense') {
    type = 0;
  } else if (rawType == '收入' || rawType == '1' || rawType == 'income') {
    type = 1;
  } else {
    fail('无法识别类型「$rawType」');
    return null;
  }

  // 金额（元 → 分）
  final rawAmount = (row['amount'] ?? '').toString().trim();
  final cents = MoneyUtil.parseToCents(rawAmount);
  if (cents == null || cents <= 0) {
    fail('金额无效「$rawAmount」');
    return null;
  }

  // 日期
  final rawDate = (row['date'] ?? '').toString().trim();
  final dateOk = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawDate) &&
      DateTime.tryParse(rawDate) != null;
  if (!dateOk) {
    fail('日期无效「$rawDate」（应为 yyyy-MM-dd）');
    return null;
  }

  // 币种：缺省走基准 SGD
  final rawCurrency = (row['currency'] ?? '').toString().trim();
  final currency = rawCurrency.isEmpty ? 'SGD' : rawCurrency.toUpperCase();

  // 分类名：空或「未分类」均落为未分类
  final rawCategory = (row['category'] ?? '').toString().trim();
  final categoryName =
      (rawCategory.isEmpty || rawCategory == '未分类') ? null : rawCategory;

  final rawNote = (row['note'] ?? '').toString().trim();
  final note = rawNote.isEmpty ? null : rawNote;

  final rawCreatedAt = (row['createdAt'] ?? '').toString().trim();
  final createdAt = DateTime.tryParse(rawCreatedAt) ??
      DateUtil.fromDayKey(rawDate);

  return ImportCandidate(
    rowNumber: rowNumber,
    categoryName: categoryName,
    transaction: Transaction(
      type: type,
      amount: cents,
      categoryId: null, // 导入时按分类名映射
      date: rawDate,
      note: note,
      createdAt: createdAt,
      currency: currency,
    ),
  );
}

/// 标准 CSV 分列：支持双引号包裹、字段内逗号与换行、`""` 转义。
List<List<String>> _splitCsv(String text) {
  final rows = <List<String>>[];
  final buffer = StringBuffer();
  final current = <String>[];
  var inQuotes = false;

  void endField() {
    current.add(buffer.toString());
    buffer.clear();
  }

  void endRow() {
    endField();
    rows.add(List<String>.from(current));
    current.clear();
  }

  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        buffer.write(c);
      }
      continue;
    }
    switch (c) {
      case '"':
        inQuotes = true;
      case ',':
        endField();
      case '\r':
        break;
      case '\n':
        endRow();
      default:
        buffer.write(c);
    }
  }
  if (buffer.isNotEmpty || current.isNotEmpty) endRow();
  // 末尾若因换行产生了空行，去掉
  while (rows.isNotEmpty && rows.last.every((c) => c.trim().isEmpty)) {
    rows.removeLast();
  }
  return rows;
}
