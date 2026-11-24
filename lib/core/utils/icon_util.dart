import 'package:characters/characters.dart';

/// 默认占位图标（无有效图标时使用）。
const String kFallbackCategoryIcon = '📦';

/// 规范化用户自定义的分类图标（v3.2）。
///
/// 规则：
/// - 只接受 1–2 个“字符”（按 Unicode 字素簇计数，因此单个 emoji 算 1 个，
///   组合 emoji 或“字母+emoji”最多 2 个）；
/// - 空串、纯空白、含换行、超长 → 返回 null，由调用方回退 [kFallbackCategoryIcon]。
String? normalizeCategoryIcon(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return null;
  if (text.contains('\n') || text.contains('\r')) return null;
  final length = text.characters.length;
  if (length < 1 || length > 2) return null;
  return text;
}
