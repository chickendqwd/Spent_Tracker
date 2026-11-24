> English version: [README.md](README.md)

# Spent Tracker

个人记账应用：记录支出与收入，支持时间维度分析、预算管控、多货币与数据导出。
基于 Flutter 构建，数据全部保存在本地（Hive），无需联网即可记账。

## 功能

### v1 — 记账闭环
- **记一笔**：支出/收入、金额（整数分存储，避免浮点误差）、分类、日期、备注
- **交易明细**：按日期倒序分组展示，支持类型/分类筛选
- **编辑与删除**：均需二次确认
- **分类管理**：预设分类不可删除；删除自定义分类后，历史账目自动置为「未分类」
- **月度总结**：总支出 / 总收入 / 结余 + 分类占比环形图

### v2 — 时间分析与预算管控（8 项 P0）
- **时间筛选**：本周 / 本月 / 上月 / 近 7 天 / 自定义区间
- **收支趋势**：近 6 或 12 个月的双线折线图（支出 / 收入）
- **分类分析**：支出 / 收入双 Tab，环形图占比 + 金额排行
- **预算**：总预算与分类预算，总览页进度条，超支标红；录入时「将超出」轻提示（不强制）
- **数据导出**：CSV / JSON，经系统分享面板保存
- **周期记账**：每周 / 每月 / 每年规则，到期日在总览页显示「今日待记」提示条，点击预填录入、手动确认入账（**不自动记账**）
- **搜索**：按备注、分类名或金额精确匹配，可与类型 / 分类筛选叠加
- **多货币**：基准币种 SGD；汇总（结余、趋势、预算、占比）统一按 SGD 展示，明细与详情保留原记账币种；汇率可手动修改或联网更新

### v2.1 — 优化打磨与深色模式
- **深色模式**：「设置 → 外观」跟随系统 / 浅色 / 深色三选一，选择写入 Hive，重启保留
- **配色收敛**：界面颜色统一走 `AppPalette`（ThemeExtension，深浅各一套），移除散落的硬编码色值
- **币种符号去重**：统一由 `symbolOf()` 提供，找不到币种时回退 `S$`

### v2.2 — 年度报告
- **年度趋势**：12 个月支出 / 收入双柱状图，可切换年份（不晚于当前年）
- **关键统计**：记账笔数、月均支出（仅按有支出的月份平均）、支出最高月
- **分类排行**：支出 / 收入双 Tab，按金额降序并显示占比
- 入口：总览页右上角按钮，以及「设置 → 分析」

### v3.0 — 数据导入
- **格式**：本应用导出的 CSV / JSON（`type, amount, currency, category, date, note, createdAt`）
- **先预览后写入**：选文件后展示「可导入 / 重复跳过 / 格式失败 / 分类未匹配」，失败行带行号与原因（最多显示 5 条）
- **追加式**：二次确认后逐条追加，不删除、不覆盖；同类型+同金额+同币种+同日期+同备注+同分类视为重复并跳过（含文件内重复）
- **分类映射**：按「类型 + 分类名」匹配现有分类，找不到的落为「未分类」
- 入口：「设置 → 数据 → 数据导入」

### v3.2 — 趋势区间、分类图标、日期修正
- **趋势区间**：趋势卡可在「本周 / 本月 / 近 3 月 / 近 6 月 / 近 12 月」间切换；常用的三档常驻显示，长区间收在「更多…」菜单里，且该入口在任何档位下都不会消失
- **按步长采样**：近 3 / 6 / 12 月按 5 / 10 / 15 天固定步长分桶（分别 18 / 18 / 24 个点），避免点数过多导致折线糊成一片；一次 O(n) 遍历完成累加，空区间保留 0
- **分类图标**：emoji 选择器扩展到约 90 个并分组展示，也可以自己输入图标；按 Unicode 字素簇校验（1–2 个），组合 emoji（如一家三口）算 1 个，非法输入回退 📦
- **周期月末日期**：每月 31 号的规则在短月份自动落到月末（4/30、2/28 或闰年 2/29）；每年 2/29 的规则在平年落到 2/28
- **金额提示更明确**：录入面板区分「未填 / 格式非法 / 必须大于 0」，并随输入清除报错
- 「设置 → 周期记账」内联说明月末规则；移除一个不再使用的 provider

## 技术栈

| 用途 | 选型 |
|---|---|
| 框架 | Flutter (Dart) |
| 本地存储 | Hive（含自定义 TypeAdapter，兼容旧数据字段缺失） |
| 状态管理 | Riverpod（`Box.watch()` → StreamProvider 驱动响应式刷新） |
| 图表 | fl_chart |
| 分享/导出 | share_plus |
| 文件选择（导入） | file_picker |

## 目录结构

