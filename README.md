> 中文版：[README.zh-CN.md](README.zh-CN.md)

# Spent Tracker

A personal expense tracker for recording spending and income, with time-based analysis, budgets, multi-currency support and data export/import. Built with Flutter; all data stays on the device in Hive, so the app works fully offline.

## Features

### v1 — Core ledger
- **Add an entry**: expense/income, amount (stored as integer cents to avoid floating-point drift), category, date, note
- **Transaction list**: grouped by date, newest first, filterable by type and category
- **Edit / delete**: both require a confirmation step
- **Categories**: preset categories cannot be deleted; deleting a custom category moves its historical entries to "Uncategorized"
- **Monthly summary**: total expense, total income, balance, plus a category-share donut chart

### v2 — Time analysis and budgets (8 P0 items)
- **Date range filter**: this week / this month / last month / last 7 days / custom range
- **Trend chart**: 6- or 12-month dual line chart for expenses and income
- **Category breakdown**: expense and income tabs, donut share plus a ranked amount list
- **Budgets**: overall and per-category budgets, progress bars on the overview page, over-budget highlighted in red, and a soft "will exceed" hint while entering an amount (never blocking)
- **Data export**: CSV / JSON through the system share sheet
- **Recurring entries**: weekly / monthly / yearly rules surface a "due today" banner on the overview page; tapping it pre-fills the entry form and you confirm manually (**no automatic booking**)
- **Search**: exact match on note, category name or amount, combinable with the type and category filters
- **Multi-currency**: SGD is the base currency; all aggregates (balance, trend, budgets, shares) are shown in SGD while the list and detail sheet keep the original currency; exchange rates can be edited by hand or updated from the network

### v2.1 — Polish and dark mode
- **Dark mode**: Settings → Appearance offers System / Light / Dark; the choice is persisted in Hive
- **Unified palette**: all colors go through `AppPalette` (a `ThemeExtension` with light and dark variants), removing scattered hard-coded values
- **Currency symbols**: resolved in one place by `symbolOf()`, falling back to `S$`

### v2.2 — Annual report
- **Yearly trend**: 12-month dual bar chart for expenses and income, with year switching (never past the current year)
- **Key stats**: number of entries, average monthly expense (computed only over months that have expenses), peak expense month
- **Category ranking**: expense and income tabs, sorted by amount with percentage shares
- Entry points: the button at the top right of the overview page, and Settings → Analysis

### v3.0 — Data import
- **Format**: the CSV / JSON files this app exports (`type, amount, currency, category, date, note, createdAt`)
- **Preview before writing**: after choosing a file the app shows how many rows are importable, duplicates to skip, parse failures and unmatched categories, with row numbers and reasons for the first five failures
- **Append only**: after a confirmation dialog entries are appended one by one; nothing is deleted or overwritten, and rows matching an existing entry on type + amount + currency + date + note + category are skipped as duplicates (including duplicates inside the same file)
- **Category mapping**: matched by type + category name; unmatched names become "Uncategorized"
- Entry point: Settings → Data → Import

## Tech stack

| Purpose | Choice |
|---|---|
| Framework | Flutter (Dart) |
| Local storage | Hive with custom `TypeAdapter`s that tolerate missing legacy fields |
| State management | Riverpod (`Box.watch()` feeding `StreamProvider`s for reactive updates) |
| Charts | fl_chart |
| Share / export | share_plus |
| File picking (import) | file_picker |

## Project structure

```
lib/
├── app.dart / main.dart        # entry point and theme setup
├── core/                       # constants, money/date helpers, theme palette (theme/), import parser (io/)
├── data/
│   ├── models/                 # Category / Transaction / Currency / Budget / RecurringRule (with *.g.dart)
│   └── db/                     # Hive boxes and repositories (business rules live here, including the import service)
├── state/                      # Riverpod providers (range, summary, trend, budget, recurring, currency, theme, annual)
└── ui/
    ├── overview/               # overview: range switcher, budgets, trend, category breakdown, recent entries
    ├── transactions/           # transaction list with search, filters and range switching
    ├── analysis/               # annual report
    ├── settings/               # categories, budgets, recurring rules, currencies, export, import, appearance
    └── widgets/                # shared widgets: entry sheet, transaction tile, detail sheet, range picker
test/
├── category_repository_test.dart   # v1 repository rules (real async)
├── v2_repository_test.dart         # v2 budgets, date ranges, recurring rules, currency conversion
├── annual_summary_test.dart        # annual aggregation rules
├── import_test.dart                # CSV/JSON parsing (quotes, invalid rows) and dedup / category mapping
└── widget_test.dart                # UI flows: entry, edit confirmation, category deletion, monthly summary, search, dark mode
```

## Getting started

```bash
flutter pub get
flutter run -d windows        # desktop
flutter run -d <device-id>    # Android / iOS device
```

Regenerate Hive adapters after changing a model:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## iOS install (iLoader + SideStore)

iOS builds cannot be produced on Windows, so the repo ships a GitHub Actions workflow that builds an **unsigned IPA** on a macOS runner; signing happens on the phone through iLoader / SideStore.

1. Pushing a tag (`git push origin --tags`) triggers `.github/workflows/ios-ipa.yml`; it can also be started manually with `Run workflow` on the Actions page
2. Download `SpentTracker-unsigned.ipa` from the workflow artifact or the GitHub Release
3. Use iLoader on the computer to place a pairing file, then install SideStore
4. Import the IPA in SideStore, signed with your own Apple ID; the bundle identifier is `com.spenttracker.spentTracker`
5. A free Apple ID signature lasts 7 days, so keep SideStore's automatic refresh enabled; a free account can sign at most 3 apps at a time

Note: reinstalling (uninstall then install) clears the local Hive data; an upgrade install keeps it.

## Verification

```bash
flutter analyze   # static analysis
flutter test      # 27 tests: 17 logic/repository tests, 8 UI interaction tests, 2 appearance persistence tests
```

Current status: `flutter analyze` reports no issues; `flutter test` passes 27/27. `flutter build windows --debug` also succeeds, which confirms the native file-picker plugin compiles.

## Money and exchange rates

- Amounts are always stored as **integer cents**
- Base currency is **SGD**; presets are SGD (1.0), CNY (0.186), MYR (0.30)
- A rate means "1 unit of this currency = ? SGD"; if the online update fails the app falls back to the manual rates and never blocks data entry
- Budgets are monthly; a month without an explicit budget inherits the most recent month that has one

## Releases

| Tag | Highlights |
|---|---|
| `v1.0` | Core ledger: add entry, transaction list, monthly summary, category management |
| `v2.0` | Date filters, trend chart, category breakdown, budgets and over-budget warnings, export, recurring entries, search, multi-currency |
| `v2.1` | Dark mode, unified palette, shared currency symbol helper |
| `v2.2` | Annual report: 12-month bars, key stats, category ranking |
| `v3.0` | Data import: CSV / JSON preview, deduplication, category name mapping |
| `v3.1` | Faster import deduplication, expanded documentation |

## Known limitations

- Recurring entries only remind and pre-fill inside the app; they are never booked automatically and do not use push notifications
- The import deduplication key is type + amount + currency + date + note + category, so two genuinely identical entries would be treated as duplicates and skipped
- No cloud sync and no app lock yet (planned for a later version)
- Online rate updates depend on the public `open.er-api.com` endpoint; offline the app uses the locally stored rates
