import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:spent_tracker/app.dart';
import 'package:spent_tracker/core/utils/date_util.dart';
import 'package:spent_tracker/data/db/budget_repository.dart';
import 'package:spent_tracker/data/db/currency_repository.dart';
import 'package:spent_tracker/data/db/database.dart';
import 'package:spent_tracker/data/db/recurring_rule_repository.dart';
import 'package:spent_tracker/data/db/transaction_repository.dart';
import 'package:spent_tracker/data/models/budget.dart';
import 'package:spent_tracker/data/models/recurring_rule.dart';
import 'package:spent_tracker/data/models/transaction.dart';
import 'package:spent_tracker/state/budget_providers.dart';
import 'package:spent_tracker/state/currency_providers.dart';
import 'package:spent_tracker/state/language_providers.dart';
import 'package:spent_tracker/state/recurring_rule_providers.dart';
import 'package:spent_tracker/state/transaction_providers.dart';

/// 测试用 pumpAndSettle：5 秒上限，卡在无限动画时能快速定位到具体步骤。
Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );

/// 固定界面语言（widget 测试用）：不读 Hive。
class _FixedLanguage extends LanguageNotifier {
  _FixedLanguage(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

/// v3.4.1：历史汇率快照、今日待记消隐、预算币种。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('spent_tracker_v341_test');
    await initDatabaseAt(tempDir.path);
    // 预算页的 widget 测试用：默认预算币种设为人民币（真实 I/O 只能在 setUp 完成）
    await Db.settings.put('budgetCurrencyCode', 'CNY');
    // 预置一笔本月 CNY 总预算 1000（widget 层验证展示与近似值；Hive 写入须在真实 async 中）
    final now = DateTime.now();
    final month =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    await const BudgetRepository().add(
      Budget(type: 0, month: month, amount: 100000, currency: 'CNY'),
    );
  });

  tearDown(() async {
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      await Hive.close();
    });
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ProviderContainer newContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('历史账目汇率快照', () {
    test('有快照的交易在汇率变化后金额不变', () async {
      final container = newContainer();
      final today = DateUtil.toDayKey(DateTime.now());
      // 默认 CNY 汇率 0.186；记账时锁定该汇率
      await const TransactionRepository().add(
        Transaction(
          type: 0,
          amount: 10000,
          date: today,
          currency: 'CNY',
          rateToSgd: 0.186,
          createdAt: DateTime.now(),
        ),
      );
      container.invalidate(transactionProvider);
      expect(container.read(thisMonthExpenseProvider), 1860);

      // 汇率翻倍后，这笔历史账目不应变化
      await const CurrencyRepository().updateRate('CNY', 0.372);
      container.invalidate(currencyProvider);
      container.invalidate(transactionProvider);
      expect(container.read(thisMonthExpenseProvider), 1860);
    });

    test('没有快照交易仍随汇率变化（迁移前的旧行为，作对照）', () async {
      final container = newContainer();
      await const TransactionRepository().add(
        Transaction(
          type: 0,
          amount: 10000,
          date: DateUtil.toDayKey(DateTime.now()),
          currency: 'CNY',
          createdAt: DateTime.now(),
        ),
      );
      container.invalidate(transactionProvider);
      expect(container.read(thisMonthExpenseProvider), 1860);
      await const CurrencyRepository().updateRate('CNY', 0.372);
      container.invalidate(currencyProvider);
      container.invalidate(transactionProvider);
      expect(container.read(thisMonthExpenseProvider), 3720);
    });

    test('启动迁移用当前汇率一次性锁定旧账', () async {
      await Db.transactions.add(
        Transaction(
          type: 0,
          amount: 10000,
          date: '2026-01-01',
          currency: 'CNY',
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      expect(Db.transactions.values.first.rateToSgd, isNull);

      await Hive.close();
      await initDatabaseAt(tempDir.path);

      final migrated = Db.transactions.values.first;
      expect(migrated.rateToSgd, closeTo(0.186, 1e-9));
      // 再开一次，快照不会被覆盖（幂等）
      final snapshot = migrated.rateToSgd;
      await Hive.close();
      await initDatabaseAt(tempDir.path);
      expect(Db.transactions.values.first.rateToSgd, snapshot);
    });
  });

  group('今日待记随记账消隐', () {
    RecurringRule weeklyRule({int amount = 1200}) {
      final now = DateTime.now();
      return RecurringRule(
        type: 0,
        amount: amount,
        currency: 'SGD',
        frequency: RecurringFrequency.weekly.index,
        dayValue: now.weekday,
        startDate: DateUtil.toDayKey(
          DateTime(now.year, now.month, now.day - 7),
        ),
      );
    }

    test('今天记了对应账目后提示消失', () async {
      final container = newContainer();
      final rule = weeklyRule();
      await const RecurringRuleRepository().add(rule);
      container.invalidate(recurringRuleProvider);
      expect(container.read(todayDueRulesProvider), hasLength(1));

      await const TransactionRepository().add(
        Transaction(
          type: 0,
          amount: 1200,
          date: DateUtil.toDayKey(DateTime.now()),
          currency: 'SGD',
          rateToSgd: 1.0,
          createdAt: DateTime.now(),
        ),
      );
      container.invalidate(transactionProvider);
      expect(container.read(todayDueRulesProvider), isEmpty);
    });

    test('金额对不上时仍然提示（判定不是"今天记过就算"）', () async {
      final container = newContainer();
      await const RecurringRuleRepository().add(weeklyRule());
      container.invalidate(recurringRuleProvider);
      await const TransactionRepository().add(
        Transaction(
          type: 0,
          amount: 999,
          date: DateUtil.toDayKey(DateTime.now()),
          currency: 'SGD',
          rateToSgd: 1.0,
          createdAt: DateTime.now(),
        ),
      );
      container.invalidate(transactionProvider);
      expect(container.read(todayDueRulesProvider), hasLength(1));
    });
  });

  testWidgets('预算页渲染：默认币种行与「跟随基准」语义', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          languageProvider.overrideWith(() => _FixedLanguage(const Locale('zh'))),
        ],
        child: const SpentTrackerApp(),
      ),
    );
    await settle(tester);

    await tester.tap(find.text('设置'));
    await settle(tester);
    await tester.tap(find.text('预算设置'));
    await settle(tester);

    // setUp 里把默认预算币种设为 CNY → 行标题存在，副标题显示人民币
    expect(find.text('默认预算币种'), findsOneWidget);
    expect(find.text('人民币'), findsOneWidget);
    // 预置的 CNY 预算：主值按预算币种显示，附「≈ 基准值」
    expect(find.text('¥ 1,000.00'), findsOneWidget);
    expect(find.text('≈ S\$ 186.00'), findsOneWidget);
    expect(find.text('新增预算'), findsOneWidget);

    // 新增对话框：币种可选，默认跟随全局设置（人民币）
    await tester.tap(find.text('新增预算'));
    await settle(tester);
    expect(find.text('预算币种'), findsOneWidget);
    expect(find.text('¥ 人民币'), findsWidgets);
  });
}
