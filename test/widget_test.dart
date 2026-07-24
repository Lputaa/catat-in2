import 'package:flutter_test/flutter_test.dart';
import 'package:catat_in2/data/models/transaction_model.dart';
import 'package:catat_in2/data/models/category_model.dart';
import 'package:catat_in2/data/models/account_model.dart';
import 'package:catat_in2/data/models/budget_model.dart';

void main() {
  group('TransactionModel', () {
    test('roundtrip toMap/fromMap', () {
      final tx = TransactionModel(
        id: 'tx_1',
        type: TransactionType.expense,
        amount: 50000,
        categoryId: 'cat_makanan',
        accountId: 'acc_tunai',
        date: DateTime(2026, 7, 22),
        note: 'Makan siang',
      );
      final map = tx.toMap();
      final restored = TransactionModel.fromMap(map);
      expect(restored.id, 'tx_1');
      expect(restored.type, TransactionType.expense);
      expect(restored.amount, 50000);
      expect(restored.note, 'Makan siang');
    });
  });

  group('CategoryModel', () {
    test('roundtrip toMap/fromMap', () {
      final cat = CategoryModel(
        id: 'cat_makanan',
        name: 'Makanan',
        type: CategoryType.expense,
        icon: 'restaurant',
        color: 0xFFFF6B35,
      );
      final map = cat.toMap();
      final restored = CategoryModel.fromMap(map);
      expect(restored.id, 'cat_makanan');
      expect(restored.name, 'Makanan');
      expect(restored.type, CategoryType.expense);
    });
  });

  group('AccountModel', () {
    test('roundtrip toMap/fromMap', () {
      final acc = AccountModel(
        id: 'acc_tunai',
        name: 'Tunai',
        initialBalance: 100000,
        type: AccountType.cash,
      );
      final map = acc.toMap();
      final restored = AccountModel.fromMap(map);
      expect(restored.name, 'Tunai');
      expect(restored.typeLabel, 'Tunai');
    });
  });

  group('BudgetModel', () {
    test('roundtrip toMap/fromMap', () {
      final b = BudgetModel(
        id: 'bgt_1',
        categoryId: 'cat_makanan',
        limitAmount: 500000,
        year: 2026,
        month: 7,
      );
      final map = b.toMap();
      final restored = BudgetModel.fromMap(map);
      expect(restored.limitAmount, 500000);
      expect(restored.month, 7);
    });
  });
}
