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
    this.presetKey,
  });

  /// 存储名。预设分类也保留一份（旧版本写入的中文名），展示时优先按
  /// [presetKey] 取当前语言的名字；自建分类直接用这个名称。
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

  /// 预设分类的稳定标识（如 'food'），自建分类为空。
  /// v3.4 新增；旧记录缺失时保持不变，由迁移按类型+名称补齐。
  @HiveField(4)
  String? presetKey;

  TransactionType get transactionType => TransactionType.fromIndex(type);

  /// 展示图标（无图标时用占位）
  String get displayIcon => (icon == null || icon!.isEmpty) ? '📦' : icon!;
}
