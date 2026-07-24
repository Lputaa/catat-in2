import 'package:flutter/material.dart';

enum TransactionTypeFilter { all, income, expense }

enum SortOrder { newest, oldest, largest, smallest }

class TransactionFilterState {
  final TransactionTypeFilter typeFilter;
  final DateTimeRange? dateRange;
  final String? accountId;
  final SortOrder sortOrder;
  final String searchQuery;

  const TransactionFilterState({
    this.typeFilter = TransactionTypeFilter.all,
    this.dateRange,
    this.accountId,
    this.sortOrder = SortOrder.newest,
    this.searchQuery = '',
  });

  TransactionFilterState copyWith({
    TransactionTypeFilter? typeFilter,
    DateTimeRange? dateRange,
    String? accountId,
    SortOrder? sortOrder,
    String? searchQuery,
    bool clearDateRange = false,
    bool clearAccount = false,
  }) {
    return TransactionFilterState(
      typeFilter: typeFilter ?? this.typeFilter,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      accountId: clearAccount ? null : (accountId ?? this.accountId),
      sortOrder: sortOrder ?? this.sortOrder,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get isFiltered =>
      typeFilter != TransactionTypeFilter.all ||
      dateRange != null ||
      accountId != null ||
      sortOrder != SortOrder.newest ||
      searchQuery.isNotEmpty;

  bool get hasDateRange => dateRange != null;
  bool get hasAccountFilter => accountId != null;
  bool get hasSearchQuery => searchQuery.isNotEmpty;
  bool get hasTypeFilter => typeFilter != TransactionTypeFilter.all;

  String get dateRangeLabel {
    if (dateRange == null) {
      return 'Semua Tanggal';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(dateRange!.start.year, dateRange!.start.month, dateRange!.start.day);
    final end = DateTime(dateRange!.end.year, dateRange!.end.month, dateRange!.end.day);

    if (start == today && end == today) {
      return 'Hari Ini';
    }
    if (start == today.subtract(const Duration(days: 6)) && end == today) {
      return '7 Hari';
    }
    if (start == DateTime(now.year, now.month, 1) &&
        end == DateTime(now.year, now.month + 1, 0)) {
      return 'Bulan Ini';
    }

    final startStr = '${start.day}/${start.month}';
    final endStr = '${end.day}/${end.month}';
    return '$startStr - $endStr';
  }

  String get typeFilterLabel {
    switch (typeFilter) {
      case TransactionTypeFilter.all:
        return 'Semua';
      case TransactionTypeFilter.income:
        return 'Pemasukan';
      case TransactionTypeFilter.expense:
        return 'Pengeluaran';
    }
  }

  String get sortOrderLabel {
    switch (sortOrder) {
      case SortOrder.newest:
        return 'Terbaru';
      case SortOrder.oldest:
        return 'Terlama';
      case SortOrder.largest:
        return 'Terbesar';
      case SortOrder.smallest:
        return 'Terkecil';
    }
  }
}
