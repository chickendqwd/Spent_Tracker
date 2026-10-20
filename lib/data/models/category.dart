import 'package:hive/hive.dart';

import 'transaction_type.dart';

part 'category.g.dart';

/// 分类字典表：支出/收入各有一套分类。
@HiveType(typeId: 0)
class Category extends HiveObject {
  Category({
    required this.name,
    required this.type,
    this.icon,
    this.isPreset = false,
  });

  @HiveField(0)
  String name;

  /// 所属类型：0=支出，1=收入（对应 TransactionType.index）
  @HiveField(1)
  int type;

  /// 图标（emoji），可选
  @HiveField(2)
  String? icon;

  /// 是否预设：预设分类禁止删除
  @HiveField(3)
  bool isPreset;

  TransactionType get transactionType => TransactionType.fromIndex(type);

  /// 展示图标（无图标时用占位）
  String get displayIcon => (icon == null || icon!.isEmpty) ? '📦' : icon!;
}
