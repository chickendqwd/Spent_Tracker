import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:spent_tracker/data/db/currency_repository.dart';
import 'package:spent_tracker/data/db/database.dart';
import 'package:spent_tracker/data/models/budget.dart';
import 'package:spent_tracker/data/models/currency.dart';
import 'package:spent_tracker/state/budget_providers.dart';
import 'package:spent_tracker/state/currency_providers.dart';

/// v3.3 基准币种：交叉换算、符号回退、切换基准后汇率不被改写。
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('spent_tracker_currency_test');
    await initDatabaseAt(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// SGD 锚点 1.0，CNY 0.186，JPY 0.0086
  List<Currency> sample({String base = 'SGD'}) => [
        Currency(
          code: 'SGD',
          name: '新加坡元',
          symbol: 'S\$',
          rateToSgd: 1.0,
          isBase: base == 'SGD',
        ),
        Currency(
          code: 'CNY',
          name: '人民币',
          symbol: '¥',
          rateToSgd: 0.186,
          isBase: base == 'CNY',
        ),
        Currency(
          code: 'JPY',
          name: '日元',
          symbol: '円',
          rateToSgd: 0.0086,
          isBase: base == 'JPY',
        ),
      ];

  group('toBaseCents：以 SGD 为中间货币交叉换算', () {
    test('基准 SGD 时与 v2 口径一致', () {
      final currencies = sample();
      expect(toBaseCents(currencies, 10000, 'CNY'), 1860);
      expect(toBaseCents(currencies, 5000, 'SGD'), 5000);
      // 缺失币种按 1 处理
      expect(toBaseCents(currencies, 5000, 'XYZ'), 5000);
    });

    test('基准换成 CNY 后，CNY 原样、SGD 按 1/0.186 放大', () {
      final currencies = sample(base: 'CNY');
      expect(toBaseCents(currencies, 10000, 'CNY'), 10000);
      // 100 SGD = 100/0.186 ≈ 537.63 CNY
      expect(toBaseCents(currencies, 10000, 'SGD'), 53763);
    });

    test('两种非 SGD 币种之间也走交叉换算', () {
      final currencies = sample(base: 'CNY');
      // 1000 JPY × 0.0086 / 0.186 ≈ 46.24 CNY
      expect(toBaseCents(currencies, 1000, 'JPY'), 46);
    });

    test('基准为 JPY 时 SGD 被正确放大', () {
      final currencies = sample(base: 'JPY');
      // 1 SGD = 1/0.0086 ≈ 116.28 JPY
      expect(toBaseCents(currencies, 100, 'SGD'), 11628);
    });
  });

  group('rateToBaseOf / symbolOf', () {
    test('相对基准汇率随基准变化', () {
      final sgdBase = sample();
      expect(rateToBaseOf(sgdBase, 'CNY'), closeTo(0.186, 1e-9));
      final cnyBase = sample(base: 'CNY');
      expect(rateToBaseOf(cnyBase, 'SGD'), closeTo(1 / 0.186, 1e-9));
      expect(rateToBaseOf(cnyBase, 'CNY'), closeTo(1.0, 1e-9));
    });

    test('币种缺失时回退到当前基准币种符号，而非写死 S\$', () {
      expect(symbolOf(sample(), 'XYZ'), 'S\$');
      expect(symbolOf(sample(base: 'CNY'), 'XYZ'), '¥');
    });
  });

  group('预算金额：按录入币种存储，展示时换算到基准（v3.4.1）', () {
    test('预算保持录入币种，展示换算到当前基准', () {
      // 500 CNY 预算：存 50000 分 + currency='CNY'
      final sgdBase = sample();
      expect(budgetCentsInBase(sgdBase, 50000, 'CNY'), 9300);
      // 基准切到 CNY 后原样展示
      final cnyBase = sample(base: 'CNY');
      expect(budgetCentsInBase(cnyBase, 50000, 'CNY'), 50000);
      // 预算币种等于基准时不做换算
      expect(budgetCentsInBase(sgdBase, 9300, 'SGD'), 9300);
    });

    test('旧预算没有币种字段时按 SGD 处理', () {
      final b = Budget(type: 0, month: '2026-10', amount: 9300);
      expect(b.currencyCode, 'SGD');
      expect(budgetCentsInBase(sample(base: 'CNY'), b.amount, b.currencyCode),
          50000);
    });
  });

  group('仓库：切换基准', () {
    test('setBase 只改标记，汇率与其它币种不受影响', () async {
      const repo = CurrencyRepository();
      // 种子里已含 SGD / CNY / MYR / JPY
      expect(repo.base.code, 'SGD');

      await repo.setBase('CNY');
      expect(repo.base.code, 'CNY');
      expect(Db.currencies.get('SGD')!.isBase, isFalse);
      expect(Db.currencies.get('CNY')!.isBase, isTrue);
      // 汇率保持原样，没有被改成 1
      expect(Db.currencies.get('CNY')!.rateToSgd, closeTo(0.186, 1e-9));
      expect(Db.currencies.get('SGD')!.rateToSgd, 1.0);

      // 新基准可以直接改汇率（旧实现会把基准汇率强制成 1）
      await repo.updateRate('CNY', 0.19);
      expect(Db.currencies.get('CNY')!.rateToSgd, closeTo(0.19, 1e-9));

      // SGD 是锚点，修改被忽略
      await repo.updateRate('SGD', 2.0);
      expect(Db.currencies.get('SGD')!.rateToSgd, 1.0);

      // 切回 SGD
      await repo.setBase('SGD');
      expect(repo.base.code, 'SGD');
      expect(Db.currencies.get('CNY')!.isBase, isFalse);
      // 切换不会改动之前手改过的汇率
      expect(Db.currencies.get('CNY')!.rateToSgd, closeTo(0.19, 1e-9));
    });

    test('未知币种不会改变基准', () async {
      const repo = CurrencyRepository();
      await repo.setBase('XYZ');
      expect(repo.base.code, 'SGD');
    });

    test('升级后自动补上 JPY 预设（符号为「円」）', () async {
      // 模拟老用户：只有 SGD / CNY / MYR 三个币种
      await Db.currencies.delete('JPY');
      await initDatabaseAt(tempDir.path);
      expect(Db.currencies.containsKey('JPY'), isTrue);
      expect(Db.currencies.get('JPY')!.symbol, '円');
    });

    test('老版本写入的 JPY 符号 ¥ 会被迁移成「円」', () async {
      // 模拟 3.3 装过的用户：JPY 已存在但符号还是 ¥
      final jpy = Db.currencies.get('JPY')!;
      jpy.symbol = '¥';
      await Db.currencies.put('JPY', jpy);
      await initDatabaseAt(tempDir.path);
      expect(Db.currencies.get('JPY')!.symbol, '円');
    });

    test('切换基准后，provider 层读到的基准与符号同步变化', () async {
      await const CurrencyRepository().setBase('CNY');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(baseCurrencyProvider).code, 'CNY');
      expect(
        symbolOf(container.read(currencyProvider), 'CNY'),
        '¥',
      );
      // 汇总换算用的也是新基准
      expect(
        toBaseCents(container.read(currencyProvider), 10000, 'SGD'),
        53763,
      );
    });

    test('已运行的容器里，切换基准后 baseCurrencyProvider 会自己刷新', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final seen = <String>[];
      container.listen<Currency>(
        baseCurrencyProvider,
        (_, next) => seen.add(next.code),
        fireImmediately: true,
      );

      await const CurrencyRepository().setBase('JPY');
      // 盒变更事件是异步流，等事件派发一次
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(seen, contains('JPY'));
      expect(container.read(baseCurrencyProvider).code, 'JPY');
      expect(container.read(baseCurrencyProvider).symbol, '円');
    });
  });
}
