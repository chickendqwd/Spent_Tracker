// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Spent_Tracker';

  @override
  String get curSgd => 'シンガポールドル';

  @override
  String get curCny => '人民元';

  @override
  String get curMyr => 'マレーシアリンギット';

  @override
  String get curJpy => '日本円';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '削除';

  @override
  String get commonEdit => '編集';

  @override
  String get commonMore => 'その他…';

  @override
  String get commonCustom => 'カスタム';

  @override
  String get commonAmount => '金額';

  @override
  String get commonCurrency => '通貨';

  @override
  String get commonCategory => 'カテゴリ';

  @override
  String get commonNote => 'メモ';

  @override
  String get commonDate => '日付';

  @override
  String get commonType => '種別';

  @override
  String get commonUncategorized => '未分類';

  @override
  String get commonUnknown => '不明';

  @override
  String get commonNone => 'なし';

  @override
  String commonUnitEntries(String count) {
    return '$count 件';
  }

  @override
  String get commonOverflowMenu => 'その他の操作';

  @override
  String get navOverview => '概要';

  @override
  String get navTransactions => '明細';

  @override
  String get navSettings => '設定';

  @override
  String get fabAdd => '記録する';

  @override
  String get typeExpense => '支出';

  @override
  String get typeIncome => '収入';

  @override
  String get budgetTypeTotal => '総予算';

  @override
  String get budgetTypeCategory => 'カテゴリ予算';

  @override
  String get freqWeekly => '毎週';

  @override
  String get freqMonthly => '毎月';

  @override
  String get freqYearly => '毎年';

  @override
  String get weekdayMonth => '月曜日';

  @override
  String get weekdayTue => '火曜日';

  @override
  String get weekdayWed => '水曜日';

  @override
  String get weekdayThu => '木曜日';

  @override
  String get weekdayFri => '金曜日';

  @override
  String get weekdaySat => '土曜日';

  @override
  String get weekdaySun => '日曜日';

  @override
  String get weekdayCharMon => '月';

  @override
  String get weekdayCharTue => '火';

  @override
  String get weekdayCharWed => '水';

  @override
  String get weekdayCharThu => '木';

  @override
  String get weekdayCharFri => '金';

  @override
  String get weekdayCharSat => '土';

  @override
  String get weekdayCharSun => '日';

  @override
  String dateListHeader(String month, String day, String weekday) {
    return '$month月$day日 $weekday';
  }

  @override
  String monthTitle(String year, String month) {
    return '$year年$month月';
  }

  @override
  String yearLabel(String year) {
    return '$year年';
  }

  @override
  String monthShort(String month) {
    return '$month月';
  }

  @override
  String get overviewTitle => '概要';

  @override
  String get overviewAnnualTooltip => '年間レポート';

  @override
  String get overviewTotalExpense => '総支出';

  @override
  String get overviewTotalIncome => '総収入';

  @override
  String get overviewBalance => '残高';

  @override
  String get overviewMonthlyBudget => '今月の予算';

  @override
  String get overviewOverBudget => '予算超過';

  @override
  String get overviewTrendTitle => '収支トレンド';

  @override
  String overviewTodayDue(String count) {
    return '本日の記録待ち $count 件、タップで入力に反映';
  }

  @override
  String get overviewCategoryAnalysis => 'カテゴリ分析';

  @override
  String get overviewNoExpenseInRange => 'この期間に支出はありません';

  @override
  String get overviewNoIncomeInRange => 'この期間に収入はありません';

  @override
  String get overviewRecent => '最近の記録';

  @override
  String get overviewRecentEmpty => 'まだ記録がありません。右下の「+」から追加しましょう';

  @override
  String get overviewViewAll => 'すべて表示';

  @override
  String get trendThisWeek => '今週';

  @override
  String get trendThisMonth => '今月';

  @override
  String get trendThreeMonths => '直近3か月';

  @override
  String get trendSixMonths => '直近6か月';

  @override
  String get trendTwelveMonths => '直近12か月';

  @override
  String get trendMoreRanges => 'その他の期間';

  @override
  String get rangeThisWeek => '今週';

  @override
  String get rangeThisMonth => '今月';

  @override
  String get rangeLastMonth => '先月';

  @override
  String get rangeLast7Days => '直近7日';

  @override
  String get rangeCustom => 'カスタム';

  @override
  String get transactionsTitle => '取引明細';

  @override
  String get transactionsSearchHint => 'メモ・カテゴリ・金額を検索';

  @override
  String get transactionsAll => 'すべて';

  @override
  String get transactionsAllCategories => 'すべてのカテゴリ';

  @override
  String get transactionsNoMatch => '該当する記録がありません';

  @override
  String get entryAddTitle => '記録する';

  @override
  String get entryEditTitle => '記録を編集';

  @override
  String get entryAmountEmpty => '金額を入力してください';

  @override
  String get entryAmountInvalid => '金額の形式が正しくありません（整数7桁・小数2桁まで）';

  @override
  String get entryAmountTooLong => '整数は7桁、小数は2桁までです';

  @override
  String get entryAmountPositive => '金額は0より大きい必要があります';

  @override
  String get entrySelectCategory => 'カテゴリを選択してください';

  @override
  String get entryAddCategoryFirst => '先に「設定 → カテゴリ管理」でこの種別のカテゴリを追加してください';

  @override
  String get entrySaveChanges => '変更を保存';

  @override
  String get entryConfirmEditTitle => '変更を保存しますか？';

  @override
  String get entryConfirmEditBody => '既存の記録は上書きされます。';

  @override
  String get entryConfirmSave => '保存する';

  @override
  String entryOverCategoryBudget(String amount) {
    return '今月このカテゴリは予算を超えます（$amount）';
  }

  @override
  String entryOverTotalBudget(String amount) {
    return '今月の総支出が予算を超えます（$amount）';
  }

  @override
  String get detailTitle => '記録の詳細';

  @override
  String get detailDeleteTitle => 'この記録を削除しますか？';

  @override
  String detailDeleteBody(String type, String amount) {
    return '$type $amount。削除すると元に戻せません。';
  }

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsGroupGeneral => '一般';

  @override
  String get settingsAppearance => '外観';

  @override
  String get settingsAppearanceSubtitle => 'システム / ライト / ダーク';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsLanguageSubtitle => 'システム / 中文 / English / 日本語';

  @override
  String get settingsGroupBookkeeping => '記録管理';

  @override
  String get settingsCategories => 'カテゴリ管理';

  @override
  String get settingsCategoriesSubtitle => 'プリセット + カスタムカテゴリ';

  @override
  String get settingsBudgets => '予算設定';

  @override
  String get settingsBudgetsSubtitle => '月間総予算とカテゴリ予算';

  @override
  String get settingsRecurring => '定期記録';

  @override
  String get settingsRecurringSubtitle => '毎週 / 毎月 / 毎年の記録待ち通知';

  @override
  String get settingsGroupAnalysis => '分析';

  @override
  String get settingsAnnual => '年間レポート';

  @override
  String get settingsAnnualSubtitle => '年間収支・月別棒グラフ・カテゴリランキング';

  @override
  String get settingsGroupData => 'データ';

  @override
  String get settingsCurrency => '通貨と為替';

  @override
  String get settingsCurrencySubtitle => '基準通貨の切替、為替は手動またはオンライン更新';

  @override
  String get settingsExport => 'データ出力';

  @override
  String get settingsExportSubtitle => 'CSV / JSON バックアップを出力';

  @override
  String get settingsImport => 'データ取込';

  @override
  String get settingsImportSubtitle => 'CSV / JSON バックアップから復元（追記・重複は自動スキップ）';

  @override
  String get appearanceTitle => '外観';

  @override
  String get appearanceThemeSystem => 'システムに従う';

  @override
  String get appearanceThemeSystemSub => '端末のライト/ダーク設定に合わせて切り替わる';

  @override
  String get appearanceThemeLight => 'ライト';

  @override
  String get appearanceThemeLightSub => '常にライトテーマを使う';

  @override
  String get appearanceThemeDark => 'ダーク';

  @override
  String get appearanceThemeDarkSub => '常にダークテーマを使う';

  @override
  String get appearanceNote => 'ダークモードではグラフや金額の色が背景の明るさに合わせて調整されます。';

  @override
  String get languageTitle => '言語';

  @override
  String get languageFollowSystem => 'システムに従う';

  @override
  String get languageSystemSub => '端末のシステム言語に合わせて切り替わる';

  @override
  String get languageChinese => '中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageNote =>
      '言語を切り替えると画面とプリセットカテゴリ名がすぐに更新されます。カスタムカテゴリ名やメモなど、ユーザーの入力内容はそのまま残ります。';

  @override
  String get categoriesTitle => 'カテゴリ管理';

  @override
  String get categoriesExpenseTab => '支出カテゴリ';

  @override
  String get categoriesIncomeTab => '収入カテゴリ';

  @override
  String get categoriesPresetLabel => 'プリセット';

  @override
  String get categoriesAddExpense => '支出カテゴリを追加';

  @override
  String get categoriesAddIncome => '収入カテゴリを追加';

  @override
  String get categoriesNewTitle => 'カテゴリを追加';

  @override
  String get categoriesEditTitle => 'カテゴリを編集';

  @override
  String categoriesDeleteTitle(String name) {
    return '「$name」を削除しますか？';
  }

  @override
  String get categoriesDeleteBody => 'このカテゴリの過去の記録は「未分類」になります。元に戻せません。';

  @override
  String get categoriesNameLabel => 'カテゴリ名';

  @override
  String get categoriesNameHint => '例：ペット、ジム';

  @override
  String get categoriesNameEmpty => 'カテゴリ名を入力してください';

  @override
  String get categoriesIconLabel => 'アイコン';

  @override
  String get categoriesCustomIconLabel => 'カスタムアイコン（任意）';

  @override
  String get categoriesCustomIconHint => '絵文字を1つ、例 🐹';

  @override
  String get categoriesCustomIconInvalid => '絵文字を1つ入力してください（最大2文字）';

  @override
  String get categoriesCurrent => '現在：';

  @override
  String categoriesBelongsTo(String type) {
    return '種別：$type';
  }

  @override
  String get budgetsTitle => '予算設定';

  @override
  String budgetsCurrentMonth(String month) {
    return '今月：$month';
  }

  @override
  String budgetsIntro(String name) {
    return '金額は現在の基準通貨（$name）で入力・表示します。予算を設定していない月は、直近に予算を設定した月を引き継ぎます。「制限なし」にしたい場合はその月の予算を削除してください。';
  }

  @override
  String get budgetsEmpty => '今月の予算は未設定です\n右下の「+」から追加';

  @override
  String get budgetsAdd => '予算を追加';

  @override
  String budgetsCategoryWith(String name) {
    return 'カテゴリ予算 · $name';
  }

  @override
  String budgetsMonthLabel(String month) {
    return '対象月：$month';
  }

  @override
  String get budgetsDeleteTitle => 'この予算を削除しますか？';

  @override
  String get budgetsDeleteBody => '今後の判定にのみ影響し、過去の記録には影響しません。';

  @override
  String get budgetsDialogTitle => '予算';

  @override
  String budgetsAmountLabel(String code) {
    return '金額（$code）';
  }

  @override
  String get budgetsInvalidAmount => '有効な金額を入力してください';

  @override
  String get budgetsAddExpenseFirst => '先に支出カテゴリを追加してください';

  @override
  String get recurringTitle => '定期記録';

  @override
  String get recurringIntro =>
      '定期ルールを設定すると、期日に概要ページへ「本日の記録待ち」バーが表示されます。タップで入力に反映し、手動で確定します（自動記録はしません）。';

  @override
  String get recurringEmpty => '定期ルールはまだありません\n右下の「+」から追加';

  @override
  String get recurringAdd => 'ルールを追加';

  @override
  String get recurringActive => '有効';

  @override
  String get recurringInactive => '停止中';

  @override
  String get recurringEditTooltip => '編集';

  @override
  String get recurringDeleteTitle => 'このルールを削除しますか？';

  @override
  String get recurringDeleteBody => '今後の通知にのみ影響し、記録済みの内容には影響しません。';

  @override
  String get recurringDialogTitle => '定期ルール';

  @override
  String get recurringFrequencyLabel => '頻度';

  @override
  String get recurringWeekdayLabel => '曜日';

  @override
  String recurringWeekdayOption(String char) {
    return '$char';
  }

  @override
  String get recurringDayLabel => '日付（1-31）';

  @override
  String get recurringDayHelper => '月の日数を超える日付は月末として扱います';

  @override
  String get recurringMonthEndNote => '短い月は月末に調整：31日は4月なら30日、2月なら28日';

  @override
  String recurringStartDate(String date) {
    return '開始日：$date';
  }

  @override
  String recurringStartLabel(String date) {
    return '開始 $date';
  }

  @override
  String get recurringNoteOptional => 'メモ（任意）';

  @override
  String get recurringAddCategoryFirst => '先にこの種別のカテゴリを追加してください';

  @override
  String recurringDescWeekly(String weekday) {
    return '毎週 $weekday';
  }

  @override
  String recurringDescMonthly(String day) {
    return '毎月 $day 日';
  }

  @override
  String recurringDescYearly(String month, String day) {
    return '毎年 $month 月 $day 日';
  }

  @override
  String get recurringNotCategorized => '未分類';

  @override
  String get annualTitle => '年間レポート';

  @override
  String get annualYearlyExpense => '年間支出';

  @override
  String get annualYearlyIncome => '年間収入';

  @override
  String get annualBalance => '残高';

  @override
  String get annualRecordCount => '記録件数';

  @override
  String get annualAvgExpense => '月平均支出';

  @override
  String get annualPeakMonth => '支出最多月';

  @override
  String get annualNoRecords => 'この年の記録はありません';

  @override
  String annualChartTitle(String year) {
    return '月別収支（$year年）';
  }

  @override
  String annualUnit(String symbol) {
    return '単位：$symbol';
  }

  @override
  String get annualCategoryRanking => 'カテゴリランキング';

  @override
  String get annualNoExpense => 'この年の支出はありません';

  @override
  String get annualNoIncome => 'この年の収入はありません';

  @override
  String get annualPrevYear => '前年';

  @override
  String get annualNextYear => '翌年';

  @override
  String get currencyTitle => '通貨と為替';

  @override
  String currencyIntro(String name, String code) {
    return '現在の基準通貨：$name（$code）。すべての集計（残高・トレンド・予算・カテゴリ比率）は基準通貨で表示し、明細と詳細は各記録の通貨を保ちます。為替は「1 単位 = ? $code」で、手動編集またはオンライン更新ができます。';
  }

  @override
  String get currencyRefresh => '為替をオンライン更新';

  @override
  String get currencyRefreshFailed => '取得に失敗しました。手動の為替を保持します';

  @override
  String currencyRefreshFailedWith(String error) {
    return '取得に失敗しました。手動の為替を保持します：$error';
  }

  @override
  String currencyUpdated(String list) {
    return '更新済み：$list';
  }

  @override
  String currencyMissing(String codes) {
    return '；$codes は取得できず、ローカルの為替を使用';
  }

  @override
  String get currencyBaseLabel => '基準通貨';

  @override
  String get currencyBaseBadge => '基準';

  @override
  String currencyRateLine(String code, String rate, String base) {
    return '1 $code = $rate $base';
  }

  @override
  String get currencySetAsBase => '基準通貨に設定';

  @override
  String get currencyEditRate => '為替を修正';

  @override
  String currencyConfirmBaseTitle(String code) {
    return '$code を基準通貨にしますか？';
  }

  @override
  String currencyConfirmBaseBody(String name) {
    return '集計（残高・トレンド・予算・カテゴリ比率）は $name で表示されます。\n過去の記録や予算の保存金額は書き換えず、表示時に換算します。明細は各記録の通貨のままです。';
  }

  @override
  String get currencySwitch => '切り替え';

  @override
  String currencyEditRateTitle(String code) {
    return '$code の為替を修正';
  }

  @override
  String currencyRateInputLabel(String code, String base) {
    return '1 $code = ? $base';
  }

  @override
  String get currencyPositiveRate => '正の為替を入力してください';

  @override
  String get importTitle => 'データ取込';

  @override
  String get importRestore => 'バックアップから復元';

  @override
  String get importIntro =>
      '本アプリが出力した CSV / JSON に対応します。取込は「追記」です。既存の記録は削除・上書きしません。種別・金額・通貨・日付・メモ・カテゴリが一致する行は重複としてスキップします。';

  @override
  String get importChooseFile => 'CSV / JSON ファイルを選択';

  @override
  String get importEmptyFile => 'ファイルが空です';

  @override
  String importReadFailed(String error) {
    return '読み込みに失敗しました：$error';
  }

  @override
  String get importConfirmTitle => '取り込みますか？';

  @override
  String importConfirmBody(String count, String dups) {
    return '$count 件を追記し、重複 $dups 件をスキップします。既存の記録は削除・上書きしません。';
  }

  @override
  String get importAction => '取り込む';

  @override
  String importDoneCount(String count) {
    return '$count 件を取り込みました';
  }

  @override
  String importSkipped(String count) {
    return '、重複 $count 件をスキップ';
  }

  @override
  String importUnmatchedSuffix(String count) {
    return '、$count 件はカテゴリ未一致のため未分類として保存';
  }

  @override
  String importFailed(String error) {
    return '取込に失敗しました：$error';
  }

  @override
  String get importImportable => '取込可能';

  @override
  String get importSkippedDuplicates => '重複スキップ';

  @override
  String get importParseFailed => '形式エラー';

  @override
  String get importUnmatched => 'カテゴリ未一致（未分類として保存）';

  @override
  String get importFailureDetails => '失敗の詳細（最大5件）';

  @override
  String importRowIssue(String row, String reason) {
    return '$row 行目：$reason';
  }

  @override
  String get importNoNewRecords => '取り込む新しい記録がありません';

  @override
  String importConfirmCount(String count) {
    return '$count 件を取り込む';
  }

  @override
  String get importSuccess => '取込が完了しました。明細と概要を更新済み';

  @override
  String get importTip =>
      'ヒント：先に「データ出力」で現在のデータを出力してから古いバックアップを取り込むと、操作ミスによる混乱を最小限にできます。';

  @override
  String get importSelectedFile => '選択したファイル';

  @override
  String get exportTitle => 'データ出力';

  @override
  String exportCount(String count) {
    return '全 $count 件';
  }

  @override
  String get exportIntro =>
      'CSV または JSON のバックアップを出力し、「ダウンロード」へ保存または共有できます。出力したファイルは「データ取込」で復元できます。';

  @override
  String get exportCsv => 'CSV を出力';

  @override
  String get exportJson => 'JSON を出力';

  @override
  String exportFailed(String error) {
    return '出力に失敗しました：$error';
  }

  @override
  String importErrorUnsupported(String name) {
    return '対応していないファイル形式です：$name（.csv / .json のみ）';
  }

  @override
  String get importErrorJsonInvalid => 'JSON を解析できません。ファイルが完全か確認してください';

  @override
  String get importErrorJsonNotArray => 'JSON バックアップは記録の配列（[...]）である必要があります';

  @override
  String get importErrorCsvEmpty => 'CSV ファイルが空です';

  @override
  String importErrorCsvMissing(String columns) {
    return '必須列がありません：$columns（ヘッダーに type, amount, date が必要）';
  }

  @override
  String get importErrorRowNotObject => 'オブジェクトではありません';

  @override
  String importErrorType(String value) {
    return '種別「$value」を認識できません';
  }

  @override
  String importErrorAmount(String value) {
    return '金額が無効です「$value」';
  }

  @override
  String importErrorDate(String value) {
    return '日付が無効です「$value」（yyyy-MM-dd 形式）';
  }
}
