import 'package:flutter/material.dart';

/// Maps Material icon name strings (category + picker) to [IconData].
IconData appIconFromName(String name) {
  switch (name) {
    case 'restaurant':
      return Icons.restaurant;
    case 'directions_car':
      return Icons.directions_car;
    case 'shopping_bag':
      return Icons.shopping_bag;
    case 'receipt_long':
      return Icons.receipt_long;
    case 'local_hospital':
      return Icons.local_hospital;
    case 'movie':
      return Icons.movie;
    case 'flight':
      return Icons.flight;
    case 'school':
      return Icons.school;
    case 'account_balance_wallet':
      return Icons.account_balance_wallet;
    case 'laptop':
      return Icons.laptop;
    case 'swap_horiz':
      return Icons.swap_horiz;
    case 'trending_up':
      return Icons.trending_up;
    case 'more_horiz':
      return Icons.more_horiz;
    case 'payments':
      return Icons.payments;
    case 'home':
      return Icons.home;
    case 'savings':
      return Icons.savings;
    case 'fitness_center':
      return Icons.fitness_center;
    case 'pets':
      return Icons.pets;
    case 'coffee':
      return Icons.coffee;
    case 'phone_android':
      return Icons.phone_android;
    case 'build':
      return Icons.build;
    default:
      return Icons.label_outline;
  }
}

/// Icons shown in category picker grid (extends Design §5.2).
const List<String> kCategoryIconKeys = [
  'restaurant',
  'directions_car',
  'shopping_bag',
  'receipt_long',
  'local_hospital',
  'movie',
  'flight',
  'school',
  'account_balance_wallet',
  'laptop',
  'swap_horiz',
  'trending_up',
  'more_horiz',
  'payments',
  'home',
  'savings',
  'fitness_center',
  'pets',
  'coffee',
  'phone_android',
  'build',
];
