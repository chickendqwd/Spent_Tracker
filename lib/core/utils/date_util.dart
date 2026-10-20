/// 日期工具：账目的 date 字段固定为 yyyy-MM-dd 字符串。
class DateUtil {
  DateUtil._();

  static const List<String> _weekdays = [
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  /// DateTime → yyyy-MM-dd
  static String toDayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// yyyy-MM-dd → DateTime
  static DateTime fromDayKey(String key) => DateTime.parse(key);

  /// yyyy-MM（用于月度总结聚合）
  static String monthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  /// 列表分组标题：如 "10月21日 周三"
  static String listHeader(DateTime d) =>
      '${d.month}月${d.day}日 ${_weekdays[d.weekday - 1]}';

  /// 月份标题：如 "2026年10月"
  static String monthTitle(DateTime d) => '${d.year}年${d.month}月';
}
