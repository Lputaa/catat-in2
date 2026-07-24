import 'package:uuid/uuid.dart';
import '../database_helper.dart';
import '../models/category_model.dart';

class CategoryRepo {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<CategoryModel>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('categories', orderBy: 'name');
    return maps.map(CategoryModel.fromMap).toList();
  }

  Future<List<CategoryModel>> getByType(CategoryType type) async {
    final db = await _db.database;
    final maps = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type == CategoryType.income ? 'income' : 'expense'],
      orderBy: 'name',
    );
    return maps.map(CategoryModel.fromMap).toList();
  }

  Future<CategoryModel?> getById(String id) async {
    final db = await _db.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return CategoryModel.fromMap(maps.first);
  }

  Future<void> insert(CategoryModel cat) async {
    final db = await _db.database;
    await db.insert('categories', cat.toMap());
  }

  Future<void> update(CategoryModel cat) async {
    final db = await _db.database;
    await db.update('categories', cat.toMap(), where: 'id = ?', whereArgs: [cat.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  String newId() => 'cat_${_uuid.v4()}';
}
