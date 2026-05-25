import 'package:flutter/material.dart';
import 'skeleton.dart';

enum LoadingType { default_, home, transactions, reports, categories }

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
    this.type = LoadingType.default_,
  });

  const LoadingWidget.home({super.key}) : type = LoadingType.home;
  const LoadingWidget.transactions({super.key}) : type = LoadingType.transactions;
  const LoadingWidget.reports({super.key}) : type = LoadingType.reports;
  const LoadingWidget.categories({super.key}) : type = LoadingType.categories;

  final LoadingType type;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case LoadingType.home:
        return const HomeScreenSkeleton();
      case LoadingType.transactions:
        return const TransactionScreenSkeleton();
      case LoadingType.reports:
        return const StatsScreenSkeleton();
      case LoadingType.categories:
        return const TransactionScreenSkeleton(); // Reuse list skeleton
      default:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        );
    }
  }
}
