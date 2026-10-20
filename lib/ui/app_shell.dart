import 'package:flutter/material.dart';

import 'overview/overview_page.dart';
import 'settings/categories_page.dart';
import 'transactions/transaction_list_page.dart';
import 'widgets/add_transaction_sheet.dart';

/// 应用主骨架：底部导航（总览 / 明细 / 设置）+ 悬浮「+」录入入口。
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _pages = <Widget>[
    OverviewPage(),
    TransactionListPage(),
    CategoriesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // 设置页不展示「记一笔」悬浮入口
    final showEntryButton = _index != 2;
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButton: showEntryButton
          ? FloatingActionButton(
              onPressed: () => AddTransactionSheet.show(context),
              tooltip: '记一笔',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: '总览',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '明细',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
