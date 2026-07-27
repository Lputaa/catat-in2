/// [paylater] is a credit/liability wallet (SPayLater, kartu kredit, dsb):
/// purchases are recorded as normal expenses from it, so its balance goes
/// negative until repaid via transfer — expenses stay tracked & budgeted.
enum AccountType { cash, bank, ewallet, paylater, other }

class AccountModel {
  final String id;
  final String name;
  final double initialBalance;
  final AccountType type;

  const AccountModel({
    required this.id,
    required this.name,
    required this.initialBalance,
    required this.type,
  });

  String get typeLabel {
    switch (type) {
      case AccountType.cash:
        return 'Tunai';
      case AccountType.bank:
        return 'Rekening Bank';
      case AccountType.ewallet:
        return 'E-Wallet';
      case AccountType.paylater:
        return 'Paylater / Kredit';
      case AccountType.other:
        return 'Lainnya';
    }
  }

  /// Liability wallet — balance is expected to be ≤ 0.
  bool get isCredit => type == AccountType.paylater;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'initial_balance': initialBalance,
    'type': type.name,
  };

  factory AccountModel.fromMap(Map<String, dynamic> m) => AccountModel(
    id: m['id'] as String,
    name: m['name'] as String,
    initialBalance: (m['initial_balance'] as num).toDouble(),
    type: AccountType.values.firstWhere(
      (e) => e.name == m['type'],
      orElse: () => AccountType.cash,
    ),
  );

  AccountModel copyWith({
    String? id,
    String? name,
    double? initialBalance,
    AccountType? type,
  }) => AccountModel(
    id: id ?? this.id,
    name: name ?? this.name,
    initialBalance: initialBalance ?? this.initialBalance,
    type: type ?? this.type,
  );
}
