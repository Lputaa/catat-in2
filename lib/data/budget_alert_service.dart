import 'models/transaction_model.dart';
import 'notification_service.dart';
import 'repositories/budget_repo.dart';
import 'repositories/category_repo.dart';
import 'repositories/transaction_repo.dart';

/// Fires spending-alert notifications when an expense pushes its category
/// budget across the 80% warning or 100% exceeded threshold.
class BudgetAlertService {
  BudgetAlertService._();

  /// Call right AFTER the expense has been inserted into the database.
  /// Only notifies on the transition (crossing), not on every transaction.
  static Future<void> checkAfterExpense(TransactionModel tx) async {
    if (tx.type != TransactionType.expense) return;
    try {
      final budgetRepo = BudgetRepo();
      final budget = await budgetRepo.getByCategoryAndMonth(
        tx.categoryId,
        tx.date.year,
        tx.date.month,
      );
      if (budget == null) return;

      final carry = await budgetRepo.getCarryOver(budget);
      final limit = budget.limitAmount + carry;
      if (limit <= 0) return;

      final spentAfter = await TransactionRepo().getCategoryTotal(
        tx.categoryId,
        tx.date.year,
        tx.date.month,
      );
      final spentBefore = spentAfter - tx.amount;

      final category = await CategoryRepo().getById(tx.categoryId);
      final name = category?.name ?? 'Kategori';

      if (spentBefore <= limit && spentAfter > limit) {
        await NotificationService.instance.showBudgetExceeded(
          categoryName: name,
          over: spentAfter - limit,
        );
      } else if (spentBefore < limit * 0.8 && spentAfter >= limit * 0.8) {
        await NotificationService.instance.showBudgetWarning(
          categoryName: name,
          percent: spentAfter / limit * 100,
          remaining: limit - spentAfter,
        );
      }
    } catch (_) {
      // Alerts are best-effort; never break the save flow.
    }
  }
}
