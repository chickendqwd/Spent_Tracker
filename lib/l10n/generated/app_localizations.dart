import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'Spent_Tracker'**
  String get appTitle;

  /// No description provided for @curSgd.
  ///
  /// In zh, this message translates to:
  /// **'新加坡元'**
  String get curSgd;

  /// No description provided for @curCny.
  ///
  /// In zh, this message translates to:
  /// **'人民币'**
  String get curCny;

  /// No description provided for @curMyr.
  ///
  /// In zh, this message translates to:
  /// **'马来西亚林吉特'**
  String get curMyr;

  /// No description provided for @curJpy.
  ///
  /// In zh, this message translates to:
  /// **'日元'**
  String get curJpy;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get commonEdit;

  /// No description provided for @commonMore.
  ///
  /// In zh, this message translates to:
  /// **'更多…'**
  String get commonMore;

  /// No description provided for @commonCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get commonCustom;

  /// No description provided for @commonAmount.
  ///
  /// In zh, this message translates to:
  /// **'金额'**
  String get commonAmount;

  /// No description provided for @commonCurrency.
  ///
  /// In zh, this message translates to:
  /// **'币种'**
  String get commonCurrency;

  /// No description provided for @commonCategory.
  ///
  /// In zh, this message translates to:
  /// **'分类'**
  String get commonCategory;

  /// No description provided for @commonNote.
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get commonNote;

  /// No description provided for @commonDate.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get commonDate;

  /// No description provided for @commonType.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get commonType;

  /// No description provided for @commonUncategorized.
  ///
  /// In zh, this message translates to:
  /// **'未分类'**
  String get commonUncategorized;

  /// No description provided for @commonUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get commonUnknown;

  /// No description provided for @commonNone.
  ///
  /// In zh, this message translates to:
  /// **'暂无'**
  String get commonNone;

  /// No description provided for @commonUnitEntries.
  ///
  /// In zh, this message translates to:
  /// **'{count} 笔'**
  String commonUnitEntries(String count);

  /// No description provided for @commonOverflowMenu.
  ///
  /// In zh, this message translates to:
  /// **'更多操作'**
  String get commonOverflowMenu;

  /// No description provided for @navOverview.
  ///
  /// In zh, this message translates to:
  /// **'总览'**
  String get navOverview;

  /// No description provided for @navTransactions.
  ///
  /// In zh, this message translates to:
  /// **'明细'**
  String get navTransactions;

  /// No description provided for @navSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get navSettings;

  /// No description provided for @fabAdd.
  ///
  /// In zh, this message translates to:
  /// **'记一笔'**
  String get fabAdd;

  /// No description provided for @typeExpense.
  ///
  /// In zh, this message translates to:
  /// **'支出'**
  String get typeExpense;

  /// No description provided for @typeIncome.
  ///
  /// In zh, this message translates to:
  /// **'收入'**
  String get typeIncome;

  /// No description provided for @budgetTypeTotal.
  ///
  /// In zh, this message translates to:
  /// **'总预算'**
  String get budgetTypeTotal;

  /// No description provided for @budgetTypeCategory.
  ///
  /// In zh, this message translates to:
  /// **'分类预算'**
  String get budgetTypeCategory;

  /// No description provided for @freqWeekly.
  ///
  /// In zh, this message translates to:
  /// **'每周'**
  String get freqWeekly;

  /// No description provided for @freqMonthly.
  ///
  /// In zh, this message translates to:
  /// **'每月'**
  String get freqMonthly;

  /// No description provided for @freqYearly.
  ///
  /// In zh, this message translates to:
  /// **'每年'**
  String get freqYearly;

  /// No description provided for @weekdayMonth.
  ///
  /// In zh, this message translates to:
  /// **'周一'**
  String get weekdayMonth;

  /// No description provided for @weekdayTue.
  ///
  /// In zh, this message translates to:
  /// **'周二'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In zh, this message translates to:
  /// **'周三'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In zh, this message translates to:
  /// **'周四'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In zh, this message translates to:
  /// **'周五'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In zh, this message translates to:
  /// **'周六'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In zh, this message translates to:
  /// **'周日'**
  String get weekdaySun;

  /// No description provided for @weekdayCharMon.
  ///
  /// In zh, this message translates to:
  /// **'一'**
  String get weekdayCharMon;

  /// No description provided for @weekdayCharTue.
  ///
  /// In zh, this message translates to:
  /// **'二'**
  String get weekdayCharTue;

  /// No description provided for @weekdayCharWed.
  ///
  /// In zh, this message translates to:
  /// **'三'**
  String get weekdayCharWed;

  /// No description provided for @weekdayCharThu.
  ///
  /// In zh, this message translates to:
  /// **'四'**
  String get weekdayCharThu;

  /// No description provided for @weekdayCharFri.
  ///
  /// In zh, this message translates to:
  /// **'五'**
  String get weekdayCharFri;

  /// No description provided for @weekdayCharSat.
  ///
  /// In zh, this message translates to:
  /// **'六'**
  String get weekdayCharSat;

  /// No description provided for @weekdayCharSun.
  ///
  /// In zh, this message translates to:
  /// **'日'**
  String get weekdayCharSun;

  /// No description provided for @dateListHeader.
  ///
  /// In zh, this message translates to:
  /// **'{month}月{day}日 {weekday}'**
  String dateListHeader(String month, String day, String weekday);

  /// No description provided for @monthTitle.
  ///
  /// In zh, this message translates to:
  /// **'{year}年{month}月'**
  String monthTitle(String year, String month);

  /// No description provided for @yearLabel.
  ///
  /// In zh, this message translates to:
  /// **'{year} 年'**
  String yearLabel(String year);

  /// No description provided for @monthShort.
  ///
  /// In zh, this message translates to:
  /// **'{month} 月'**
  String monthShort(String month);

  /// No description provided for @overviewTitle.
  ///
  /// In zh, this message translates to:
  /// **'总览'**
  String get overviewTitle;

  /// No description provided for @overviewAnnualTooltip.
  ///
  /// In zh, this message translates to:
  /// **'年度报告'**
  String get overviewAnnualTooltip;

  /// No description provided for @overviewTotalExpense.
  ///
  /// In zh, this message translates to:
  /// **'总支出'**
  String get overviewTotalExpense;

  /// No description provided for @overviewTotalIncome.
  ///
  /// In zh, this message translates to:
  /// **'总收入'**
  String get overviewTotalIncome;

  /// No description provided for @overviewBalance.
  ///
  /// In zh, this message translates to:
  /// **'结余'**
  String get overviewBalance;

  /// No description provided for @overviewMonthlyBudget.
  ///
  /// In zh, this message translates to:
  /// **'本月预算'**
  String get overviewMonthlyBudget;

  /// No description provided for @overviewOverBudget.
  ///
  /// In zh, this message translates to:
  /// **'已超出预算'**
  String get overviewOverBudget;

  /// No description provided for @overviewTrendTitle.
  ///
  /// In zh, this message translates to:
  /// **'收支趋势'**
  String get overviewTrendTitle;

  /// No description provided for @overviewTodayDue.
  ///
  /// In zh, this message translates to:
  /// **'今日待记 {count} 笔，点按预填录入'**
  String overviewTodayDue(String count);

  /// No description provided for @overviewCategoryAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'分类分析'**
  String get overviewCategoryAnalysis;

  /// No description provided for @overviewNoExpenseInRange.
  ///
  /// In zh, this message translates to:
  /// **'区间内暂无支出'**
  String get overviewNoExpenseInRange;

  /// No description provided for @overviewNoIncomeInRange.
  ///
  /// In zh, this message translates to:
  /// **'区间内暂无收入'**
  String get overviewNoIncomeInRange;

  /// No description provided for @overviewRecent.
  ///
  /// In zh, this message translates to:
  /// **'最近记录'**
  String get overviewRecent;

  /// No description provided for @overviewRecentEmpty.
  ///
  /// In zh, this message translates to:
  /// **'区间内还没有记录，点右下角「+」记一笔吧'**
  String get overviewRecentEmpty;

  /// No description provided for @overviewViewAll.
  ///
  /// In zh, this message translates to:
  /// **'查看全部'**
  String get overviewViewAll;

  /// No description provided for @trendThisWeek.
  ///
  /// In zh, this message translates to:
  /// **'本周'**
  String get trendThisWeek;

  /// No description provided for @trendThisMonth.
  ///
  /// In zh, this message translates to:
  /// **'本月'**
  String get trendThisMonth;

  /// No description provided for @trendThreeMonths.
  ///
  /// In zh, this message translates to:
  /// **'近3月'**
  String get trendThreeMonths;

  /// No description provided for @trendSixMonths.
  ///
  /// In zh, this message translates to:
  /// **'近6月'**
  String get trendSixMonths;

  /// No description provided for @trendTwelveMonths.
  ///
  /// In zh, this message translates to:
  /// **'近12月'**
  String get trendTwelveMonths;

  /// No description provided for @trendMoreRanges.
  ///
  /// In zh, this message translates to:
  /// **'更多区间'**
  String get trendMoreRanges;

  /// No description provided for @rangeThisWeek.
  ///
  /// In zh, this message translates to:
  /// **'本周'**
  String get rangeThisWeek;

  /// No description provided for @rangeThisMonth.
  ///
  /// In zh, this message translates to:
  /// **'本月'**
  String get rangeThisMonth;

  /// No description provided for @rangeLastMonth.
  ///
  /// In zh, this message translates to:
  /// **'上月'**
  String get rangeLastMonth;

  /// No description provided for @rangeLast7Days.
  ///
  /// In zh, this message translates to:
  /// **'近7天'**
  String get rangeLast7Days;

  /// No description provided for @rangeCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get rangeCustom;

  /// No description provided for @transactionsTitle.
  ///
  /// In zh, this message translates to:
  /// **'交易明细'**
  String get transactionsTitle;

  /// No description provided for @transactionsSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索备注、分类或金额'**
  String get transactionsSearchHint;

  /// No description provided for @transactionsAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get transactionsAll;

  /// No description provided for @transactionsAllCategories.
  ///
  /// In zh, this message translates to:
  /// **'全部分类'**
  String get transactionsAllCategories;

  /// No description provided for @transactionsNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有找到匹配的账目'**
  String get transactionsNoMatch;

  /// No description provided for @entryAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'记一笔'**
  String get entryAddTitle;

  /// No description provided for @entryEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑账目'**
  String get entryEditTitle;

  /// No description provided for @entryAmountEmpty.
  ///
  /// In zh, this message translates to:
  /// **'请输入金额'**
  String get entryAmountEmpty;

  /// No description provided for @entryAmountInvalid.
  ///
  /// In zh, this message translates to:
  /// **'金额格式无效，请输入数字（最多 7 位整数、2 位小数）'**
  String get entryAmountInvalid;

  /// No description provided for @entryAmountTooLong.
  ///
  /// In zh, this message translates to:
  /// **'整数最多 7 位、小数最多 2 位'**
  String get entryAmountTooLong;

  /// No description provided for @entryAmountPositive.
  ///
  /// In zh, this message translates to:
  /// **'金额必须大于 0'**
  String get entryAmountPositive;

  /// No description provided for @entrySelectCategory.
  ///
  /// In zh, this message translates to:
  /// **'请选择分类'**
  String get entrySelectCategory;

  /// No description provided for @entryAddCategoryFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先在「设置 → 分类管理」中添加该类型分类'**
  String get entryAddCategoryFirst;

  /// No description provided for @entrySaveChanges.
  ///
  /// In zh, this message translates to:
  /// **'保存修改'**
  String get entrySaveChanges;

  /// No description provided for @entryConfirmEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认保存修改？'**
  String get entryConfirmEditTitle;

  /// No description provided for @entryConfirmEditBody.
  ///
  /// In zh, this message translates to:
  /// **'保存后将覆盖原有记录。'**
  String get entryConfirmEditBody;

  /// No description provided for @entryConfirmSave.
  ///
  /// In zh, this message translates to:
  /// **'确认保存'**
  String get entryConfirmSave;

  /// No description provided for @entryOverCategoryBudget.
  ///
  /// In zh, this message translates to:
  /// **'本月该分类将超出预算（{amount}）'**
  String entryOverCategoryBudget(String amount);

  /// No description provided for @entryOverTotalBudget.
  ///
  /// In zh, this message translates to:
  /// **'本月总支出将超出预算（{amount}）'**
  String entryOverTotalBudget(String amount);

  /// No description provided for @detailTitle.
  ///
  /// In zh, this message translates to:
  /// **'账目详情'**
  String get detailTitle;

  /// No description provided for @detailDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除这笔记录？'**
  String get detailDeleteTitle;

  /// No description provided for @detailDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'{type} {amount}，删除后不可恢复。'**
  String detailDeleteBody(String type, String amount);

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsGroupGeneral.
  ///
  /// In zh, this message translates to:
  /// **'通用'**
  String get settingsGroupGeneral;

  /// No description provided for @settingsAppearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统 / 浅色 / 深色'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统 / 中文 / English / 日本語'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsGroupBookkeeping.
  ///
  /// In zh, this message translates to:
  /// **'记账管理'**
  String get settingsGroupBookkeeping;

  /// No description provided for @settingsCategories.
  ///
  /// In zh, this message translates to:
  /// **'分类管理'**
  String get settingsCategories;

  /// No description provided for @settingsCategoriesSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'预设 + 自定义分类'**
  String get settingsCategoriesSubtitle;

  /// No description provided for @settingsBudgets.
  ///
  /// In zh, this message translates to:
  /// **'预算设置'**
  String get settingsBudgets;

  /// No description provided for @settingsBudgetsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'月度总预算与分类预算'**
  String get settingsBudgetsSubtitle;

  /// No description provided for @settingsRecurring.
  ///
  /// In zh, this message translates to:
  /// **'周期记账'**
  String get settingsRecurring;

  /// No description provided for @settingsRecurringSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'每周 / 每月 / 每年待记提醒'**
  String get settingsRecurringSubtitle;

  /// No description provided for @settingsGroupAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'分析'**
  String get settingsGroupAnalysis;

  /// No description provided for @settingsAnnual.
  ///
  /// In zh, this message translates to:
  /// **'年度报告'**
  String get settingsAnnual;

  /// No description provided for @settingsAnnualSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'全年收支、月度柱状图与分类排行'**
  String get settingsAnnualSubtitle;

  /// No description provided for @settingsGroupData.
  ///
  /// In zh, this message translates to:
  /// **'数据'**
  String get settingsGroupData;

  /// No description provided for @settingsCurrency.
  ///
  /// In zh, this message translates to:
  /// **'货币与汇率'**
  String get settingsCurrency;

  /// No description provided for @settingsCurrencySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'切换基准币种，汇率可手动或联网更新'**
  String get settingsCurrencySubtitle;

  /// No description provided for @settingsExport.
  ///
  /// In zh, this message translates to:
  /// **'数据导出'**
  String get settingsExport;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'导出 CSV / JSON 备份'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsImport.
  ///
  /// In zh, this message translates to:
  /// **'数据导入'**
  String get settingsImport;

  /// No description provided for @settingsImportSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'从 CSV / JSON 备份恢复（追加，自动跳过重复）'**
  String get settingsImportSubtitle;

  /// No description provided for @appearanceTitle.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get appearanceTitle;

  /// No description provided for @appearanceThemeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get appearanceThemeSystem;

  /// No description provided for @appearanceThemeSystemSub.
  ///
  /// In zh, this message translates to:
  /// **'随手机/电脑的深浅色设置自动切换'**
  String get appearanceThemeSystemSub;

  /// No description provided for @appearanceThemeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get appearanceThemeLight;

  /// No description provided for @appearanceThemeLightSub.
  ///
  /// In zh, this message translates to:
  /// **'始终使用浅色主题'**
  String get appearanceThemeLightSub;

  /// No description provided for @appearanceThemeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get appearanceThemeDark;

  /// No description provided for @appearanceThemeDarkSub.
  ///
  /// In zh, this message translates to:
  /// **'始终使用深色主题'**
  String get appearanceThemeDarkSub;

  /// No description provided for @appearanceNote.
  ///
  /// In zh, this message translates to:
  /// **'深色模式下的图表、金额颜色会自动适配背景亮度。'**
  String get appearanceNote;

  /// No description provided for @languageTitle.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get languageTitle;

  /// No description provided for @languageFollowSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get languageFollowSystem;

  /// No description provided for @languageSystemSub.
  ///
  /// In zh, this message translates to:
  /// **'随手机/电脑的系统语言自动切换'**
  String get languageSystemSub;

  /// No description provided for @languageChinese.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageJapanese.
  ///
  /// In zh, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @languageNote.
  ///
  /// In zh, this message translates to:
  /// **'切换语言后界面与预设分类名称会立即更新；自定义分类名、备注等用户内容保持原文。'**
  String get languageNote;

  /// No description provided for @categoriesTitle.
  ///
  /// In zh, this message translates to:
  /// **'分类管理'**
  String get categoriesTitle;

  /// No description provided for @categoriesExpenseTab.
  ///
  /// In zh, this message translates to:
  /// **'支出分类'**
  String get categoriesExpenseTab;

  /// No description provided for @categoriesIncomeTab.
  ///
  /// In zh, this message translates to:
  /// **'收入分类'**
  String get categoriesIncomeTab;

  /// No description provided for @categoriesPresetLabel.
  ///
  /// In zh, this message translates to:
  /// **'预设分类'**
  String get categoriesPresetLabel;

  /// No description provided for @categoriesAddExpense.
  ///
  /// In zh, this message translates to:
  /// **'新增支出分类'**
  String get categoriesAddExpense;

  /// No description provided for @categoriesAddIncome.
  ///
  /// In zh, this message translates to:
  /// **'新增收入分类'**
  String get categoriesAddIncome;

  /// No description provided for @categoriesNewTitle.
  ///
  /// In zh, this message translates to:
  /// **'新增分类'**
  String get categoriesNewTitle;

  /// No description provided for @categoriesEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑分类'**
  String get categoriesEditTitle;

  /// No description provided for @categoriesDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除分类「{name}」？'**
  String categoriesDeleteTitle(String name);

  /// No description provided for @categoriesDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'该分类下的历史账目将变为「未分类」，此操作不可恢复。'**
  String get categoriesDeleteBody;

  /// No description provided for @categoriesNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'分类名称'**
  String get categoriesNameLabel;

  /// No description provided for @categoriesNameHint.
  ///
  /// In zh, this message translates to:
  /// **'如：宠物、健身'**
  String get categoriesNameHint;

  /// No description provided for @categoriesNameEmpty.
  ///
  /// In zh, this message translates to:
  /// **'请输入分类名称'**
  String get categoriesNameEmpty;

  /// No description provided for @categoriesIconLabel.
  ///
  /// In zh, this message translates to:
  /// **'图标'**
  String get categoriesIconLabel;

  /// No description provided for @categoriesCustomIconLabel.
  ///
  /// In zh, this message translates to:
  /// **'自定义图标（可选）'**
  String get categoriesCustomIconLabel;

  /// No description provided for @categoriesCustomIconHint.
  ///
  /// In zh, this message translates to:
  /// **'输入 1 个 emoji，如 🐹'**
  String get categoriesCustomIconHint;

  /// No description provided for @categoriesCustomIconInvalid.
  ///
  /// In zh, this message translates to:
  /// **'请输入 1 个 emoji（最多 2 个字符）'**
  String get categoriesCustomIconInvalid;

  /// No description provided for @categoriesCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前：'**
  String get categoriesCurrent;

  /// No description provided for @categoriesBelongsTo.
  ///
  /// In zh, this message translates to:
  /// **'所属类型：{type}'**
  String categoriesBelongsTo(String type);

  /// No description provided for @budgetsTitle.
  ///
  /// In zh, this message translates to:
  /// **'预算设置'**
  String get budgetsTitle;

  /// No description provided for @budgetsCurrentMonth.
  ///
  /// In zh, this message translates to:
  /// **'当前月：{month}'**
  String budgetsCurrentMonth(String month);

  /// No description provided for @budgetsIntro.
  ///
  /// In zh, this message translates to:
  /// **'金额按当前基准币种（{name}）录入与显示。当月未设置预算时，自动沿用最近一个设置过预算的月份；想要「不设限制」请删除该月预算。'**
  String budgetsIntro(String name);

  /// No description provided for @budgetsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'本月尚未设置预算\n点右下角「+」添加'**
  String get budgetsEmpty;

  /// No description provided for @budgetsAdd.
  ///
  /// In zh, this message translates to:
  /// **'新增预算'**
  String get budgetsAdd;

  /// No description provided for @budgetsCategoryWith.
  ///
  /// In zh, this message translates to:
  /// **'分类预算 · {name}'**
  String budgetsCategoryWith(String name);

  /// No description provided for @budgetsMonthLabel.
  ///
  /// In zh, this message translates to:
  /// **'所属月：{month}'**
  String budgetsMonthLabel(String month);

  /// No description provided for @budgetsDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除这笔预算？'**
  String get budgetsDeleteTitle;

  /// No description provided for @budgetsDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'删除后仅影响后续，不影响历史账目。'**
  String get budgetsDeleteBody;

  /// No description provided for @budgetsDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'预算'**
  String get budgetsDialogTitle;

  /// No description provided for @budgetsAmountLabel.
  ///
  /// In zh, this message translates to:
  /// **'金额（{code}）'**
  String budgetsAmountLabel(String code);

  /// No description provided for @budgetsInvalidAmount.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效金额'**
  String get budgetsInvalidAmount;

  /// No description provided for @budgetsAddExpenseFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先添加支出分类'**
  String get budgetsAddExpenseFirst;

  /// No description provided for @recurringTitle.
  ///
  /// In zh, this message translates to:
  /// **'周期记账'**
  String get recurringTitle;

  /// No description provided for @recurringIntro.
  ///
  /// In zh, this message translates to:
  /// **'设置周期规则后，到期日在总览页出现「今日待记」提示条，点击预填录入并手动确认入账（不自动记账）。'**
  String get recurringIntro;

  /// No description provided for @recurringEmpty.
  ///
  /// In zh, this message translates to:
  /// **'尚未设置周期规则\n点右下角「+」添加'**
  String get recurringEmpty;

  /// No description provided for @recurringAdd.
  ///
  /// In zh, this message translates to:
  /// **'新增规则'**
  String get recurringAdd;

  /// No description provided for @recurringActive.
  ///
  /// In zh, this message translates to:
  /// **'启用中'**
  String get recurringActive;

  /// No description provided for @recurringInactive.
  ///
  /// In zh, this message translates to:
  /// **'已停用'**
  String get recurringInactive;

  /// No description provided for @recurringEditTooltip.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get recurringEditTooltip;

  /// No description provided for @recurringDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除这条规则？'**
  String get recurringDeleteTitle;

  /// No description provided for @recurringDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'删除后仅影响后续提醒，不影响已记账目。'**
  String get recurringDeleteBody;

  /// No description provided for @recurringDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'周期规则'**
  String get recurringDialogTitle;

  /// No description provided for @recurringFrequencyLabel.
  ///
  /// In zh, this message translates to:
  /// **'频率'**
  String get recurringFrequencyLabel;

  /// No description provided for @recurringWeekdayLabel.
  ///
  /// In zh, this message translates to:
  /// **'每周几'**
  String get recurringWeekdayLabel;

  /// No description provided for @recurringWeekdayOption.
  ///
  /// In zh, this message translates to:
  /// **'周{char}'**
  String recurringWeekdayOption(String char);

  /// No description provided for @recurringDayLabel.
  ///
  /// In zh, this message translates to:
  /// **'几号（1-31）'**
  String get recurringDayLabel;

  /// No description provided for @recurringDayHelper.
  ///
  /// In zh, this message translates to:
  /// **'超过当月天数的日期按月末处理'**
  String get recurringDayHelper;

  /// No description provided for @recurringMonthEndNote.
  ///
  /// In zh, this message translates to:
  /// **'小月/平年按月末：如 31 号在 4 月记 30 日、2 月记 28 日'**
  String get recurringMonthEndNote;

  /// No description provided for @recurringStartDate.
  ///
  /// In zh, this message translates to:
  /// **'开始日期：{date}'**
  String recurringStartDate(String date);

  /// No description provided for @recurringStartLabel.
  ///
  /// In zh, this message translates to:
  /// **'开始 {date}'**
  String recurringStartLabel(String date);

  /// No description provided for @recurringNoteOptional.
  ///
  /// In zh, this message translates to:
  /// **'备注（可选）'**
  String get recurringNoteOptional;

  /// No description provided for @recurringAddCategoryFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先添加该类型分类'**
  String get recurringAddCategoryFirst;

  /// No description provided for @recurringDescWeekly.
  ///
  /// In zh, this message translates to:
  /// **'每周 {weekday}'**
  String recurringDescWeekly(String weekday);

  /// No description provided for @recurringDescMonthly.
  ///
  /// In zh, this message translates to:
  /// **'每月 {day} 号'**
  String recurringDescMonthly(String day);

  /// No description provided for @recurringDescYearly.
  ///
  /// In zh, this message translates to:
  /// **'每年 {month} 月 {day} 号'**
  String recurringDescYearly(String month, String day);

  /// No description provided for @recurringNotCategorized.
  ///
  /// In zh, this message translates to:
  /// **'未分类'**
  String get recurringNotCategorized;

  /// No description provided for @annualTitle.
  ///
  /// In zh, this message translates to:
  /// **'年度报告'**
  String get annualTitle;

  /// No description provided for @annualYearlyExpense.
  ///
  /// In zh, this message translates to:
  /// **'全年支出'**
  String get annualYearlyExpense;

  /// No description provided for @annualYearlyIncome.
  ///
  /// In zh, this message translates to:
  /// **'全年收入'**
  String get annualYearlyIncome;

  /// No description provided for @annualBalance.
  ///
  /// In zh, this message translates to:
  /// **'结余'**
  String get annualBalance;

  /// No description provided for @annualRecordCount.
  ///
  /// In zh, this message translates to:
  /// **'记账笔数'**
  String get annualRecordCount;

  /// No description provided for @annualAvgExpense.
  ///
  /// In zh, this message translates to:
  /// **'月均支出'**
  String get annualAvgExpense;

  /// No description provided for @annualPeakMonth.
  ///
  /// In zh, this message translates to:
  /// **'支出最高月'**
  String get annualPeakMonth;

  /// No description provided for @annualNoRecords.
  ///
  /// In zh, this message translates to:
  /// **'该年暂无记录'**
  String get annualNoRecords;

  /// No description provided for @annualChartTitle.
  ///
  /// In zh, this message translates to:
  /// **'月度收支（{year} 年）'**
  String annualChartTitle(String year);

  /// No description provided for @annualUnit.
  ///
  /// In zh, this message translates to:
  /// **'单位：{symbol}'**
  String annualUnit(String symbol);

  /// No description provided for @annualCategoryRanking.
  ///
  /// In zh, this message translates to:
  /// **'分类排行'**
  String get annualCategoryRanking;

  /// No description provided for @annualNoExpense.
  ///
  /// In zh, this message translates to:
  /// **'该年暂无支出'**
  String get annualNoExpense;

  /// No description provided for @annualNoIncome.
  ///
  /// In zh, this message translates to:
  /// **'该年暂无收入'**
  String get annualNoIncome;

  /// No description provided for @annualPrevYear.
  ///
  /// In zh, this message translates to:
  /// **'上一年'**
  String get annualPrevYear;

  /// No description provided for @annualNextYear.
  ///
  /// In zh, this message translates to:
  /// **'下一年'**
  String get annualNextYear;

  /// No description provided for @currencyTitle.
  ///
  /// In zh, this message translates to:
  /// **'货币与汇率'**
  String get currencyTitle;

  /// No description provided for @currencyIntro.
  ///
  /// In zh, this message translates to:
  /// **'当前基准币种：{name}（{code}）。所有汇总（结余、趋势、预算、分类占比）按基准币种显示；明细与详情保留每笔账目自己的币种。汇率为「1 单位本币 = ? {code}」，可手动修改或联网更新。'**
  String currencyIntro(String name, String code);

  /// No description provided for @currencyRefresh.
  ///
  /// In zh, this message translates to:
  /// **'联网更新汇率'**
  String get currencyRefresh;

  /// No description provided for @currencyRefreshFailed.
  ///
  /// In zh, this message translates to:
  /// **'联网失败，已保留手动汇率'**
  String get currencyRefreshFailed;

  /// No description provided for @currencyRefreshFailedWith.
  ///
  /// In zh, this message translates to:
  /// **'联网失败，已保留手动汇率：{error}'**
  String currencyRefreshFailedWith(String error);

  /// No description provided for @currencyUpdated.
  ///
  /// In zh, this message translates to:
  /// **'已更新：{list}'**
  String currencyUpdated(String list);

  /// No description provided for @currencyMissing.
  ///
  /// In zh, this message translates to:
  /// **'；未获取到 {codes}，沿用本地汇率'**
  String currencyMissing(String codes);

  /// No description provided for @currencyBaseLabel.
  ///
  /// In zh, this message translates to:
  /// **'基准币种'**
  String get currencyBaseLabel;

  /// No description provided for @currencyBaseBadge.
  ///
  /// In zh, this message translates to:
  /// **'基准'**
  String get currencyBaseBadge;

  /// No description provided for @currencyRateLine.
  ///
  /// In zh, this message translates to:
  /// **'1 {code} = {rate} {base}'**
  String currencyRateLine(String code, String rate, String base);

  /// No description provided for @currencySetAsBase.
  ///
  /// In zh, this message translates to:
  /// **'设为基准币种'**
  String get currencySetAsBase;

  /// No description provided for @currencyEditRate.
  ///
  /// In zh, this message translates to:
  /// **'修改汇率'**
  String get currencyEditRate;

  /// No description provided for @currencyConfirmBaseTitle.
  ///
  /// In zh, this message translates to:
  /// **'把 {code} 设为基准币种？'**
  String currencyConfirmBaseTitle(String code);

  /// No description provided for @currencyConfirmBaseBody.
  ///
  /// In zh, this message translates to:
  /// **'汇总（结余、趋势、预算、分类占比）将改为按 {name} 显示。\n历史账目与已录预算的存储金额不会改写，只是换算后展示；明细仍显示每笔账目自己的币种。'**
  String currencyConfirmBaseBody(String name);

  /// No description provided for @currencySwitch.
  ///
  /// In zh, this message translates to:
  /// **'切换'**
  String get currencySwitch;

  /// No description provided for @currencyEditRateTitle.
  ///
  /// In zh, this message translates to:
  /// **'修改 {code} 汇率'**
  String currencyEditRateTitle(String code);

  /// No description provided for @currencyRateInputLabel.
  ///
  /// In zh, this message translates to:
  /// **'1 {code} = ? {base}'**
  String currencyRateInputLabel(String code, String base);

  /// No description provided for @currencyPositiveRate.
  ///
  /// In zh, this message translates to:
  /// **'请输入正数汇率'**
  String get currencyPositiveRate;

  /// No description provided for @importTitle.
  ///
  /// In zh, this message translates to:
  /// **'数据导入'**
  String get importTitle;

  /// No description provided for @importRestore.
  ///
  /// In zh, this message translates to:
  /// **'从备份文件恢复'**
  String get importRestore;

  /// No description provided for @importIntro.
  ///
  /// In zh, this message translates to:
  /// **'支持本应用导出的 CSV / JSON。导入为「追加」：不会删除或覆盖现有账目；同类型、同金额、同币种、同日期、同备注、同分类的记录会被视为重复并跳过。'**
  String get importIntro;

  /// No description provided for @importChooseFile.
  ///
  /// In zh, this message translates to:
  /// **'选择 CSV / JSON 文件'**
  String get importChooseFile;

  /// No description provided for @importEmptyFile.
  ///
  /// In zh, this message translates to:
  /// **'该文件为空'**
  String get importEmptyFile;

  /// No description provided for @importReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'读取失败：{error}'**
  String importReadFailed(String error);

  /// No description provided for @importConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认导入？'**
  String get importConfirmTitle;

  /// No description provided for @importConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'将追加 {count} 笔账目；跳过重复 {dups} 笔。导入不会删除或覆盖现有记录。'**
  String importConfirmBody(String count, String dups);

  /// No description provided for @importAction.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get importAction;

  /// No description provided for @importDoneCount.
  ///
  /// In zh, this message translates to:
  /// **'已导入 {count} 笔'**
  String importDoneCount(String count);

  /// No description provided for @importSkipped.
  ///
  /// In zh, this message translates to:
  /// **'，跳过重复 {count} 笔'**
  String importSkipped(String count);

  /// No description provided for @importUnmatchedSuffix.
  ///
  /// In zh, this message translates to:
  /// **'，{count} 笔分类未匹配已记为未分类'**
  String importUnmatchedSuffix(String count);

  /// No description provided for @importFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败：{error}'**
  String importFailed(String error);

  /// No description provided for @importImportable.
  ///
  /// In zh, this message translates to:
  /// **'可导入'**
  String get importImportable;

  /// No description provided for @importSkippedDuplicates.
  ///
  /// In zh, this message translates to:
  /// **'重复跳过'**
  String get importSkippedDuplicates;

  /// No description provided for @importParseFailed.
  ///
  /// In zh, this message translates to:
  /// **'格式失败'**
  String get importParseFailed;

  /// No description provided for @importUnmatched.
  ///
  /// In zh, this message translates to:
  /// **'分类未匹配（将记为未分类）'**
  String get importUnmatched;

  /// No description provided for @importFailureDetails.
  ///
  /// In zh, this message translates to:
  /// **'失败明细（最多显示 5 条）'**
  String get importFailureDetails;

  /// No description provided for @importRowIssue.
  ///
  /// In zh, this message translates to:
  /// **'第 {row} 行：{reason}'**
  String importRowIssue(String row, String reason);

  /// No description provided for @importNoNewRecords.
  ///
  /// In zh, this message translates to:
  /// **'没有可导入的新记录'**
  String get importNoNewRecords;

  /// No description provided for @importConfirmCount.
  ///
  /// In zh, this message translates to:
  /// **'确认导入 {count} 笔'**
  String importConfirmCount(String count);

  /// No description provided for @importSuccess.
  ///
  /// In zh, this message translates to:
  /// **'导入完成，明细与总览已刷新'**
  String get importSuccess;

  /// No description provided for @importTip.
  ///
  /// In zh, this message translates to:
  /// **'提示：先在「数据导出」里导出一份当前数据，再导入旧备份，可最大程度避免误操作带来的数据混乱。'**
  String get importTip;

  /// No description provided for @importSelectedFile.
  ///
  /// In zh, this message translates to:
  /// **'已选择文件'**
  String get importSelectedFile;

  /// No description provided for @exportTitle.
  ///
  /// In zh, this message translates to:
  /// **'数据导出'**
  String get exportTitle;

  /// No description provided for @exportCount.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 笔账目'**
  String exportCount(String count);

  /// No description provided for @exportIntro.
  ///
  /// In zh, this message translates to:
  /// **'导出为 CSV 或 JSON 备份文件，可保存到「下载」或发送。导出的文件可在「数据导入」中恢复。'**
  String get exportIntro;

  /// No description provided for @exportCsv.
  ///
  /// In zh, this message translates to:
  /// **'导出 CSV'**
  String get exportCsv;

  /// No description provided for @exportJson.
  ///
  /// In zh, this message translates to:
  /// **'导出 JSON'**
  String get exportJson;

  /// No description provided for @exportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败：{error}'**
  String exportFailed(String error);

  /// No description provided for @importErrorUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'不支持的文件类型：{name}（仅支持 .csv / .json）'**
  String importErrorUnsupported(String name);

  /// No description provided for @importErrorJsonInvalid.
  ///
  /// In zh, this message translates to:
  /// **'JSON 格式无法解析，请确认文件完整'**
  String get importErrorJsonInvalid;

  /// No description provided for @importErrorJsonNotArray.
  ///
  /// In zh, this message translates to:
  /// **'JSON 备份应为账目数组（[...]）'**
  String get importErrorJsonNotArray;

  /// No description provided for @importErrorCsvEmpty.
  ///
  /// In zh, this message translates to:
  /// **'CSV 文件为空'**
  String get importErrorCsvEmpty;

  /// No description provided for @importErrorCsvMissing.
  ///
  /// In zh, this message translates to:
  /// **'CSV 缺少必需列：{columns}（表头需包含 type, amount, date）'**
  String importErrorCsvMissing(String columns);

  /// No description provided for @importErrorRowNotObject.
  ///
  /// In zh, this message translates to:
  /// **'不是对象'**
  String get importErrorRowNotObject;

  /// No description provided for @importErrorType.
  ///
  /// In zh, this message translates to:
  /// **'无法识别类型「{value}」'**
  String importErrorType(String value);

  /// No description provided for @importErrorAmount.
  ///
  /// In zh, this message translates to:
  /// **'金额无效「{value}」'**
  String importErrorAmount(String value);

  /// No description provided for @importErrorDate.
  ///
  /// In zh, this message translates to:
  /// **'日期无效「{value}」（应为 yyyy-MM-dd）'**
  String importErrorDate(String value);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
