import 'dart:convert';
import 'dart:io';

import 'package:fast_gbk/fast_gbk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:spent_tracker/app.dart';
import 'package:spent_tracker/core/io/encoding_util.dart';
import 'package:spent_tracker/core/io/import_parser.dart';
import 'package:spent_tracker/core/utils/date_util.dart';
import 'package:spent_tracker/data/db/database.dart';
import 'package:spent_tracker/data/db/import_service.dart';
import 'package:spent_tracker/data/models/category.dart';
import 'package:spent_tracker/data/models/transaction.dart';
import 'package:spent_tracker/l10n/l10n.dart';
import 'package:spent_tracker/state/language_providers.dart';

/// 固定界面语言（测试用）：不读 Hive，直接返回给定 locale。
class _FixedLanguage extends LanguageNotifier {
  _FixedLanguage(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('spent_i18n_test');
    await initDatabaseAt(tempDir.path);
  });

  tearDown(() async {
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      await Hive.close();
    });
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('三语：界面文案与预设分类名跟随语言，自建分类保持原文', () async {
    final zh = await AppLocalizations.delegate.load(const Locale('zh'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ja = await AppLocalizations.delegate.load(const Locale('ja'));

    expect(zh.overviewTitle, '总览');
    expect(en.overviewTitle, 'Overview');
    expect(ja.overviewTitle, '概要');

    final food = Category(
      name: '餐饮',
      type: 0,
      isPreset: true,
      presetKey: 'food',
    );
    expect(categoryDisplayName(zh, food), '餐饮');
    expect(categoryDisplayName(en, food), 'Food');
    expect(categoryDisplayName(ja, food), '食費');

    final custom = Category(name: '宠物', type: 0);
    expect(categoryDisplayName(en, custom), '宠物');

    expect(categoryDisplayName(en, null), 'Uncategorized');
  });

  test('GBK：中文备份按 GBK 解码，不再乱码', () {
    // 模拟 Windows Excel 的 GBK 导出
    final bytes = gbk.encode('餐饮');
    expect(bytes.length, greaterThan(2), reason: 'GBK 中文字节为双字节');
    expect(ImportTextDecoder.decode(bytes), '餐饮');
    // UTF-8 仍优先按 UTF-8 解码
    expect(ImportTextDecoder.decode(utf8.encode('餐饮')), '餐饮');
  });

  test('中性标识：英文备份导入中文库仍命中预设分类，不落未分类', () async {
    const csv = 'type,amount,currency,categoryKey,categoryName,date,note\n'
        'expense,10.00,SGD,food,Food,2026-01-02,lunch\n'
        'income,100.00,SGD,salary,Salary,2026-01-03,pay\n';

    final parsed = parseImportContent(csv, fileName: 'en.csv');
    expect(parsed.issues, isEmpty);
    expect(parsed.candidates[0].categoryKey, 'food');

    final dryRun = const ImportService().preview(parsed.candidates);
    expect(dryRun.unmatchedCategories, 0);

    await const ImportService().commit(dryRun);
    final lunch =
        Db.transactions.values.firstWhere((t) => t.note == 'lunch');
    final category =
        Db.categories.values.firstWhere((c) => c.key == lunch.categoryId);
    expect(category.presetKey, 'food');
    expect(category.name, '餐饮', reason: '中文库中保留原有存储名');
  });

  testWidgets('英文界面：导航与空态文案本地化，「查看全部」进入明细页', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          languageProvider.overrideWith(() => _FixedLanguage(const Locale('en'))),
        ],
        child: const SpentTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Details'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
    expect(
      find.text('Nothing here yet — tap “+” to add an entry'),
      findsOneWidget,
    );

    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();

    expect(find.text('Search note, category or amount'), findsOneWidget);
  });

  testWidgets('搜索口径：英文界面按分类展示名、币种符号与金额匹配', (tester) async {
    // 一条今天的餐饮支出（默认时间范围「本周」包含今天）
    final food = Db.categories.values.firstWhere((c) => c.presetKey == 'food');
    await tester.runAsync(() async {
      await Db.transactions.add(
        Transaction(
          type: 0,
          amount: 2550,
          categoryId: food.key as int,
          date: DateUtil.toDayKey(DateTime.now()),
          note: 'lunch',
          createdAt: DateTime.now(),
        ),
      );
    });

    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          languageProvider.overrideWith(() => _FixedLanguage(const Locale('en'))),
        ],
        child: const SpentTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 进入明细页
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(find.text('lunch'), findsOneWidget);

    // 分类展示名（英文 Food）能命中——旧口径只比存储名「餐饮」，搜不到
    await tester.enterText(find.byType(TextField).first, 'Food');
    await tester.pumpAndSettle();
    expect(find.text('lunch'), findsOneWidget);

    // 币种符号 S$ 能命中
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, r'S$');
    await tester.pumpAndSettle();
    expect(find.text('lunch'), findsOneWidget);

    // 金额（显示值 25.50）能命中
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '25.50');
    await tester.pumpAndSettle();
    expect(find.text('lunch'), findsOneWidget);

    // 无关关键词不命中
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('lunch'), findsNothing);
  });
}
