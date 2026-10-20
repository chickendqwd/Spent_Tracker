import '../models/transaction.dart';
import 'database.dart';

/// 账目仓库：封装 Hive 读写与账目业务规则。
class TransactionRepository {
  const TransactionRepository();

  /// 全部账目：日期倒序，同日按创建时间倒序
  List<Transaction> getAll() {
    final list = Db.transactions.values.toList();
    list.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  Transaction? byKey(int key) => Db.transactions.get(key);

  Future<int> add(Transaction transaction) => Db.transactions.add(transaction);

  Future<void> update(Transaction transaction) => transaction.save();

  Future<void> delete(int key) => Db.transactions.delete(key);
}
