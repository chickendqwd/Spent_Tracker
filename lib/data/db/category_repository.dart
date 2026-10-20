import '../models/category.dart';
import 'database.dart';

/// 分类仓库：封装 Hive 读写与分类业务规则。
class CategoryRepository {
  const CategoryRepository();

  /// 全部分类（按创建顺序）
  List<Category> getAll() =>
      Db.categories.values.toList()
        ..sort((a, b) => (a.key as int).compareTo(b.key as int));

  /// 指定类型（0=支出，1=收入）的分类
  List<Category> byType(int type) =>
      getAll().where((c) => c.type == type).toList();

  Category? byKey(int key) => Db.categories.get(key);

  Future<int> add(Category category) => Db.categories.add(category);

  Future<void> update(Category category) => category.save();

  /// 删除自定义分类；已引用该分类的历史账目置为「未分类」。
  /// 预设分类禁止删除（UI 已隐藏删除入口，此处仍做拦截）。
  Future<void> delete(int key) async {
    final category = Db.categories.get(key);
    if (category == null) return;
    if (category.isPreset) {
      throw StateError('预设分类禁止删除');
    }
    final affected = Db.transactions.values
        .where((t) => t.categoryId == key)
        .toList();
    for (final t in affected) {
      t.categoryId = null; // 置为「未分类」
      await t.save();
    }
    await Db.categories.delete(key);
  }
}
