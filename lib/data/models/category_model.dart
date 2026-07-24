import 'package:flutter/material.dart';

enum CategoryType { income, expense }

class CategoryModel {
  final String id;
  final String name;
  final CategoryType type;
  final String icon;   // Material icon codepoint as string
  final int color;     // Color hex value

  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });

  Color get colorValue => Color(color);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type == CategoryType.income ? 'income' : 'expense',
        'icon': icon,
        'color': color,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> m) => CategoryModel(
        id: m['id'] as String,
        name: m['name'] as String,
        type: (m['type'] as String) == 'income'
            ? CategoryType.income
            : CategoryType.expense,
        icon: m['icon'] as String,
        color: m['color'] as int,
      );
}
