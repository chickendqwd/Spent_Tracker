import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/db/database.dart';
import '../data/db/transaction_repository.dart';
import '../data/models/transaction.dart';

/// 账目盒子的变更事件流：任何增删改都会触发，驱动状态自动刷新。
final transactionsBoxEventsProvider = StreamProvider<BoxEvent>((ref) {
  return Db.transactions.watch();
});

/// 账目状态：监听 Hive 盒子变化，增删改后自动刷新。
class TransactionNotifier extends Notifier<List<Transaction>> {
  TransactionNotifier();

  @override
  List<Transaction> build() {
    ref.watch(transactionsBoxEventsProvider);
    return const TransactionRepository().getAll();
  }

  Future<int> add(Transaction transaction) =>
      const TransactionRepository().add(transaction);

  Future<void> update(Transaction transaction) =>
      const TransactionRepository().update(transaction);

  Future<void> remove(int key) => const TransactionRepository().delete(key);
}

final transactionProvider =
    NotifierProvider<TransactionNotifier, List<Transaction>>(
      TransactionNotifier.new,
    );
