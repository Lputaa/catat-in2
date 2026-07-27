import 'package:uuid/uuid.dart';
import '../database_helper.dart';
import '../models/transaction_template_model.dart';

class TemplateRepo {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<TransactionTemplateModel>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('transaction_templates', orderBy: 'name ASC');
    return maps.map(TransactionTemplateModel.fromMap).toList();
  }

  Future<void> insert(TransactionTemplateModel template) async {
    final db = await _db.database;
    await db.insert('transaction_templates', template.toMap());
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('transaction_templates', where: 'id = ?', whereArgs: [id]);
  }

  String newId() => 'tpl_${_uuid.v4()}';
}
