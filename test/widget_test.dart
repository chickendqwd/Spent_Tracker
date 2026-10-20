import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:spent_tracker/app.dart';
import 'package:spent_tracker/data/db/database.dart';
import 'package:spent_tracker/data/models/category.dart';
import 'package:spent_tracker/data/models/transaction.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('spent_tracker_test');
    await initDatabaseAt(tempDir.path);
  });

  tearDown(() async {
    // Hive.close 含真实文件 I/O，须在真实 zone 中执行，否则 FakeAsync 下挂起
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      await Hive.close();
    });
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    // 更高的视口，避免分类列表/录入面板超出折叠区（懒加载找不到控件）
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(child: SpentTrackerApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('首启：总览页渲染三卡片、空态与预设分类', (tester) async {
    await pumpApp(tester);

    expect(find.textContaining('本月总览'), findsOneWidget);
    expect(find.text('总支出'), findsOneWidget);
    expect(find.text('总收入'), findsOneWidget);
    expect(find.text('结余'), findsOneWidget);
    expect(find.text('本月暂无支出'), findsOneWidget);
    expect(find.text('还没有记录，点右下角「+」记一笔吧'), findsOneWidget);

    // 预设分类已写入数据库
    expect(Db.categories.length, 13);
  });

  testWidgets('录入闭环：记一笔支出后总览与明细同步更新', (tester) async {
    await pumpApp(tester);

    // 打开悬浮「+」
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('记一笔'), findsOneWidget);

    // 输入金额（金额键盘优先：TextInputType.numberWithOptions）
    final amountField = find.byType(TextField).first;
    await tester.enterText(amountField, '25.50');
    await tester.pumpAndSettle();

    // 默认选中「餐饮」（第一个支出分类），直接保存
    // Hive 落盘是真实异步：runAsync 让文件写入完成，面板随之关闭
    await tester.runAsync(() async {
      await tester.tap(find.text('保存'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // 面板关闭，总览出现该笔支出
    expect(find.text('记一笔'), findsNothing); // 录入面板已关闭
    expect(find.text('¥25.50'), findsWidgets);
    // 数据库落盘
    expect(Db.transactions.length, 1);
    final saved = Db.transactions.getAt(0)!;
    expect(saved.amount, 2550);
    expect(saved.type, 0);
    expect(saved.categoryId, isNotNull);
    expect(saved.note, isNull);

    // 明细页可见该记录
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    expect(find.text('交易明细'), findsOneWidget);
    expect(find.text('餐饮'), findsWidgets);
    expect(find.text('-¥25.50'), findsOneWidget);
  });

  testWidgets('编辑账目需二次确认', (tester) async {
    await pumpApp(tester);

    // 预置一笔账目（Hive 落盘为真实 I/O，需在 runAsync 中完成）
    await tester.runAsync(() async {
      await Db.transactions.add(
        Transaction(
          type: 0,
          amount: 1000,
          categoryId: Db.categories.getAt(0)?.key as int?,
          date: '2026-10-20',
          createdAt: DateTime.now(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    // 进入明细 → 点击记录 → 详情 → 编辑
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('餐饮'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    expect(find.text('编辑账目'), findsOneWidget);

    // 修改金额后保存 → 弹出确认框
    await tester.enterText(find.byType(TextField).first, '20.00');
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存修改'));
    await tester.pumpAndSettle();
    expect(find.text('确认保存修改？'), findsOneWidget);

    // 取消则不落盘
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(Db.transactions.getAt(0)!.amount, 1000);
  });

  testWidgets('删除分类：UI 二次确认；预设分类不可删', (tester) async {
    await pumpApp(tester);

    // 新增自定义分类（真实 I/O 在 runAsync 中完成）
    await tester.runAsync(() async {
      await Db.categories.add(Category(name: '宠物', type: 0));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    // 进入设置页：自定义分类有删除按钮，预设分类没有
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('删除'), findsOneWidget); // 仅自定义分类「宠物」可删

    // 点击删除 → 弹出二次确认（含规则提示）
    await tester.tap(find.byTooltip('删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除分类「宠物」？'), findsOneWidget);
    expect(find.textContaining('历史账目将变为「未分类」'), findsOneWidget);

    // 取消：分类保留，确认框关闭
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('删除'), findsOneWidget);

    // 预设分类始终没有删除按钮
    await tester.tap(find.text('收入分类'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('删除'), findsNothing);
    await tester.tap(find.text('支出分类'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('删除'), findsOneWidget);

    // 「确认删除 → 历史账目置未分类、预设禁删」的数据规则由
    // category_repository_test.dart 单测覆盖（真实异步环境）
  });

  testWidgets('月度总结：分类占比与结余正确', (tester) async {
    await pumpApp(tester);

    // 预置：支出 25.5（餐饮）+ 10（交通），收入 100（真实 I/O 在 runAsync 中完成）
    final expenseCat = Db.categories.values.firstWhere((c) => c.name == '餐饮');
    final trafficCat = Db.categories.values.firstWhere((c) => c.name == '交通');
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await tester.runAsync(() async {
      await Db.transactions.add(
        Transaction(
          type: 0,
          amount: 2550,
          categoryId: expenseCat.key as int,
          date: today,
          createdAt: DateTime.now(),
        ),
      );
      await Db.transactions.add(
        Transaction(
          type: 0,
          amount: 1000,
          categoryId: trafficCat.key as int,
          date: today,
          createdAt: DateTime.now().add(const Duration(seconds: 1)),
        ),
      );
      await Db.transactions.add(
        Transaction(
          type: 1,
          amount: 10000,
          categoryId: null,
          date: today,
          createdAt: DateTime.now().add(const Duration(seconds: 2)),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    await tester.pumpAndSettle();

    expect(find.text('¥35.50'), findsOneWidget); // 总支出 25.50+10.00
    expect(find.text('¥100.00'), findsOneWidget); // 总收入
    expect(find.text('¥64.50'), findsOneWidget); // 结余
    // 分类占比图例
    expect(find.text('餐饮'), findsWidgets);
    expect(find.text('交通'), findsWidgets);
  });
}
