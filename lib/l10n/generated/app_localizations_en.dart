// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Spent_Tracker';

  @override
  String get curSgd => 'Singapore dollar';

  @override
  String get curCny => 'Chinese yuan';

  @override
  String get curMyr => 'Malaysian ringgit';

  @override
  String get curJpy => 'Japanese yen';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonMore => 'More…';

  @override
  String get commonCustom => 'Custom';

  @override
  String get commonAmount => 'Amount';

  @override
  String get commonCurrency => 'Currency';

  @override
  String get commonCategory => 'Category';

  @override
  String get commonNote => 'Note';

  @override
  String get commonDate => 'Date';

  @override
  String get commonType => 'Type';

  @override
  String get commonUncategorized => 'Uncategorized';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get commonNone => 'None';

  @override
  String commonUnitEntries(String count) {
    return '$count entries';
  }

  @override
  String get commonOverflowMenu => 'More actions';

  @override
  String get navOverview => 'Overview';

  @override
  String get navTransactions => 'Details';

  @override
  String get navSettings => 'Settings';

  @override
  String get fabAdd => 'Add entry';

  @override
  String get typeExpense => 'Expense';

  @override
  String get typeIncome => 'Income';

  @override
  String get budgetTypeTotal => 'Total budget';

  @override
  String get budgetTypeCategory => 'Category budget';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqMonthly => 'Monthly';

  @override
  String get freqYearly => 'Yearly';

  @override
  String get weekdayMonth => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get weekdayCharMon => 'M';

  @override
  String get weekdayCharTue => 'T';

  @override
  String get weekdayCharWed => 'W';

  @override
  String get weekdayCharThu => 'T';

  @override
  String get weekdayCharFri => 'F';

  @override
  String get weekdayCharSat => 'S';

  @override
  String get weekdayCharSun => 'S';

  @override
  String dateListHeader(String month, String day, String weekday) {
    return '$month/$day $weekday';
  }

  @override
  String monthTitle(String year, String month) {
    return '$year/$month';
  }

  @override
  String yearLabel(String year) {
    return '$year';
  }

  @override
  String monthShort(String month) {
    return 'Month $month';
  }

  @override
  String get overviewTitle => 'Overview';

  @override
  String get overviewAnnualTooltip => 'Annual report';

  @override
  String get overviewTotalExpense => 'Total spent';

  @override
  String get overviewTotalIncome => 'Total income';

  @override
  String get overviewBalance => 'Balance';

  @override
  String get overviewMonthlyBudget => 'Monthly budget';

  @override
  String get overviewOverBudget => 'Over budget';

  @override
  String get overviewTrendTitle => 'Cash flow trend';

  @override
  String overviewTodayDue(String count) {
    return '$count recurring entries due today, tap to prefill';
  }

  @override
  String get overviewCategoryAnalysis => 'Category breakdown';

  @override
  String get overviewNoExpenseInRange => 'No spending in this period';

  @override
  String get overviewNoIncomeInRange => 'No income in this period';

  @override
  String get overviewRecent => 'Recent entries';

  @override
  String get overviewRecentEmpty =>
      'Nothing here yet — tap “+” to add an entry';

  @override
  String get overviewViewAll => 'View all';

  @override
  String get trendThisWeek => 'This week';

  @override
  String get trendThisMonth => 'This month';

  @override
  String get trendThreeMonths => 'Last 3M';

  @override
  String get trendSixMonths => 'Last 6M';

  @override
  String get trendTwelveMonths => 'Last 12M';

  @override
  String get trendMoreRanges => 'More ranges';

  @override
  String get rangeThisWeek => 'This week';

  @override
  String get rangeThisMonth => 'This month';

  @override
  String get rangeLastMonth => 'Last month';

  @override
  String get rangeLast7Days => 'Last 7D';

  @override
  String get rangeCustom => 'Custom';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get transactionsSearchHint => 'Search note, category or amount';

  @override
  String get transactionsAll => 'All';

  @override
  String get transactionsAllCategories => 'All categories';

  @override
  String get transactionsNoMatch => 'No matching entries';

  @override
  String get entryAddTitle => 'Add entry';

  @override
  String get entryEditTitle => 'Edit entry';

  @override
  String get entryAmountEmpty => 'Please enter an amount';

  @override
  String get entryAmountInvalid =>
      'Invalid amount — enter a number (up to 7 integer and 2 decimal digits)';

  @override
  String get entryAmountTooLong => 'At most 7 integer digits and 2 decimals';

  @override
  String get entryAmountPositive => 'Amount must be greater than 0';

  @override
  String get entrySelectCategory => 'Please choose a category';

  @override
  String get entryAddCategoryFirst =>
      'Add a category of this type in Settings → Categories first';

  @override
  String get entrySaveChanges => 'Save changes';

  @override
  String get entryConfirmEditTitle => 'Save changes?';

  @override
  String get entryConfirmEditBody => 'The existing entry will be overwritten.';

  @override
  String get entryConfirmSave => 'Save';

  @override
  String entryOverCategoryBudget(String amount) {
    return 'This expense will exceed the category budget ($amount)';
  }

  @override
  String entryOverTotalBudget(String amount) {
    return 'This expense will exceed the monthly budget ($amount)';
  }

  @override
  String get detailTitle => 'Entry details';

  @override
  String get detailDeleteTitle => 'Delete this entry?';

  @override
  String detailDeleteBody(String type, String amount) {
    return '$type $amount — this cannot be undone.';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGroupGeneral => 'General';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceSubtitle => 'System / Light / Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle => 'System / 中文 / English / 日本語';

  @override
  String get settingsGroupBookkeeping => 'Bookkeeping';

  @override
  String get settingsCategories => 'Categories';

  @override
  String get settingsCategoriesSubtitle => 'Preset and custom categories';

  @override
  String get settingsBudgets => 'Budgets';

  @override
  String get settingsBudgetsSubtitle =>
      'Monthly total and per-category budgets';

  @override
  String get settingsRecurring => 'Recurring entries';

  @override
  String get settingsRecurringSubtitle => 'Weekly / monthly / yearly reminders';

  @override
  String get settingsGroupAnalysis => 'Analysis';

  @override
  String get settingsAnnual => 'Annual report';

  @override
  String get settingsAnnualSubtitle =>
      'Yearly totals, monthly bars and category ranking';

  @override
  String get settingsGroupData => 'Data';

  @override
  String get settingsCurrency => 'Currency & rates';

  @override
  String get settingsCurrencySubtitle =>
      'Switch base currency; rates manual or fetched';

  @override
  String get settingsExport => 'Export data';

  @override
  String get settingsExportSubtitle => 'Export CSV / JSON backup';

  @override
  String get settingsImport => 'Import data';

  @override
  String get settingsImportSubtitle =>
      'Restore from CSV / JSON (append, duplicates skipped)';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceThemeSystem => 'Follow system';

  @override
  String get appearanceThemeSystemSub =>
      'Match the light/dark setting of your device';

  @override
  String get appearanceThemeLight => 'Light';

  @override
  String get appearanceThemeLightSub => 'Always use the light theme';

  @override
  String get appearanceThemeDark => 'Dark';

  @override
  String get appearanceThemeDarkSub => 'Always use the dark theme';

  @override
  String get appearanceNote =>
      'In dark mode, chart and amount colours adapt to the background brightness.';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageFollowSystem => 'Follow system';

  @override
  String get languageSystemSub => 'Match the language of your device';

  @override
  String get languageChinese => '中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageNote =>
      'Interface and preset category names update immediately; custom category names, notes and other user content stay as written.';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesExpenseTab => 'Expense';

  @override
  String get categoriesIncomeTab => 'Income';

  @override
  String get categoriesPresetLabel => 'Preset';

  @override
  String get categoriesAddExpense => 'Add expense category';

  @override
  String get categoriesAddIncome => 'Add income category';

  @override
  String get categoriesNewTitle => 'New category';

  @override
  String get categoriesEditTitle => 'Edit category';

  @override
  String categoriesDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get categoriesDeleteBody =>
      'Existing entries in this category become Uncategorized. This cannot be undone.';

  @override
  String get categoriesNameLabel => 'Category name';

  @override
  String get categoriesNameHint => 'e.g. Pets, Gym';

  @override
  String get categoriesNameEmpty => 'Please enter a category name';

  @override
  String get categoriesIconLabel => 'Icon';

  @override
  String get categoriesCustomIconLabel => 'Custom icon (optional)';

  @override
  String get categoriesCustomIconHint => 'One emoji, e.g. 🐹';

  @override
  String get categoriesCustomIconInvalid =>
      'Enter one emoji (up to 2 characters)';

  @override
  String get categoriesCurrent => 'Current:';

  @override
  String categoriesBelongsTo(String type) {
    return 'Type: $type';
  }

  @override
  String get budgetsTitle => 'Budgets';

  @override
  String budgetsCurrentMonth(String month) {
    return 'Current month: $month';
  }

  @override
  String budgetsIntro(String name) {
    return 'Amounts default to the current base currency ($name); each budget can also use its own currency. A month without an explicit budget inherits the most recent month that has one; delete that month\'s budget to mean “no limit”.';
  }

  @override
  String get budgetsDefaultCurrency => 'Default budget currency';

  @override
  String get budgetsCurrencyFollowBase => 'Follow base currency';

  @override
  String get budgetsCurrency => 'Budget currency';

  @override
  String budgetsApprox(String amount) {
    return '≈ $amount';
  }

  @override
  String get budgetsEmpty => 'No budget this month\nTap “+” to add one';

  @override
  String get budgetsAdd => 'Add budget';

  @override
  String budgetsCategoryWith(String name) {
    return 'Category budget · $name';
  }

  @override
  String budgetsMonthLabel(String month) {
    return 'Month: $month';
  }

  @override
  String get budgetsDeleteTitle => 'Delete this budget?';

  @override
  String get budgetsDeleteBody =>
      'Only future checks are affected; existing entries are untouched.';

  @override
  String get budgetsDialogTitle => 'Budget';

  @override
  String budgetsAmountLabel(String code) {
    return 'Amount ($code)';
  }

  @override
  String get budgetsInvalidAmount => 'Please enter a valid amount';

  @override
  String get budgetsAddExpenseFirst => 'Add an expense category first';

  @override
  String get recurringTitle => 'Recurring entries';

  @override
  String get recurringIntro =>
      'When a rule is due, a “due today” banner appears on the overview page; tap to prefill and confirm manually (nothing is booked automatically).';

  @override
  String get recurringEmpty => 'No recurring rules yet\nTap “+” to add one';

  @override
  String get recurringAdd => 'Add rule';

  @override
  String get recurringActive => 'Active';

  @override
  String get recurringInactive => 'Paused';

  @override
  String get recurringEditTooltip => 'Edit';

  @override
  String get recurringDeleteTitle => 'Delete this rule?';

  @override
  String get recurringDeleteBody =>
      'Only future reminders are affected; booked entries are untouched.';

  @override
  String get recurringDialogTitle => 'Recurring rule';

  @override
  String get recurringFrequencyLabel => 'Frequency';

  @override
  String get recurringWeekdayLabel => 'Weekday';

  @override
  String recurringWeekdayOption(String char) {
    return '$char';
  }

  @override
  String get recurringDayLabel => 'Day (1-31)';

  @override
  String get recurringDayHelper =>
      'Dates beyond the month length fall on the month end';

  @override
  String get recurringMonthEndNote =>
      'Short months clamp to the month end: the 31st becomes Apr 30 or Feb 28';

  @override
  String recurringStartDate(String date) {
    return 'Start date: $date';
  }

  @override
  String recurringStartLabel(String date) {
    return 'Starts $date';
  }

  @override
  String get recurringNoteOptional => 'Note (optional)';

  @override
  String get recurringAddCategoryFirst => 'Add a category of this type first';

  @override
  String recurringDescWeekly(String weekday) {
    return 'Every $weekday';
  }

  @override
  String recurringDescMonthly(String day) {
    return 'Day $day each month';
  }

  @override
  String recurringDescYearly(String month, String day) {
    return 'Every year on $month/$day';
  }

  @override
  String get recurringNotCategorized => 'Uncategorized';

  @override
  String get annualTitle => 'Annual report';

  @override
  String get annualYearlyExpense => 'Spent';

  @override
  String get annualYearlyIncome => 'Income';

  @override
  String get annualBalance => 'Balance';

  @override
  String get annualRecordCount => 'Entries';

  @override
  String get annualAvgExpense => 'Avg / month';

  @override
  String get annualPeakMonth => 'Peak month';

  @override
  String get annualNoRecords => 'No records this year';

  @override
  String annualChartTitle(String year) {
    return 'Monthly cash flow ($year)';
  }

  @override
  String annualUnit(String symbol) {
    return 'Unit: $symbol';
  }

  @override
  String get annualCategoryRanking => 'Category ranking';

  @override
  String get annualNoExpense => 'No spending this year';

  @override
  String get annualNoIncome => 'No income this year';

  @override
  String get annualPrevYear => 'Previous year';

  @override
  String get annualNextYear => 'Next year';

  @override
  String get currencyTitle => 'Currency & rates';

  @override
  String currencyIntro(String name, String code) {
    return 'Base currency: $name ($code). All aggregates (balance, trend, budgets, category shares) use the base currency; lists and details keep each entry\'s own currency. Rates are shown as “1 unit = ? $code” and can be edited or fetched online.';
  }

  @override
  String get currencyRefresh => 'Fetch rates online';

  @override
  String get currencyRefreshFailed => 'Fetch failed; manual rates kept';

  @override
  String currencyRefreshFailedWith(String error) {
    return 'Fetch failed; manual rates kept: $error';
  }

  @override
  String currencyUpdated(String list) {
    return 'Updated: $list';
  }

  @override
  String currencyMissing(String codes) {
    return '; $codes unavailable, local rates kept';
  }

  @override
  String get currencyBaseLabel => 'Base currency';

  @override
  String get currencyBaseBadge => 'Base';

  @override
  String currencyRateLine(String code, String rate, String base) {
    return '1 $code = $rate $base';
  }

  @override
  String get currencySetAsBase => 'Set as base currency';

  @override
  String get currencyEditRate => 'Edit rate';

  @override
  String currencyConfirmBaseTitle(String code) {
    return 'Set $code as base currency?';
  }

  @override
  String currencyConfirmBaseBody(String name) {
    return 'Aggregates (balance, trend, budgets, category shares) will be shown in $name.\nStored amounts of entries and budgets are not rewritten — only converted for display; lists still show each entry\'s own currency.';
  }

  @override
  String get currencySwitch => 'Switch';

  @override
  String currencyEditRateTitle(String code) {
    return 'Edit $code rate';
  }

  @override
  String currencyRateInputLabel(String code, String base) {
    return '1 $code = ? $base';
  }

  @override
  String get currencyPositiveRate => 'Enter a positive rate';

  @override
  String get importTitle => 'Import data';

  @override
  String get importRestore => 'Restore from a backup';

  @override
  String get importIntro =>
      'CSV / JSON exported by this app is supported. Import appends: existing entries are never deleted or overwritten; rows matching on type, amount, currency, date, note and category are skipped as duplicates.';

  @override
  String get importChooseFile => 'Choose a CSV / JSON file';

  @override
  String get importEmptyFile => 'This file is empty';

  @override
  String importReadFailed(String error) {
    return 'Could not read the file: $error';
  }

  @override
  String get importConfirmTitle => 'Import now?';

  @override
  String importConfirmBody(String count, String dups) {
    return '$count entries will be appended; $dups duplicates skipped. Existing records are never deleted or overwritten.';
  }

  @override
  String get importAction => 'Import';

  @override
  String importDoneCount(String count) {
    return 'Imported $count entries';
  }

  @override
  String importSkipped(String count) {
    return ', skipped $count duplicates';
  }

  @override
  String importUnmatchedSuffix(String count) {
    return ', $count entries had an unmatched category and were saved as Uncategorized';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get importImportable => 'Importable';

  @override
  String get importSkippedDuplicates => 'Duplicates skipped';

  @override
  String get importParseFailed => 'Format errors';

  @override
  String get importUnmatched => 'Unmatched categories (will be Uncategorized)';

  @override
  String get importFailureDetails => 'Failures (first 5 shown)';

  @override
  String importRowIssue(String row, String reason) {
    return 'Row $row: $reason';
  }

  @override
  String get importNoNewRecords => 'No new records to import';

  @override
  String importConfirmCount(String count) {
    return 'Import $count entries';
  }

  @override
  String get importSuccess => 'Import finished — lists and overview refreshed';

  @override
  String get importTip =>
      'Tip: export the current data first, then import the old backup, to keep mistakes to a minimum.';

  @override
  String get importSelectedFile => 'Selected file';

  @override
  String get exportTitle => 'Export data';

  @override
  String exportCount(String count) {
    return '$count entries';
  }

  @override
  String get exportIntro =>
      'Export a CSV or JSON backup, save it to Downloads or share it. The file can be restored from Import data.';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportJson => 'Export JSON';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String importErrorUnsupported(String name) {
    return 'Unsupported file type: $name (only .csv / .json)';
  }

  @override
  String get importErrorJsonInvalid =>
      'The JSON could not be parsed; check that the file is complete';

  @override
  String get importErrorJsonNotArray =>
      'A JSON backup must be an array of entries ([...])';

  @override
  String get importErrorCsvEmpty => 'The CSV file is empty';

  @override
  String importErrorCsvMissing(String columns) {
    return 'Missing required columns: $columns (the header must contain type, amount, date)';
  }

  @override
  String get importErrorRowNotObject => 'not an object';

  @override
  String importErrorType(String value) {
    return 'Unrecognised type “$value”';
  }

  @override
  String importErrorAmount(String value) {
    return 'Invalid amount “$value”';
  }

  @override
  String importErrorDate(String value) {
    return 'Invalid date “$value” (expected yyyy-MM-dd)';
  }
}
