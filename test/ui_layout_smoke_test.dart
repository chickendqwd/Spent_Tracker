import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:spent_tracker/app.dart';
import 'package:spent_tracker/core/utils/date_util.dart';
import 'package:spent_tracker/data/db/database.dart';
import 'package:spent_tracker/data/models/transaction.dart';
import 'package:spent_tracker/state/language_providers.dart';

/// 窄屏（iPhone SE / 360dp）布局冒烟：任何 RenderFlex 溢出都会作为异常抛出。
/// 覆盖总览、明细、设置、录入面板与详情面板，避免新组件在真实机型上溢出。
class _ZhLanguage extends LanguageNotifier {
  @override
  Locale? build() => const Locale('zh');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('spent_tracker_layout');
    await initDatabaseAt(tempDir.path);
  });

  tearDown(() async {
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      await Hive.close();
    });
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> pumpNarrow(WidgetTester tester) async {
    // 360 x 780 dp（常见窄屏）
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [languageProvider.overrideWith(_ZhLanguage.new)],
        child: const SpentTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('窄屏总览 / 明细 / 设置 / 弹层均不溢出', (tester) async {
    await pumpNarrow(tester);

    // 预置数据：长备注 + 大金额 + 多分类，覆盖文本截断与数字缩放
    await tester.runAsync(() async {
      final cats = Db.categories.values.toList();
      final today = DateUtil.toDayKey(DateTime.now());
      for (var i = 0; i < 6; i++) {
        await Db.transactions.add(
          Transaction(
            type: i.isEven ? 0 : 1,
            amount: i == 0 ? 123456789 : 1200 + i * 300,
            categoryId: cats[i % cats.length].key as int,
            date: today,
            note: i == 0 ? '这个备注特别特别长用来验证文本截断不会把布局撑破' : null,
            createdAt: DateTime.now().add(Duration(seconds: i)),
          ),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    final err = tester.takeException();
    expect(err, isNull, reason: '总览页溢出');

    // 明细页
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '明细页溢出');

    // 打开详情面板
    await tester.tap(find.text('餐饮').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '详情面板溢出');

    // 关闭面板
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    // 设置页
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '设置页溢出');

    // 回总览打开录入面板
    await tester.tap(find.text('总览'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '录入面板溢出');
  });
}
