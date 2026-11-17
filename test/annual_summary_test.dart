import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:spent_tracker/data/db/database.dart';
import 'package:spent_tracker/data/models/transaction.dart';
import 'package:spent_tracker/state/annual_providers.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('spent_annual_test');
    await initDatabaseAt(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('年报：按年聚合，跨年记录被排除，统计项正确', () async {
    final year = DateTime.now().year;
    await Db.transactions.add(
      Transaction(
        type: 0,
        amount: 10000,
        categoryId: null,
        date: '$year-01-05',
        createdAt: DateTime.now(),
      ),
    );
    await Db.transactions.add(
      Transaction(
        type: 0,
        amount: 20000,
        categoryId: null,
        date: '$year-03-10',
        createdAt: DateTime.now(),
      ),
    );
    await Db.transactions.add(
      Transaction(
        type: 1,
        amount: 50000,
        categoryId: null,
        date: '$year-06-01',
        createdAt: DateTime.now(),
      ),
    );
    // 上一年最后一天：必须被排除
    await Db.transactions.add(
      Transaction(
        type: 0,
        amount: 9900,
        categoryId: null,
        date: '${year - 1}-12-31',
        createdAt: DateTime.now(),
      ),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final summary = container.read(annualSummaryProvider);

    expect(summary.year, year);
    expect(summary.totalExpense, 30000);
    expect(summary.totalIncome, 50000);
    expect(summary.balance, 20000);
    expect(summary.recordCount, 3, reason: '跨年记录不计入');

    // 12 个月固定长度，空月为 0
    expect(summary.months.length, 12);
    expect(summary.months[0].expense, 10000);
    expect(summary.months[2].expense, 20000);
    expect(summary.months[5].income, 50000);
    expect(summary.months[11].expense, 0);

    expect(summary.peakExpenseMonth, 3, reason: '支出最高的是 3 月');
    expect(summary.monthsWithExpense, 2, reason: '仅 1 月与 3 月有支出');
    expect(summary.averageMonthlyExpense, 15000, reason: '月均按有支出的月份计算');

    // 未分类记录归入「未分类」一项
    expect(summary.expenseByCategory.length, 1);
    expect(summary.expenseByCategory.single.category, isNull);
    expect(summary.expenseByCategory.single.amountCents, 30000);
  });

  test('年报：切到上一年后统计范围随之改变', () async {
    final year = DateTime.now().year;
    await Db.transactions.add(
      Transaction(
        type: 0,
        amount: 12345,
        categoryId: null,
        date: '${year - 1}-07-01',
        createdAt: DateTime.now(),
      ),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(annualSummaryProvider).recordCount, 0);

    container.read(annualYearProvider.notifier).previous();
    final lastYear = container.read(annualSummaryProvider);
    expect(lastYear.year, year - 1);
    expect(lastYear.totalExpense, 12345);
    expect(lastYear.recordCount, 1);
  });
}
