import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import 'overview/overview_page.dart';
import 'settings/settings_page.dart';
import 'transactions/transaction_list_page.dart';
import 'widgets/add_transaction_sheet.dart';

/// 应用主骨架：底部导航（总览 / 明细 / 设置）+ 悬浮「+」录入入口。
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _pages = <Widget>[
    OverviewPage(),
    TransactionListPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // 设置页不展示「记一笔」悬浮入口
    final showEntryButton = _index != 2;
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButton: showEntryButton
          ? FloatingActionButton(
              onPressed: () => AddTransactionSheet.show(context),
              tooltip: l10n.fabAdd,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: l10n.navOverview,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.navTransactions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
