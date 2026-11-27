import 'dart:convert';

import 'package:fast_gbk/fast_gbk.dart';

/// 导入文件的文本解码（v3.4 · B7）。
///
/// 顺序：UTF-8 BOM → UTF-16 BOM → 严格 UTF-8 → GBK → 容错 UTF-8。
/// Windows 版 Excel 默认导出 GBK 编码 CSV，先按严格 UTF-8 试一次能避免把
/// 合法的 UTF-8 中文误判成 GBK（两种编码的中文字节不重叠，但顺序必须固定）。
class ImportTextDecoder {
  ImportTextDecoder._();

  static String decode(List<int> bytes) {
    if (bytes.isEmpty) return '';

    // UTF-8 BOM
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3), allowMalformed: true);
    }
    // UTF-16 LE / BE（Excel 的「Unicode 文本」）
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return _decodeUtf16(bytes.sublist(2), littleEndian: true);
    }
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return _decodeUtf16(bytes.sublist(2), littleEndian: false);
    }

    // 严格 UTF-8：能解就直接用
    try {
      return utf8.decode(bytes);
    } on FormatException {
      // 继续尝试 GBK
    }

    try {
      return gbk.decode(bytes);
    } catch (_) {
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  static String _decodeUtf16(List<int> bytes, {required bool littleEndian}) {
    final buffer = StringBuffer();
    var i = 0;
    while (i + 1 < bytes.length) {
      final unit = littleEndian
          ? bytes[i] | (bytes[i + 1] << 8)
          : (bytes[i] << 8) | bytes[i + 1];
      // 代理对：D800–DBFF 后跟 DC00–DFFF
      if (unit >= 0xD800 &&
          unit <= 0xDBFF &&
          i + 3 < bytes.length) {
        final low = littleEndian
            ? bytes[i + 2] | (bytes[i + 3] << 8)
            : (bytes[i + 2] << 8) | bytes[i + 3];
        if (low >= 0xDC00 && low <= 0xDFFF) {
          final codePoint =
              0x10000 + ((unit - 0xD800) << 10) + (low - 0xDC00);
          buffer.writeCharCode(codePoint);
          i += 4;
          continue;
        }
      }
      buffer.writeCharCode(unit);
      i += 2;
    }
    return buffer.toString();
  }
}
