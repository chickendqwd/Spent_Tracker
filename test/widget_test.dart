import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:spent_tracker/app.dart';
import 'package:spent_tracker/core/theme/app_schemes.dart';
import 'package:spent_tracker/core/theme/app_theme.dart';
import 'package:spent_tracker/core/utils/date_util.dart';
import 'package:spent_tracker/data/db/currency_repository.dart';
import 'package:spent_tracker/data/db/database.dart';
import 'package:spent_tracker/data/models/category.dart';
import 'package:spent_tracker/data/models/transaction.dart';
import 'package:spent_tracker/state/language_providers.dart';
import 'package:spent_tracker/state/theme_providers.dart';

/// 测试固定中文界面：断言文案不随宿主机语言（可能解析为 en）漂移。
class _ZhLanguage extends LanguageNotifier {
  @override
  Locale? build() => const Locale('zh');
}

void main() {
  // 普通 test 与 testWidgets 混跑，确保 binding 在两者中都可用的 Hive close
  TestWidgetsFlutterBinding.ensureInitialized();

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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [languageProvider.overrideWith(_ZhLanguage.new)],
        child: const SpentTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('首启：总览页渲染三卡片、空态与预设分类', (tester) async {
    await pumpApp(tester);

    expect(find.text('总览'), findsWidgets);
    expect(find.text('总支出'), findsOneWidget);
    expect(find.text('总收入'), findsOneWidget);
    expect(find.text('结余'), findsOneWidget);
    expect(find.text('区间内暂无支出'), findsOneWidget);
    expect(find.text('区间内还没有记录，点右下角「+」记一笔吧'), findsOneWidget);

    // 预设分类与预设币种已写入数据库
    expect(Db.categories.length, 13);
    // SGD / CNY / MYR / JPY（v3.3 新增 JPY）
    expect(Db.currencies.length, 4);
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

    // 面板关闭，总览出现该笔支出（默认币种 SGD，符号 S$）
    expect(find.text('记一笔'), findsNothing); // 录入面板已关闭
    expect(find.text('S\$25.50'), findsWidgets);
    // 数据库落盘
    expect(Db.transactions.length, 1);
    final saved = Db.transactions.getAt(0)!;
    expect(saved.amount, 2550);
    expect(saved.type, 0);
    expect(saved.categoryId, isNotNull);
    expect(saved.note, isNull);
    expect(saved.currency, 'SGD');

    // 明细页可见该记录
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    expect(find.text('交易明细'), findsOneWidget);
    expect(find.text('餐饮'), findsWidgets);
    expect(find.text('-S\$25.50'), findsOneWidget);
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
          // 用「今天」而非固定日期：默认区间是本月，硬编码日期会跨月失效
          date: DateUtil.toDayKey(DateTime.now()),
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

    // 进入设置 → 分类管理：自定义分类有删除按钮，预设分类没有
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('分类管理'));
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

    expect(find.text('S\$35.50'), findsOneWidget); // 总支出 25.50+10.00
    expect(find.text('S\$100.00'), findsOneWidget); // 总收入
    expect(find.text('S\$64.50'), findsOneWidget); // 结余
    // 分类占比图例
    expect(find.text('餐饮'), findsWidgets);
    expect(find.text('交通'), findsWidgets);
  });

  testWidgets('搜索：按备注关键词过滤交易明细', (tester) async {
    await pumpApp(tester);

    // 预置：餐饮(备注 午餐) + 交通(备注 地铁)，均为本月
    final expenseCat = Db.categories.values.firstWhere((c) => c.name == '餐饮');
    final trafficCat = Db.categories.values.firstWhere((c) => c.name == '交通');
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await tester.runAsync(() async {
      await Db.transactions.add(
        Transaction(
          type: 0,
          amount: 1000,
          categoryId: expenseCat.key as int,
          date: today,
          note: '午餐',
          createdAt: DateTime.now(),
        ),
      );
      await Db.transactions.add(
        Transaction(
          type: 0,
          amount: 500,
          categoryId: trafficCat.key as int,
          date: today,
          note: '地铁',
          createdAt: DateTime.now().add(const Duration(seconds: 1)),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    await tester.pumpAndSettle();

    // 进入明细页，两条都可见
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    expect(find.text('餐饮'), findsWidgets);
    expect(find.text('交通'), findsWidgets);

    // 按备注搜索「午餐」→ 只保留餐饮
    await tester.enterText(find.byType(TextField).first, '午餐');
    await tester.pumpAndSettle();
    expect(find.text('餐饮'), findsWidgets);
    expect(find.text('交通'), findsNothing);

    // 清空 → 两条恢复
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    expect(find.text('交通'), findsWidgets);
  });

  testWidgets('外观：切换深色后主题与配色生效并持久化', (tester) async {
    await pumpApp(tester);

    // 设置 → 外观
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('外观'));
    await tester.pumpAndSettle();

    // 切换到深色（点击会触发 Hive 写入，须在真实 zone 中执行，否则 FakeAsync 下挂起）
    await tester.runAsync(() async {
      await tester.tap(find.text('深色'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();

    // 1) 主题亮度变为 dark
    final ctx = tester.element(find.byType(Scaffold).last);
    expect(Theme.of(ctx).brightness, Brightness.dark);

    // 2) 语义色取自深色 palette（收入色与浅色不同，可区分旧实现）
    final palette = Theme.of(ctx).extension<AppPalette>();
    expect(palette, isNotNull);
    expect(palette!.income, AppPalette.dark.income);
    expect(AppPalette.dark.income, isNot(AppPalette.light.income));

    // 3) 选择出现在 UI（打勾）
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('趋势卡：默认本周 + 单字星期标签，区间可切换', (tester) async {
    await pumpApp(tester);

    // v3.3.1：默认档位是「本周」，X 轴在日期下多一行单字星期
    // 顶部时间筛选器同样有「本周」，故用 findsWidgets
    expect(find.text('本周'), findsWidgets);
    // 本周必定包含周一，故「一」一定出现在 X 轴上
    expect(find.text('一'), findsWidgets);

    // 本周 / 本月 / 近3月 平铺，长区间收进「更多…」
    expect(find.text('本月'), findsWidgets);
    expect(find.text('近3月'), findsOneWidget);
    expect(find.text('更多…'), findsOneWidget);

    // 打开更多菜单 → 出现近 6 月 / 近 12 月
    await tester.tap(find.text('更多…'));
    await tester.pumpAndSettle();
    expect(find.text('近12月'), findsWidgets);

    // 选中近 12 月后：当前档位变成常驻 chip，入口保持可用
    await tester.tap(find.text('近12月').last);
    await tester.pumpAndSettle();
    expect(find.text('近12月'), findsOneWidget);
    expect(find.text('近6月'), findsNothing);
    expect(find.text('更多…'), findsOneWidget);
    // 切到长区间后不再显示单字星期
    expect(find.text('一'), findsNothing);
  });

  testWidgets('货币页：JPY 预设已展示，SGD 为基准，非基准币种可设为基准', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('货币与汇率'));
    await tester.pumpAndSettle();

    // JPY 预设已存在；CNY 与 JPY 符号同为 ¥，靠名称区分
    expect(find.textContaining('日元 (JPY)'), findsOneWidget);
    expect(find.textContaining('人民币 (CNY)'), findsOneWidget);

    // 基准标记只出现在 SGD 上，其余三个币种各有操作菜单
    expect(find.text('基准'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNWidgets(3));

    // 菜单里提供「修改汇率」与「设为基准币种」
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    expect(find.text('修改汇率'), findsOneWidget);
    expect(find.text('设为基准币种'), findsOneWidget);
  });

  testWidgets('基准为 JPY 时：总览符号变「円」，货币页星标落在日元行', (tester) async {
    // 先把基准切成 JPY（FakeAsync 下 Hive 写入须走真实异步）
    await tester.runAsync(() async {
      await const CurrencyRepository().setBase('JPY');
    });
    await pumpApp(tester);

    // 总览汇总符号跟随基准 → 円，而不是 S$ 或 ¥
    expect(find.text('円0.00'), findsWidgets);
    expect(find.text('S\$0.00'), findsNothing);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('货币与汇率'));
    await tester.pumpAndSettle();

    // 星标必须在日元行，SGD 行不再是基准
    final jpyTile = find.ancestor(
      of: find.textContaining('日元 (JPY)'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(of: jpyTile, matching: find.byIcon(Icons.star)),
      findsOneWidget,
    );
    // 日元为基准 → 不可设为基准，只剩 SGD / CNY / MYR 三个可操作菜单
    expect(find.byType(PopupMenuButton<String>), findsNWidgets(3));
  });

  // 持久化属于真实 I/O，单独用真实异步验证（FakeAsync 下 Hive 写入不推进）
  test('外观：选择的模式写入 Hive 并在新实例中恢复', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(themeModeProvider.notifier).set(ThemeMode.dark);
    expect(Db.settings.get(ThemeModeNotifier.storageKey), 'dark');

    // 重新读取：模拟重启后从 Hive 恢复
    final restarted = ProviderContainer();
    addTearDown(restarted.dispose);
    expect(restarted.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('配色方案：默认黑白灰、10 套可选、切换后主色跟随强调色', (tester) async {
    await pumpApp(tester);

    // 默认是黑白灰：亮色主色为近黑
    final shellCtx = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(shellCtx).extension<AppPalette>()!.primary,
        AppPalette.light.primary);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('配色方案'));
    await tester.pumpAndSettle();

    // 10 套方案全部可见（默认项带「默认」标签）
    expect(find.text('黑白灰'), findsOneWidget);
    expect(find.text('默认'), findsOneWidget);
    expect(find.text('深林苔'), findsOneWidget);
    expect(find.text('海军金'), findsOneWidget);
    expect(find.text('柔粉岩'), findsOneWidget);
    // 每行都有 3 个色球（10 行 × 3）
    expect(AppPaletteSchemes.all.length, 10);
    expect(
      AppPaletteSchemes.all.every((s) => s.dots.length == 3),
      isTrue,
    );
    // 只有一个选中勾
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    // 切到深林苔：Hive 写入须在真实 zone 中执行
    await tester.runAsync(() async {
      await tester.tap(find.text('深林苔'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();

    final pageCtx = tester.element(find.byType(Scaffold).last);
    expect(
      Theme.of(pageCtx).extension<AppPalette>()!.primary,
      AppPaletteSchemes.deepForest.accent,
    );
    expect(Db.settings.get(PaletteSchemeNotifier.storageKey), 'deepForest');

    // 新实例从 Hive 恢复同一套配色
    final restarted = ProviderContainer();
    addTearDown(restarted.dispose);
    expect(restarted.read(paletteSchemeProvider).id, 'deepForest');
  });
}
