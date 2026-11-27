import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:spent_tracker/core/io/import_parser.dart';
import 'package:spent_tracker/data/db/database.dart';
import 'package:spent_tracker/data/db/import_service.dart';
import 'package:spent_tracker/data/models/transaction.dart';

void main() {
  group('解析器', () {
    test('CSV：引号内的逗号与换行不破坏分列；非法行进入 issues', () {
      const csv = 'id,type,amount,currency,category,date,note,createdAt\n'
          '1,支出,12.50,SGD,餐饮,2026-01-02,"lunch, with comma",2026-01-02T10:00:00.000\n'
          '2,收入,abc,SGD,工资,2026-01-03,,\n'
          '3,收入,88.80,SGD,工资,2026/01/04,,\n';

      final result = parseImportContent(csv, fileName: 'backup.csv');

      expect(result.candidates.length, 1);
      final first = result.candidates.single;
      expect(first.transaction.amount, 1250, reason: '12.50 元 → 1250 分');
      expect(first.transaction.note, 'lunch, with comma');
      expect(first.transaction.type, 0);
      expect(first.categoryName, '餐饮');
      expect(result.issues.length, 2, reason: '金额非法与日期格式非法各算一条');
    });

    test('CSV：缺必需列时抛出可读错误', () {
      const csv = 'id,amount,date\n1,10.00,2026-01-02\n';
      expect(
        () => parseImportContent(csv, fileName: 'bad.csv'),
        throwsA(
          isA<ImportException>().having(
            (e) => e.code,
            'code',
            ImportErrorCode.csvMissingColumns,
          ),
        ),
      );
    });

    test('JSON：兼容中文类型与 0/1，缺省币种为 SGD', () {
      const json = '[{"type":"收入","amount":"100.00","date":"2026-02-01","category":"工资"},'
          '{"type":0,"amount":"9.90","date":"2026-02-02","currency":"cny"},'
          '{"type":"转账","amount":"1.00","date":"2026-02-03"}]';

      final result = parseImportContent(json, fileName: 'backup.json');

      expect(result.candidates.length, 2);
      expect(result.candidates[0].transaction.type, 1);
      expect(result.candidates[0].transaction.currency, 'SGD');
      expect(result.candidates[1].transaction.type, 0);
      expect(result.candidates[1].transaction.currency, 'CNY');
      expect(result.issues.length, 1, reason: '未知类型被拒');
    });
  });

  group('导入服务', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('spent_import_test');
      await initDatabaseAt(tempDir.path);
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('预演与落库：跳过重复、按名称映射分类、未匹配落未分类', () async {
      // 现有账目：餐饮 10.00 / 2026-01-01 / 备注「午餐」
      final food = Db.categories.values
          .firstWhere((c) => c.name == '餐饮' && c.type == 0);
      await Db.transactions.add(
        Transaction(
          type: 0,
          amount: 1000,
          categoryId: food.key as int,
          date: '2026-01-01',
          note: '午餐',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      const csv = 'type,amount,currency,category,date,note\n'
          // 与现有完全一致 → 重复
          '支出,10.00,SGD,餐饮,2026-01-01,午餐\n'
          // 新记录，分类可匹配
          '支出,20.00,SGD,餐饮,2026-01-05,晚餐\n'
          // 分类不存在 → 落未分类
          '支出,5.00,SGD,宠物,2026-01-06,猫粮\n'
          // 文件内与第 2 条重复 → 跳过
          '支出,20.00,SGD,餐饮,2026-01-05,晚餐\n';

      final parsed = parseImportContent(csv, fileName: 'a.csv');
      expect(parsed.candidates.length, 4);
      expect(parsed.issues, isEmpty);

      final dryRun = const ImportService().preview(parsed.candidates);
      expect(dryRun.toImport.length, 2);
      expect(dryRun.duplicates, 2, reason: '一条与库内重复，一条与文件内重复');
      expect(dryRun.unmatchedCategories, 1);

      final outcome = await const ImportService().commit(dryRun);
      expect(outcome.imported, 2);
      expect(outcome.unmatchedCategories, 1);
      expect(Db.transactions.length, 3, reason: '1 条原有 + 2 条新增');

      // 分类按名称正确映射，未知分类落为 null（未分类）
      final imported = Db.transactions.values
          .where((t) => t.note == '晚餐' || t.note == '猫粮')
          .toList();
      expect(imported.length, 2);
      final dinner = imported.firstWhere((t) => t.note == '晚餐');
      final catFood = imported.firstWhere((t) => t.note == '猫粮');
      expect(dinner.categoryId, food.key);
      expect(catFood.categoryId, isNull);
    });

    test('预演不改动数据', () async {
      const csv = 'type,amount,date\n支出,10.00,2026-01-02\n';
      final parsed = parseImportContent(csv, fileName: 'a.csv');
      const ImportService().preview(parsed.candidates);
      expect(Db.transactions.length, 0, reason: 'preview 必须无副作用');
    });
  });
}
