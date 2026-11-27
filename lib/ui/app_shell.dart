import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import 'overview/overview_page.dart';
import 'settings/settings_page.dart';
import 'transactions/transaction_list_page.dart';
import 'widgets/add_transaction_sheet.dart';

/// 应用主骨架：底部导航（总览 / 明细 / 设置）+ 悬浮「+」录入入口。
///
/// 切换标签时做一次短促的淡入 + 轻微上移（约 240ms），
/// 用 IndexedStack 保留各页状态，动画只作用于整个页面容器。
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.014),
    end: Offset.zero,
  ).animate(_fade);

  static const _pages = <Widget>[
    OverviewPage(),
    TransactionListPage(),
    SettingsPage(),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // 设置页不展示「记一笔」悬浮入口
    final showEntryButton = _index != 2;
    return Scaffold(
      body: FadeTransition(
        opacity: Tween<double>(begin: 0.86, end: 1).animate(_fade),
        child: SlideTransition(
          position: _slide,
          child: IndexedStack(index: _index, children: _pages),
        ),
      ),
      floatingActionButton: showEntryButton
          ? FloatingActionButton(
              onPressed: () => AddTransactionSheet.show(context),
              tooltip: l10n.fabAdd,
              child: const Icon(Icons.add, size: 26),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
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
