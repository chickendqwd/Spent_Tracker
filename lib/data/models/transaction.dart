import 'package:hive/hive.dart';

import 'transaction_type.dart';

part 'transaction.g.dart';

/// 账目主表：一笔支出/收入。
@HiveType(typeId: 1)
class Transaction extends HiveObject {
  Transaction({
    required this.type,
    required this.amount,
    this.categoryId,
    required this.date,
    this.note,
    required this.createdAt,
    String currency = 'SGD',
    // ignore: prefer_initializing_formals
  }) : _currency = currency;

  /// 0=支出，1=收入（对应 TransactionType.index）
  @HiveField(0)
  int type;

  /// 金额（整数分），避免浮点误差
  @HiveField(1)
  int amount;

  /// 分类外键 → Category.key；null 表示「未分类」（分类被删除后置为此值）
  @HiveField(2)
  int? categoryId;

  /// 记账日期 yyyy-MM-dd
  @HiveField(3)
  String date;

  /// 备注（可选）
  @HiveField(4)
  String? note;

  /// 创建时间戳
  @HiveField(5)
  DateTime createdAt;

  /// 币种代码（v2 新增）。内部可空存储：v1 旧记录无此字段，读取时回退 SGD，
  /// 避免 hive adapter 对缺失字段赋空导致崩溃。
  @HiveField(6)
  String? _currency;

  /// 币种代码，默认 SGD（基准币种）。
  String get currency => _currency ?? 'SGD';

  set currency(String value) => _currency = value;

  TransactionType get transactionType => TransactionType.fromIndex(type);
}