```
lib/
├── app.dart / main.dart        # 入口与主题
├── core/                       # 常量、金额/日期工具、主题配色（theme/）、导入解析（io/）
├── data/
│   ├── models/                 # Category / Transaction / Currency / Budget / RecurringRule（含 *.g.dart）
│   └── db/                     # Hive 盒子 + 各仓库（业务规则所在层，含导入服务）
├── state/                      # Riverpod providers（时间区间、汇总、趋势、预算、周期规则、货币、主题、年报）
└── ui/
    ├── overview/               # 总览（时间切换/预算/趋势/分类分析/最近记录）
    ├── transactions/           # 交易明细（搜索/筛选/时间切换）
    ├── analysis/               # 年度报告
    ├── settings/               # 设置（分类/预算/周期记账/货币与汇率/导出/导入/外观）
    └── widgets/                # 共用组件（录入面板、账目条目、详情、时间选择器）
test/
├── category_repository_test.dart   # v1 仓库规则（真实异步）
├── v2_repository_test.dart         # v2 预算/时间区间/周期规则/多货币换算
├── annual_summary_test.dart        # 年度聚合规则
├── import_test.dart                # 导入解析（CSV 引号/非法行/JSON）与去重、分类映射
├── trend_analytics_test.dart       # 趋势分桶：边界、连续性、步长采样、折算调用
├── rule_and_icon_test.dart         # 周期规则月末夹取、分类图标校验
└── widget_test.dart                # UI 交互流（录入闭环、编辑确认、删除分类、月度总结、搜索、深色模式、趋势区间）
```

## 下载

| 平台 | 文件 | 安装方式 |
|---|---|---|
| 安卓 | [SpentTracker-3.2.0-android.apk](https://github.com/chickendqwd/Spent_Tracker/releases/latest/download/SpentTracker-3.2.0-android.apk)（arm64，19 MB） | 传到手机直接打开安装，按提示允许「安装未知来源应用」 |
| iOS | [SpentTracker-unsigned.ipa](https://github.com/chickendqwd/Spent_Tracker/releases/latest/download/SpentTracker-unsigned.ipa) | 未签名包，需用 iLoader + SideStore 在手机上签名（见下文） |

所有安装包都挂在 [Releases](https://github.com/chickendqwd/Spent_Tracker/releases)。APK 用开发密钥签名，适合测试；换一台机器重新构建的版本无法覆盖安装。

## 运行

```bash
flutter pub get
flutter run -d windows        # 桌面
flutter run -d <device-id>    # Android / iOS 设备
```

### iOS 安装（iLoader + SideStore）

Windows 上无法本地构建 iOS 包，仓库内置 GitHub Actions 流水线，在 macOS 机器上产出**未签名 IPA**，签名由 iPhone 端的 iLoader / SideStore 完成：

1. 推送标签（`git push origin --tags`）会自动触发 `.github/workflows/ios-ipa.yml`；也可在 Actions 页手动 `Run workflow`
2. 构建完成后，在 Actions 的产物（artifact）或 Release 附件里下载 `SpentTracker-unsigned.ipa`
3. 用 iLoader 生成 Pairing File 并导入 SideStore
4. 在 SideStore / iLoader 中导入该 IPA，Bundle ID 填 `com.spenttracker.spentTracker`，用自己的 Apple ID 签名安装
5. 免费 Apple ID 的签名 7 天有效，请开启 SideStore 的自动刷新；免费账号同时最多签名 3 个 App

注意：重装（卸载后安装）会清空本地 Hive 数据，升级覆盖安装则保留。

修改 Hive 模型后需重新生成适配器：

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 验证

```bash
flutter analyze   # 静态检查
flutter test      # 46 个测试：27 个逻辑/仓库单测 + 17 个 UI 交互测试 + 2 个外观持久化测试
```

当前状态：`flutter analyze` 无问题；`flutter test` 46/46 通过。

## 数据与汇率说明

- 金额一律以**整数分**存储
- 基准币种为 **SGD**，预设币种：SGD（1.0）、CNY（0.186）、MYR（0.30）
- 汇率含义为「1 单位本币 = ? SGD」；联网更新失败时自动回退到手动汇率，不阻塞记账
- 预算按「月」记录；当月未设置时沿用最近一个设有预算的月份

## 版本

| 标签 | 说明 |
|---|---|
| `v1.0` | 记账闭环（记一笔 / 交易列表 / 月度总结 / 分类管理） |
| `v2.0` | 时间筛选 / 趋势图 / 分类分析 / 预算与超支 / 导出 / 周期记账 / 搜索 / 多货币 |
| `v2.1` | 深色模式 / 配色收敛 / 币种符号去重 |
| `v2.2` | 年度报告（12 月柱状图、关键统计、分类排行） |
| `v3.0` | 数据导入（CSV / JSON 预览、去重、分类名映射） |
| `v3.1` | 导入去重性能优化、本文档补全 |
| `v3.2` | 趋势区间与按步长采样、约 90 个分类图标与自定义输入、周期月末日期、金额提示更明确 |

## 已知限制

- 周期记账只做应用内提醒与预填，不自动入账，也不使用系统推送
- 导入的去重键为「类型+金额+币种+日期+备注+分类名」，两笔刚好完全相同的真实记录会被误判为重复而跳过
- 暂无云同步、密码锁（属后续版本）
- 汇率联网更新依赖公开接口 `open.er-api.com`，离线时使用本地手动汇率
