import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/db/category_repository.dart';
import '../data/db/database.dart';
import '../data/models/category.dart';

/// 分类盒子的变更事件流：任何增删改都会触发，驱动状态自动刷新。
final categoriesBoxEventsProvider = StreamProvider<BoxEvent>((ref) {
  return Db.categories.watch();
});

/// 分类状态：监听 Hive 盒子变化，增删改后自动刷新。
class CategoryNotifier extends Notifier<List<Category>> {
  CategoryNotifier();

  @override
  List<Category> build() {
    ref.watch(categoriesBoxEventsProvider);
    return const CategoryRepository().getAll();
  }

  /// 新增自定义分类
  Future<int> add(String name, int type, String? icon) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return -1;
    return const CategoryRepository().add(
      Category(name: trimmed, type: type, icon: icon),
    );
  }

  /// 修改自定义分类
  Future<void> update(Category category, String name, String? icon) async {
    category.name = name.trim();
    category.icon = icon;
    await const CategoryRepository().update(category);
  }

  /// 删除自定义分类；历史账目自动置「未分类」，预设分类抛错。
  Future<void> remove(int key) => const CategoryRepository().delete(key);

  /// 指定类型（0=支出，1=收入）的分类
  List<Category> ofType(int type) =>
      state.where((c) => c.type == type).toList();
}

final categoryProvider = NotifierProvider<CategoryNotifier, List<Category>>(
  CategoryNotifier.new,
);
