// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Spent_Tracker';

  @override
  String get curSgd => '新加坡元';

  @override
  String get curCny => '人民币';

  @override
  String get curMyr => '马来西亚林吉特';

  @override
  String get curJpy => '日元';

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '删除';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonMore => '更多…';

  @override
  String get commonCustom => '自定义';

  @override
  String get commonAmount => '金额';

  @override
  String get commonCurrency => '币种';

  @override
  String get commonCategory => '分类';

  @override
  String get commonNote => '备注';

  @override
  String get commonDate => '日期';

  @override
  String get commonType => '类型';

  @override
  String get commonUncategorized => '未分类';

  @override
  String get commonUnknown => '未知';

  @override
  String get commonNone => '暂无';

  @override
  String commonUnitEntries(String count) {
    return '$count 笔';
  }

  @override
  String get commonOverflowMenu => '更多操作';

  @override
  String get navOverview => '总览';

  @override
  String get navTransactions => '明细';

  @override
  String get navSettings => '设置';

  @override
  String get fabAdd => '记一笔';

  @override
  String get typeExpense => '支出';

  @override
  String get typeIncome => '收入';

  @override
  String get budgetTypeTotal => '总预算';

  @override
  String get budgetTypeCategory => '分类预算';

  @override
  String get freqWeekly => '每周';

  @override
  String get freqMonthly => '每月';

  @override
  String get freqYearly => '每年';

  @override
  String get weekdayMonth => '周一';

  @override
  String get weekdayTue => '周二';

  @override
  String get weekdayWed => '周三';

  @override
  String get weekdayThu => '周四';

  @override
  String get weekdayFri => '周五';

  @override
  String get weekdaySat => '周六';

  @override
  String get weekdaySun => '周日';

  @override
  String get weekdayCharMon => '一';

  @override
  String get weekdayCharTue => '二';

  @override
  String get weekdayCharWed => '三';

  @override
  String get weekdayCharThu => '四';

  @override
  String get weekdayCharFri => '五';

  @override
  String get weekdayCharSat => '六';

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
    return '$year 年';
  }

  @override
  String monthShort(String month) {
    return '$month 月';
  }

  @override
  String get overviewTitle => '总览';

  @override
  String get overviewAnnualTooltip => '年度报告';

  @override
  String get overviewTotalExpense => '总支出';

  @override
  String get overviewTotalIncome => '总收入';

  @override
  String get overviewBalance => '结余';

  @override
  String get overviewMonthlyBudget => '本月预算';

  @override
  String get overviewOverBudget => '已超出预算';

  @override
  String get overviewTrendTitle => '收支趋势';

  @override
  String overviewTodayDue(String count) {
    return '今日待记 $count 笔，点按预填录入';
  }

  @override
  String get overviewCategoryAnalysis => '分类分析';

  @override
  String get overviewNoExpenseInRange => '区间内暂无支出';

  @override
  String get overviewNoIncomeInRange => '区间内暂无收入';

  @override
  String get overviewRecent => '最近记录';

  @override
  String get overviewRecentEmpty => '区间内还没有记录，点右下角「+」记一笔吧';

  @override
  String get overviewViewAll => '查看全部';

  @override
  String get trendThisWeek => '本周';

  @override
  String get trendThisMonth => '本月';

  @override
  String get trendThreeMonths => '近3月';

  @override
  String get trendSixMonths => '近6月';

  @override
  String get trendTwelveMonths => '近12月';

  @override
  String get trendMoreRanges => '更多区间';

  @override
  String get rangeThisWeek => '本周';

  @override
  String get rangeThisMonth => '本月';

  @override
  String get rangeLastMonth => '上月';

  @override
  String get rangeLast7Days => '近7天';

  @override
  String get rangeCustom => '自定义';

  @override
  String get transactionsTitle => '交易明细';

  @override
  String get transactionsSearchHint => '搜索备注、分类或金额';

  @override
  String get transactionsAll => '全部';

  @override
  String get transactionsAllCategories => '全部分类';

  @override
  String get transactionsNoMatch => '没有找到匹配的账目';

  @override
  String get entryAddTitle => '记一笔';

  @override
  String get entryEditTitle => '编辑账目';

  @override
  String get entryAmountEmpty => '请输入金额';

  @override
  String get entryAmountInvalid => '金额格式无效，请输入数字（最多 7 位整数、2 位小数）';

  @override
  String get entryAmountTooLong => '整数最多 7 位、小数最多 2 位';

  @override
  String get entryAmountPositive => '金额必须大于 0';

  @override
  String get entrySelectCategory => '请选择分类';

  @override
  String get entryAddCategoryFirst => '请先在「设置 → 分类管理」中添加该类型分类';

  @override
  String get entrySaveChanges => '保存修改';

  @override
  String get entryConfirmEditTitle => '确认保存修改？';

  @override
  String get entryConfirmEditBody => '保存后将覆盖原有记录。';

  @override
  String get entryConfirmSave => '确认保存';

  @override
  String entryOverCategoryBudget(String amount) {
    return '本月该分类将超出预算（$amount）';
  }

  @override
  String entryOverTotalBudget(String amount) {
    return '本月总支出将超出预算（$amount）';
  }

  @override
  String get detailTitle => '账目详情';

  @override
  String get detailDeleteTitle => '删除这笔记录？';

  @override
  String detailDeleteBody(String type, String amount) {
    return '$type $amount，删除后不可恢复。';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsGroupGeneral => '通用';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsAppearanceSubtitle => '跟随系统 / 浅色 / 深色';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSubtitle => '跟随系统 / 中文 / English / 日本語';

  @override
  String get settingsGroupBookkeeping => '记账管理';

  @override
  String get settingsCategories => '分类管理';

  @override
  String get settingsCategoriesSubtitle => '预设 + 自定义分类';

  @override
  String get settingsBudgets => '预算设置';

  @override
  String get settingsBudgetsSubtitle => '月度总预算与分类预算';

  @override
  String get settingsRecurring => '周期记账';

  @override
  String get settingsRecurringSubtitle => '每周 / 每月 / 每年待记提醒';

  @override
  String get settingsGroupAnalysis => '分析';

  @override
  String get settingsAnnual => '年度报告';

  @override
  String get settingsAnnualSubtitle => '全年收支、月度柱状图与分类排行';

  @override
  String get settingsGroupData => '数据';

  @override
  String get settingsCurrency => '货币与汇率';

  @override
  String get settingsCurrencySubtitle => '切换基准币种，汇率可手动或联网更新';

  @override
  String get settingsExport => '数据导出';

  @override
  String get settingsExportSubtitle => '导出 CSV / JSON 备份';

  @override
  String get settingsImport => '数据导入';

  @override
  String get settingsImportSubtitle => '从 CSV / JSON 备份恢复（追加，自动跳过重复）';

  @override
  String get appearanceTitle => '外观';

  @override
  String get appearanceThemeSystem => '跟随系统';

  @override
  String get appearanceThemeSystemSub => '随手机/电脑的深浅色设置自动切换';

  @override
  String get appearanceThemeLight => '浅色';

  @override
  String get appearanceThemeLightSub => '始终使用浅色主题';

  @override
  String get appearanceThemeDark => '深色';

  @override
  String get appearanceThemeDarkSub => '始终使用深色主题';

  @override
  String get appearanceNote => '深色模式下的图表、金额颜色会自动适配背景亮度。';

  @override
  String get languageTitle => '语言';

  @override
  String get languageFollowSystem => '跟随系统';

  @override
  String get languageSystemSub => '随手机/电脑的系统语言自动切换';

  @override
  String get languageChinese => '中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageNote => '切换语言后界面与预设分类名称会立即更新；自定义分类名、备注等用户内容保持原文。';

  @override
  String get categoriesTitle => '分类管理';

  @override
  String get categoriesExpenseTab => '支出分类';

  @override
  String get categoriesIncomeTab => '收入分类';

  @override
  String get categoriesPresetLabel => '预设分类';

  @override
  String get categoriesAddExpense => '新增支出分类';

  @override
  String get categoriesAddIncome => '新增收入分类';

  @override
  String get categoriesNewTitle => '新增分类';

  @override
  String get categoriesEditTitle => '编辑分类';

  @override
  String categoriesDeleteTitle(String name) {
    return '删除分类「$name」？';
  }

  @override
  String get categoriesDeleteBody => '该分类下的历史账目将变为「未分类」，此操作不可恢复。';

  @override
  String get categoriesNameLabel => '分类名称';

  @override
  String get categoriesNameHint => '如：宠物、健身';

  @override
  String get categoriesNameEmpty => '请输入分类名称';

  @override
  String get categoriesIconLabel => '图标';

  @override
  String get categoriesCustomIconLabel => '自定义图标（可选）';

  @override
  String get categoriesCustomIconHint => '输入 1 个 emoji，如 🐹';

  @override
  String get categoriesCustomIconInvalid => '请输入 1 个 emoji（最多 2 个字符）';

  @override
  String get categoriesCurrent => '当前：';

  @override
  String categoriesBelongsTo(String type) {
    return '所属类型：$type';
  }

  @override
  String get budgetsTitle => '预算设置';

  @override
  String budgetsCurrentMonth(String month) {
    return '当前月：$month';
  }

  @override
  String budgetsIntro(String name) {
    return '金额默认按当前基准币种（$name）录入；每条预算也可以单独选择其他币种。当月未设置预算时，自动沿用最近一个设置过预算的月份；想要「不设限制」请删除该月预算。';
  }

  @override
  String get budgetsDefaultCurrency => '默认预算币种';

  @override
  String get budgetsCurrencyFollowBase => '跟随基准币种';

  @override
  String get budgetsCurrency => '预算币种';

  @override
  String budgetsApprox(String amount) {
    return '≈ $amount';
  }

  @override
  String get budgetsEmpty => '本月尚未设置预算\n点右下角「+」添加';

  @override
  String get budgetsAdd => '新增预算';

  @override
  String budgetsCategoryWith(String name) {
    return '分类预算 · $name';
  }

  @override
  String budgetsMonthLabel(String month) {
    return '所属月：$month';
  }

  @override
  String get budgetsDeleteTitle => '删除这笔预算？';

  @override
  String get budgetsDeleteBody => '删除后仅影响后续，不影响历史账目。';

  @override
  String get budgetsDialogTitle => '预算';

  @override
  String budgetsAmountLabel(String code) {
    return '金额（$code）';
  }

  @override
  String get budgetsInvalidAmount => '请输入有效金额';

  @override
  String get budgetsAddExpenseFirst => '请先添加支出分类';

  @override
  String get recurringTitle => '周期记账';

  @override
  String get recurringIntro =>
      '设置周期规则后，到期日在总览页出现「今日待记」提示条，点击预填录入并手动确认入账（不自动记账）。';

  @override
  String get recurringEmpty => '尚未设置周期规则\n点右下角「+」添加';

  @override
  String get recurringAdd => '新增规则';

  @override
  String get recurringActive => '启用中';

  @override
  String get recurringInactive => '已停用';

  @override
  String get recurringEditTooltip => '编辑';

  @override
  String get recurringDeleteTitle => '删除这条规则？';

  @override
  String get recurringDeleteBody => '删除后仅影响后续提醒，不影响已记账目。';

  @override
  String get recurringDialogTitle => '周期规则';

  @override
  String get recurringFrequencyLabel => '频率';

  @override
  String get recurringWeekdayLabel => '每周几';

  @override
  String recurringWeekdayOption(String char) {
    return '周$char';
  }

  @override
  String get recurringDayLabel => '几号（1-31）';

  @override
  String get recurringDayHelper => '超过当月天数的日期按月末处理';

  @override
  String get recurringMonthEndNote => '小月/平年按月末：如 31 号在 4 月记 30 日、2 月记 28 日';

  @override
  String recurringStartDate(String date) {
    return '开始日期：$date';
  }

  @override
  String recurringStartLabel(String date) {
    return '开始 $date';
  }

  @override
  String get recurringNoteOptional => '备注（可选）';

  @override
  String get recurringAddCategoryFirst => '请先添加该类型分类';

  @override
  String recurringDescWeekly(String weekday) {
    return '每周 $weekday';
  }

  @override
  String recurringDescMonthly(String day) {
    return '每月 $day 号';
  }

  @override
  String recurringDescYearly(String month, String day) {
    return '每年 $month 月 $day 号';
  }

  @override
  String get recurringNotCategorized => '未分类';

  @override
  String get annualTitle => '年度报告';

  @override
  String get annualYearlyExpense => '全年支出';

  @override
  String get annualYearlyIncome => '全年收入';

  @override
  String get annualBalance => '结余';

  @override
  String get annualRecordCount => '记账笔数';

  @override
  String get annualAvgExpense => '月均支出';

  @override
  String get annualPeakMonth => '支出最高月';

  @override
  String get annualNoRecords => '该年暂无记录';

  @override
  String annualChartTitle(String year) {
    return '月度收支（$year 年）';
  }

  @override
  String annualUnit(String symbol) {
    return '单位：$symbol';
  }

  @override
  String get annualCategoryRanking => '分类排行';

  @override
  String get annualNoExpense => '该年暂无支出';

  @override
  String get annualNoIncome => '该年暂无收入';

  @override
  String get annualPrevYear => '上一年';

  @override
  String get annualNextYear => '下一年';

  @override
  String get currencyTitle => '货币与汇率';

  @override
  String currencyIntro(String name, String code) {
    return '当前基准币种：$name（$code）。所有汇总（结余、趋势、预算、分类占比）按基准币种显示；明细与详情保留每笔账目自己的币种。汇率为「1 单位本币 = ? $code」，可手动修改或联网更新。';
  }

  @override
  String get currencyRefresh => '联网更新汇率';

  @override
  String get currencyRefreshFailed => '联网失败，已保留手动汇率';

  @override
  String currencyRefreshFailedWith(String error) {
    return '联网失败，已保留手动汇率：$error';
  }

  @override
  String currencyUpdated(String list) {
    return '已更新：$list';
  }

  @override
  String currencyMissing(String codes) {
    return '；未获取到 $codes，沿用本地汇率';
  }

  @override
  String get currencyBaseLabel => '基准币种';

  @override
  String get currencyBaseBadge => '基准';

  @override
  String currencyRateLine(String code, String rate, String base) {
    return '1 $code = $rate $base';
  }

  @override
  String get currencySetAsBase => '设为基准币种';

  @override
  String get currencyEditRate => '修改汇率';

  @override
  String currencyConfirmBaseTitle(String code) {
    return '把 $code 设为基准币种？';
  }

  @override
  String currencyConfirmBaseBody(String name) {
    return '汇总（结余、趋势、预算、分类占比）将改为按 $name 显示。\n历史账目与已录预算的存储金额不会改写，只是换算后展示；明细仍显示每笔账目自己的币种。';
  }

  @override
  String get currencySwitch => '切换';

  @override
  String currencyEditRateTitle(String code) {
    return '修改 $code 汇率';
  }

  @override
  String currencyRateInputLabel(String code, String base) {
    return '1 $code = ? $base';
  }

  @override
  String get currencyPositiveRate => '请输入正数汇率';

  @override
  String get importTitle => '数据导入';

  @override
  String get importRestore => '从备份文件恢复';

  @override
  String get importIntro =>
      '支持本应用导出的 CSV / JSON。导入为「追加」：不会删除或覆盖现有账目；同类型、同金额、同币种、同日期、同备注、同分类的记录会被视为重复并跳过。';

  @override
  String get importChooseFile => '选择 CSV / JSON 文件';

  @override
  String get importEmptyFile => '该文件为空';

  @override
  String importReadFailed(String error) {
    return '读取失败：$error';
  }

  @override
  String get importConfirmTitle => '确认导入？';

  @override
  String importConfirmBody(String count, String dups) {
    return '将追加 $count 笔账目；跳过重复 $dups 笔。导入不会删除或覆盖现有记录。';
  }

  @override
  String get importAction => '导入';

  @override
  String importDoneCount(String count) {
    return '已导入 $count 笔';
  }

  @override
  String importSkipped(String count) {
    return '，跳过重复 $count 笔';
  }

  @override
  String importUnmatchedSuffix(String count) {
    return '，$count 笔分类未匹配已记为未分类';
  }

  @override
  String importFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String get importImportable => '可导入';

  @override
  String get importSkippedDuplicates => '重复跳过';

  @override
  String get importParseFailed => '格式失败';

  @override
  String get importUnmatched => '分类未匹配（将记为未分类）';

  @override
  String get importFailureDetails => '失败明细（最多显示 5 条）';

  @override
  String importRowIssue(String row, String reason) {
    return '第 $row 行：$reason';
  }

  @override
  String get importNoNewRecords => '没有可导入的新记录';

  @override
  String importConfirmCount(String count) {
    return '确认导入 $count 笔';
  }

  @override
  String get importSuccess => '导入完成，明细与总览已刷新';

  @override
  String get importTip => '提示：先在「数据导出」里导出一份当前数据，再导入旧备份，可最大程度避免误操作带来的数据混乱。';

  @override
  String get importSelectedFile => '已选择文件';

  @override
  String get exportTitle => '数据导出';

  @override
  String exportCount(String count) {
    return '共 $count 笔账目';
  }

  @override
  String get exportIntro => '导出为 CSV 或 JSON 备份文件，可保存到「下载」或发送。导出的文件可在「数据导入」中恢复。';

  @override
  String get exportCsv => '导出 CSV';

  @override
  String get exportJson => '导出 JSON';

  @override
  String exportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String importErrorUnsupported(String name) {
    return '不支持的文件类型：$name（仅支持 .csv / .json）';
  }

  @override
  String get importErrorJsonInvalid => 'JSON 格式无法解析，请确认文件完整';

  @override
  String get importErrorJsonNotArray => 'JSON 备份应为账目数组（[...]）';

  @override
  String get importErrorCsvEmpty => 'CSV 文件为空';

  @override
  String importErrorCsvMissing(String columns) {
    return 'CSV 缺少必需列：$columns（表头需包含 type, amount, date）';
  }

  @override
  String get importErrorRowNotObject => '不是对象';

  @override
  String importErrorType(String value) {
    return '无法识别类型「$value」';
  }

  @override
  String importErrorAmount(String value) {
    return '金额无效「$value」';
  }

  @override
  String importErrorDate(String value) {
    return '日期无效「$value」（应为 yyyy-MM-dd）';
  }

  @override
  String get settingsPalette => '配色方案';

  @override
  String get settingsPaletteSubtitle => '10 套三色配色，默认黑白灰';

  @override
  String get paletteTitle => '配色方案';

  @override
  String get paletteNote => '切换后立即生效，并同步到深色模式；图表、按钮与选中态会跟随主色。';

  @override
  String get paletteDefault => '默认';

  @override
  String get paletteGray => '黑白灰';

  @override
  String get paletteDeepForest => '深林苔';

  @override
  String get paletteGlacier => '冰川雾';

  @override
  String get paletteNavyGold => '海军金';

  @override
  String get palettePeachSea => '蜜桃海';

  @override
  String get paletteElectricBerry => '电音莓';

  @override
  String get paletteTerracotta => '陶土现代';

  @override
  String get paletteForestNoir => '森林香';

  @override
  String get paletteSkyWood => '晴空木';

  @override
  String get paletteRoseStone => '柔粉岩';
}
