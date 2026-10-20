import 'package:intl/intl.dart';

import '../constants.dart';

/// 金额工具：内部一律以整数「分」存储与计算，展示时转为带符号文本。
class MoneyUtil {
  MoneyUtil._();

  /// 分 → 展示文本，如 123450 → "¥1,234.50"
  static String format(int cents, {String? symbol}) {
    final s = symbol ?? AppConstants.currencySymbol;
    return '$s${NumberFormat('#,##0.00').format(cents / 100)}';
  }

  /// 用户输入（元，可含最多两位小数）→ 分。
  /// 非法输入（空、负、多余小数点等）返回 null。
  static int? parseToCents(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    if (!RegExp(r'^\d{1,7}(\.\d{1,2})?$').hasMatch(text)) return null;
    final parts = text.split('.');
    final yuan = int.parse(parts[0]);
    final centsPart = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
    return yuan * 100 + int.parse(centsPart);
  }

  /// 元文本（两位小数，无千分位），用于编辑回填输入框。
  static String inputText(int cents) => (cents / 100).toStringAsFixed(2);
}
