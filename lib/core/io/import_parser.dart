import 'dart:convert';

import '../../data/models/transaction.dart';
import '../utils/date_util.dart';
import '../utils/money_util.dart';

/// 一条可导入的账目（分类尚未映射为 categoryId）。
class ImportCandidate {
  const ImportCandidate({
    required this.transaction,
    required this.categoryName,
    required this.rowNumber,
    this.categoryKey,
  });

  final Transaction transaction;

  /// 导出文件里的分类展示名（当前语言）；null 表示「未分类」
  final String? categoryName;

  /// 导出文件里的分类中性标识（预设分类的 presetKey，自建分类为空）。
  /// v3.4 新增；旧备份文件没有这一列。
  final String? categoryKey;

  /// 在源文件中的行号（CSV 含表头，从 1 开始计数），便于定位问题
  final int rowNumber;
}

/// 文件级错误：无法继续解析。
enum ImportErrorCode {
  unsupportedFile,
  jsonInvalid,
  jsonNotArray,
  csvEmpty,
  csvMissingColumns,
}

class ImportException implements Exception {
  const ImportException(this.code, {this.fileName, this.columns = const []});

  final ImportErrorCode code;

  /// unsupportedFile 时的文件名
  final String? fileName;

  /// csvMissingColumns 时缺少的列名
  final List<String> columns;

  @override
  String toString() => 'ImportException($code)';
}

/// 行级错误：该行被跳过，其余行照常导入。
enum ImportIssueCode { rowNotObject, invalidType, invalidAmount, invalidDate }

class ImportIssue {
  const ImportIssue({
    required this.rowNumber,
    required this.code,
    this.value = '',
  });

  final int rowNumber;
  final ImportIssueCode code;

  /// 出问题的原始文本（类型 / 金额 / 日期）
  final String value;
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
/// v3.4 起导出文件使用中性标识：`type` 为 `expense` / `income`，
/// 分类用 `categoryKey`（presetKey）加 `categoryName`（人可读名称）。
/// 旧文件（type 为「支出/收入/0/1」、分类只有 `category` 列）继续兼容。
ImportParseResult parseImportContent(String content, {required String fileName}) {
  // 去掉 UTF-8 BOM，否则 CSV 首列表头会变成 "\uFEFFtype"
  if (content.startsWith('\uFEFF')) content = content.substring(1);
  final ext = fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : '';
  if (ext == 'json') return _parseJson(content);
  if (ext == 'csv') return _parseCsvContent(content);
  throw ImportException(
    ImportErrorCode.unsupportedFile,
    fileName: fileName,
  );
}

ImportParseResult _parseJson(String content) {
  final Object? decoded;
  try {
    decoded = jsonDecode(content);
  } catch (e) {
    throw const ImportException(ImportErrorCode.jsonInvalid);
  }
  if (decoded is! List) {
    throw const ImportException(ImportErrorCode.jsonNotArray);
  }

  final candidates = <ImportCandidate>[];
  final issues = <ImportIssue>[];
  for (final (i, item) in decoded.indexed) {
    final rowNumber = i + 1;
    if (item is! Map) {
      issues.add(
        ImportIssue(rowNumber: rowNumber, code: ImportIssueCode.rowNotObject),
      );
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
    throw const ImportException(ImportErrorCode.csvEmpty);
  }

  final header =
      rows.first.map((h) => h.replaceFirst('\uFEFF', '').trim()).toList();
  final lowerHeader = header.map((h) => h.toLowerCase()).toList();
  final required = ['type', 'amount', 'date'];
  final missing = required.where((f) => !lowerHeader.contains(f)).toList();
  if (missing.isNotEmpty) {
    throw ImportException(
      ImportErrorCode.csvMissingColumns,
      columns: missing,
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

/// 中性类型标识与多语标签 → 0/1；无法识别返回 null。
int? _parseType(String raw) {
  final v = raw.trim().toLowerCase();
  switch (v) {
    case 'expense':
    case '0':
    case '支出':
    case '出費':
      return 0;
    case 'income':
    case '1':
    case '收入':
    case '収入':
      return 1;
  }
  return null;
}

/// 「未分类」在各语言里的写法（旧文件用它表示无分类）。
bool _isUncategorized(String name) =>
    name == '未分类' || name == 'Uncategorized' || name == '未分類';

ImportCandidate? _buildCandidate(
  Map<String, Object?> row,
  int rowNumber,
  List<ImportIssue> issues,
) {
  void fail(ImportIssueCode code, [String value = '']) {
    issues.add(ImportIssue(rowNumber: rowNumber, code: code, value: value));
  }

  // 类型
  final rawType = (row['type'] ?? '').toString();
  final type = _parseType(rawType);
  if (type == null) {
    fail(ImportIssueCode.invalidType, rawType.trim());
    return null;
  }

  // 金额（元 → 分）
  final rawAmount = (row['amount'] ?? '').toString().trim();
  final cents = MoneyUtil.parseToCents(rawAmount);
  if (cents == null || cents <= 0) {
    fail(ImportIssueCode.invalidAmount, rawAmount);
    return null;
  }

  // 日期
  final rawDate = (row['date'] ?? '').toString().trim();
  final dateOk = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawDate) &&
      DateTime.tryParse(rawDate) != null;
  if (!dateOk) {
    fail(ImportIssueCode.invalidDate, rawDate);
    return null;
  }

  // 币种：缺省走基准 SGD
  final rawCurrency = (row['currency'] ?? '').toString().trim();
  final currency = rawCurrency.isEmpty ? 'SGD' : rawCurrency.toUpperCase();

  // 分类：新文件用 categoryKey（中性）+ categoryName（展示名）；
  // 旧文件只有 category 名称列
  final rawKey = (row['categoryKey'] ?? '').toString().trim();
  final rawName = (row['categoryName'] ?? row['category'] ?? '').toString().trim();
  final categoryKey = rawKey.isEmpty ? null : rawKey;
  final categoryName =
      (rawName.isEmpty || _isUncategorized(rawName)) ? null : rawName;

  final rawNote = (row['note'] ?? '').toString().trim();
  final note = rawNote.isEmpty ? null : rawNote;

  final rawCreatedAt = (row['createdAt'] ?? '').toString().trim();
  final createdAt = DateTime.tryParse(rawCreatedAt) ??
      DateUtil.fromDayKey(rawDate);

  // 汇率快照（v3.4.1）：备份文件带 rateToSgd 时沿用，缺失则留给落库阶段按当前汇率补
  final rawRate = (row['rateToSgd'] ?? '').toString().trim();
  final rateToSgd = double.tryParse(rawRate);

  return ImportCandidate(
    rowNumber: rowNumber,
    categoryName: categoryName,
    categoryKey: categoryKey,
    transaction: Transaction(
      type: type,
      amount: cents,
      categoryId: null, // 导入时按标识/名称映射
      date: rawDate,
      note: note,
      createdAt: createdAt,
      currency: currency,
      rateToSgd: (rateToSgd != null && rateToSgd > 0) ? rateToSgd : null,
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
