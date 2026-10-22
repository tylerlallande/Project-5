import 'package:flutter/material.dart';

enum BringItemCategory {
  food('Food', Icons.restaurant_rounded),
  drinks('Drinks', Icons.local_drink_rounded),
  gear('Gear', Icons.handyman_rounded),
  games('Games', Icons.sports_rounded),
  other('Other', Icons.inventory_2_rounded);

  const BringItemCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

class BringItem {
  const BringItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.category,
    this.claimedBy,
    this.isPacked = false,
  });

  final String id;
  final String name;
  final int quantity;
  final BringItemCategory category;
  final String? claimedBy;
  final bool isPacked;

  BringItem copyWith({
    String? name,
    int? quantity,
    BringItemCategory? category,
    String? claimedBy,
    bool clearClaim = false,
    bool? isPacked,
  }) {
    return BringItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      claimedBy: clearClaim ? null : claimedBy ?? this.claimedBy,
      isPacked: isPacked ?? this.isPacked,
    );
  }

  factory BringItem.fromJson(Map<String, dynamic> data) => BringItem(
    id: data['id'] as String,
    name: data['name'] as String,
    quantity: data['quantity'] as int,
    category: BringItemCategory.values.firstWhere(
      (value) => value.name == data['category'],
      orElse: () => BringItemCategory.other,
    ),
    claimedBy: data['claimedBy'] as String?,
    isPacked: data['isPacked'] as bool? ?? false,
  );
}
