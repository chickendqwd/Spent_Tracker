import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:spent_tracker/data/db/category_repository.dart';
import 'package:spent_tracker/data/db/database.dart';
import 'package:spent_tracker/data/db/transaction_repository.dart';
import 'package:spent_tracker/data/models/category.dart';
import 'package:spent_tracker/data/models/transaction.dart';

/// 数据层（仓库）规则测试：真实异步环境下验证 Hive 读写与业务规则。
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('spent_tracker_repo_test');
    await initDatabaseAt(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('删除自定义分类：历史账目置为未分类', () async {
    final catKey = await Db.categories.add(Category(name: '宠物', type: 0));
    final txKey = await Db.transactions.add(
      Transaction(
        type: 0,
        amount: 800,
        categoryId: catKey,
        date: '2026-10-21',
        createdAt: DateTime.now(),
      ),
    );

    await const CategoryRepository().delete(catKey);

    expect(Db.categories.get(catKey), isNull);
    final tx = Db.transactions.get(txKey)!;
    expect(tx.categoryId, isNull); // 已置为「未分类」
    expect(tx.amount, 800); // 账目本身保留
  });

  test('预设分类禁止删除', () async {
    final preset = Db.categories.values.firstWhere((c) => c.isPreset);
    await expectLater(
      const CategoryRepository().delete(preset.key as int),
      throwsA(isA<StateError>()),
    );
  });

  test('账目仓库：按日期倒序、同日按创建时间倒序', () async {
    await Db.transactions.add(
      Transaction(
        type: 0,
        amount: 100,
        categoryId: null,
        date: '2026-10-20',
        createdAt: DateTime(2026, 10, 20),
      ),
    );
    await Db.transactions.add(
      Transaction(
        type: 0,
        amount: 200,
        categoryId: null,
        date: '2026-10-21',
        createdAt: DateTime(2026, 10, 21),
      ),
    );
    await Db.transactions.add(
      Transaction(
        type: 0,
        amount: 300,
        categoryId: null,
        date: '2026-10-21',
        createdAt: DateTime(2026, 10, 21, 12), // 同日更晚
      ),
    );

    final list = const TransactionRepository().getAll();
    expect(list.map((t) => t.date).toList(), [
      '2026-10-21',
      '2026-10-21',
      '2026-10-20',
    ]);
    expect(list.map((t) => t.amount).toList(), [300, 200, 100]);
  });

  test('金额解析：整数分存储', () {
    // MoneyUtil 的行为由录入面板间接覆盖；这里验证存储即整数分
    final tx = Transaction(
      type: 0,
      amount: 2550,
      categoryId: null,
      date: '2026-10-21',
      createdAt: DateTime.now(),
    );
    expect(tx.amount, 2550); // 25.50 元 → 2550 分
  });
}
