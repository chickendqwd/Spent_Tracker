import 'package:flutter/widgets.dart';

import '../data/models/budget.dart';
import '../data/models/category.dart';
import '../data/models/currency.dart';
import '../data/models/recurring_rule.dart';
import '../data/models/transaction_type.dart';
import '../core/analytics/trend_analytics.dart';
import '../core/io/import_parser.dart';
import '../data/preset_categories.dart';
import '../state/time_range_providers.dart';
import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart' show AppLocalizations;

/// 全局取当前语言文案：`context.l10n.xxx`
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// 枚举与日期的本地化展示。
extension L10nLabels on AppLocalizations {
  String txType(TransactionType type) =>
      type == TransactionType.expense ? typeExpense : typeIncome;

  String txTypeByIndex(int index) =>
      index == 0 ? typeExpense : typeIncome;

  String budgetType(BudgetType type) =>
      type == BudgetType.total ? budgetTypeTotal : budgetTypeCategory;

  String frequency(RecurringFrequency frequency) => switch (frequency) {
        RecurringFrequency.weekly => freqWeekly,
        RecurringFrequency.monthly => freqMonthly,
        RecurringFrequency.yearly => freqYearly,
      };

  String trendRange(TrendRange range) => switch (range) {
        TrendRange.week => trendThisWeek,
        TrendRange.month => trendThisMonth,
        TrendRange.threeMonths => trendThreeMonths,
        TrendRange.sixMonths => trendSixMonths,
        TrendRange.twelveMonths => trendTwelveMonths,
      };

  String timeRange(TimeRangeKind kind) => switch (kind) {
        TimeRangeKind.thisWeek => rangeThisWeek,
        TimeRangeKind.thisMonth => rangeThisMonth,
        TimeRangeKind.lastMonth => rangeLastMonth,
        TimeRangeKind.last7Days => rangeLast7Days,
        TimeRangeKind.custom => rangeCustom,
      };

  /// 周一…周日
  String weekdayName(int weekday) => switch (weekday) {
        1 => weekdayMonth,
        2 => weekdayTue,
        3 => weekdayWed,
        4 => weekdayThu,
        5 => weekdayFri,
        6 => weekdaySat,
        _ => weekdaySun,
      };

  /// 单字星期（趋势图第二行）
  String weekdayChar(int weekday) => switch (weekday) {
        1 => weekdayCharMon,
        2 => weekdayCharTue,
        3 => weekdayCharWed,
        4 => weekdayCharThu,
        5 => weekdayCharFri,
        6 => weekdayCharSat,
        _ => weekdayCharSun,
      };

  String dateHeader(DateTime d) => dateListHeader(
        '${d.month}',
        '${d.day}',
        weekdayName(d.weekday),
      );

  String monthTitleOf(DateTime d) =>
      monthTitle('${d.year}', '${d.month}');

  String yearLabelOf(int year) => yearLabel('$year');
}

/// 分类展示名：预设分类跟随语言，自建分类保持用户输入的名称。
String categoryDisplayName(AppLocalizations l10n, Category? category) {
  if (category == null) return l10n.commonUncategorized;
  final key = category.presetKey;
  if (key == null) return category.name;
  return PresetCategories.nameFor(key, l10n.localeName) ?? category.name;
}

/// 数值 → 千分位两位小数（无币种符号以外的格式差异）
String localeNumber(num value) => value.toStringAsFixed(2);

/// 货币展示名：预设币种跟随语言，非预设币种沿用用户填写的名称。
String currencyDisplayName(AppLocalizations l10n, Currency currency) =>
    switch (currency.code) {
      'SGD' => l10n.curSgd,
      'CNY' => l10n.curCny,
      'MYR' => l10n.curMyr,
      'JPY' => l10n.curJpy,
      _ => currency.name,
    };

/// 导入文件级错误 → 当前语言文案
String importErrorText(AppLocalizations l10n, ImportException e) =>
    switch (e.code) {
      ImportErrorCode.unsupportedFile =>
        l10n.importErrorUnsupported(e.fileName ?? ''),
      ImportErrorCode.jsonInvalid => l10n.importErrorJsonInvalid,
      ImportErrorCode.jsonNotArray => l10n.importErrorJsonNotArray,
      ImportErrorCode.csvEmpty => l10n.importErrorCsvEmpty,
      ImportErrorCode.csvMissingColumns =>
        l10n.importErrorCsvMissing(e.columns.join(', ')),
    };

/// 导入行级错误 → 当前语言文案
String importIssueText(AppLocalizations l10n, ImportIssue issue) =>
    switch (issue.code) {
      ImportIssueCode.rowNotObject => l10n.importErrorRowNotObject,
      ImportIssueCode.invalidType => l10n.importErrorType(issue.value),
      ImportIssueCode.invalidAmount =>
        l10n.importErrorAmount(issue.value),
      ImportIssueCode.invalidDate => l10n.importErrorDate(issue.value),
    };
