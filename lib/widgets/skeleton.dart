import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_colors.dart';

class SkeletonContainer extends StatelessWidget {
  const SkeletonContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.margin,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark
        ? AppColors.surfaceContainerHighDark
        : AppColors.surfaceContainerHighLight;
    final highlightColor = isDark 
        ? AppColors.cardDark 
        : AppColors.bgLight;

    return Container(
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

class TransactionScreenSkeleton extends StatelessWidget {
  const TransactionScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            const Row(
              children: [
                SkeletonContainer(width: 40, height: 40, borderRadius: 20),
                SizedBox(width: 12),
                SkeletonContainer(width: 200, height: 32),
                Spacer(),
                SkeletonContainer(width: 40, height: 40, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 24),
            // Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  4,
                  (i) => const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: SkeletonContainer(width: 80, height: 40, borderRadius: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Group Title
            const SkeletonContainer(width: 100, height: 16),
            const SizedBox(height: 16),
            // Items
            ...List.generate(3, (i) => const TransactionItemSkeleton()),
            const SizedBox(height: 24),
            // Another Group
            const SkeletonContainer(width: 80, height: 16),
            const SizedBox(height: 16),
            ...List.generate(2, (i) => const TransactionItemSkeleton()),
          ],
        ),
      ),
    );
  }
}

class TransactionItemSkeleton extends StatelessWidget {
  const TransactionItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SkeletonContainer(width: 48, height: 48, borderRadius: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonContainer(width: 140, height: 16),
                  SizedBox(height: 8),
                  SkeletonContainer(width: 80, height: 12),
                ],
              ),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SkeletonContainer(width: 60, height: 24),
                SizedBox(height: 8),
                SkeletonContainer(width: 40, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreenSkeleton extends StatelessWidget {
  const RegisterScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonContainer(width: 200, height: 40),
          const SizedBox(height: 16),
          const SkeletonContainer(width: double.infinity, height: 16),
          const SkeletonContainer(width: 250, height: 16, margin: EdgeInsets.only(top: 8)),
          const SizedBox(height: 48),
          // Fields
          ...List.generate(3, (i) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonContainer(width: 100, height: 16),
              const SizedBox(height: 8),
              const SkeletonContainer(width: double.infinity, height: 56, borderRadius: 12),
              const SizedBox(height: 24),
            ],
          )),
          const SizedBox(height: 16),
          const SkeletonContainer(width: double.infinity, height: 56, borderRadius: 12),
          const SizedBox(height: 24),
          const Center(child: SkeletonContainer(width: 150, height: 16)),
        ],
      ),
    );
  }
}

class LoginScreenSkeleton extends StatelessWidget {
  const LoginScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonContainer(width: 64, height: 64, borderRadius: 16),
          const SizedBox(height: 24),
          const SkeletonContainer(width: 250, height: 40),
          const SizedBox(height: 8),
          const SkeletonContainer(width: 180, height: 40),
          const SizedBox(height: 16),
          const SkeletonContainer(width: 280, height: 16),
          const SizedBox(height: 48),
          // Fields
          const SkeletonContainer(width: 80, height: 16),
          const SizedBox(height: 8),
          const SkeletonContainer(width: double.infinity, height: 56, borderRadius: 12),
          const SizedBox(height: 24),
          const SkeletonContainer(width: 100, height: 16),
          const SizedBox(height: 8),
          const SkeletonContainer(width: double.infinity, height: 56, borderRadius: 12),
          const SizedBox(height: 12),
          const Align(alignment: Alignment.centerRight, child: SkeletonContainer(width: 120, height: 16)),
          const SizedBox(height: 32),
          const SkeletonContainer(width: double.infinity, height: 64, borderRadius: 12),
          const SizedBox(height: 24),
          const Center(child: SkeletonContainer(width: 180, height: 16)),
          const SizedBox(height: 48),
          // Social Login placeholders
          Row(
            children: [
              const Expanded(child: SkeletonContainer(height: 56, borderRadius: 12)),
              const SizedBox(width: 16),
              const Expanded(child: SkeletonContainer(height: 56, borderRadius: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class StatsScreenSkeleton extends StatelessWidget {
  const StatsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonContainer(width: 40, height: 40, borderRadius: 20),
              SizedBox(width: 12),
              SkeletonContainer(width: 180, height: 32),
              Spacer(),
              SkeletonContainer(width: 40, height: 40, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 32),
          const SkeletonContainer(width: double.infinity, height: 220, borderRadius: 24),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: SkeletonContainer(height: 100, borderRadius: 20)),
              const SizedBox(width: 16),
              const Expanded(child: SkeletonContainer(height: 100, borderRadius: 20)),
            ],
          ),
          const SizedBox(height: 32),
          const SkeletonContainer(width: 120, height: 20),
          const SizedBox(height: 16),
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: const SkeletonContainer(width: double.infinity, height: 80, borderRadius: 16),
          )),
        ],
      ),
    );
  }
}

class AddTransactionScreenSkeleton extends StatelessWidget {
  const AddTransactionScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Center(child: SkeletonContainer(width: 200, height: 60)),
          const SizedBox(height: 48),
          const SkeletonContainer(width: 100, height: 16),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (i) => const SkeletonContainer(width: 70, height: 90, borderRadius: 16)),
          ),
          const SizedBox(height: 32),
          const SkeletonContainer(width: double.infinity, height: 56, borderRadius: 16),
          const SizedBox(height: 16),
          const SkeletonContainer(width: double.infinity, height: 56, borderRadius: 16),
          const SizedBox(height: 16),
          const SkeletonContainer(width: double.infinity, height: 120, borderRadius: 16),
          const Spacer(),
          const SkeletonContainer(width: double.infinity, height: 56, borderRadius: 16),
        ],
      ),
    );
  }
}

class BudgetScreenSkeleton extends StatelessWidget {
  const BudgetScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonContainer(width: 40, height: 40, borderRadius: 20),
              SizedBox(width: 12),
              SkeletonContainer(width: 180, height: 32),
              Spacer(),
              SkeletonContainer(width: 40, height: 40, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 32),
          const SkeletonContainer(width: double.infinity, height: 160, borderRadius: 24),
          const SizedBox(height: 32),
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: const SkeletonContainer(width: double.infinity, height: 100, borderRadius: 20),
          )),
          const SizedBox(height: 16),
          const SkeletonContainer(width: double.infinity, height: 80, borderRadius: 20),
        ],
      ),
    );
  }
}

class SearchScreenSkeleton extends StatelessWidget {
  const SearchScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonContainer(width: double.infinity, height: 56, borderRadius: 16),
          const SizedBox(height: 24),
          const SkeletonContainer(width: 100, height: 20),
          const SizedBox(height: 16),
          ...List.generate(4, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: const TransactionItemSkeleton(),
          )),
        ],
      ),
    );
  }
}

class SettingsScreenSkeleton extends StatelessWidget {
  const SettingsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const SkeletonContainer(width: 150, height: 32),
          const SizedBox(height: 32),
          ...List.generate(3, (i) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonContainer(width: 100, height: 16),
              const SizedBox(height: 16),
              ...List.generate(3, (j) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: const SkeletonContainer(width: double.infinity, height: 60, borderRadius: 12),
              )),
              const SizedBox(height: 24),
            ],
          )),
        ],
      ),
    );
  }
}

class ProfileScreenSkeleton extends StatelessWidget {
  const ProfileScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const SkeletonContainer(width: 100, height: 100, borderRadius: 50),
          const SizedBox(height: 16),
          const SkeletonContainer(width: 180, height: 24),
          const SizedBox(height: 8),
          const SkeletonContainer(width: 140, height: 16),
          const SizedBox(height: 48),
          ...List.generate(2, (i) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonContainer(width: 120, height: 20),
              const SizedBox(height: 16),
              ...List.generate(3, (j) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: const SkeletonContainer(width: double.infinity, height: 64, borderRadius: 16),
              )),
              const SizedBox(height: 24),
            ],
          )),
          const SizedBox(height: 32),
          const SkeletonContainer(width: double.infinity, height: 56, borderRadius: 16),
        ],
      ),
    );
  }
}
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 88, 24, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const SkeletonContainer(width: 32, height: 32, borderRadius: 16),
                const SizedBox(width: 12),
                const SkeletonContainer(width: 180, height: 24),
                const Spacer(),
                const SkeletonContainer(width: 20, height: 20, borderRadius: 10),
              ],
            ),
            const SizedBox(height: 24),
            // Welcome
            const SkeletonContainer(width: 120, height: 16),
            const SizedBox(height: 8),
            const SkeletonContainer(width: 200, height: 40),
            const SizedBox(height: 24),
            // Hero Balance card
            const SkeletonContainer(width: double.infinity, height: 200, borderRadius: 32),
            const SizedBox(height: 24),
            // Chips
            Row(
              children: List.generate(4, (i) => const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SkeletonContainer(width: 70, height: 36, borderRadius: 20),
              )),
            ),
            const SizedBox(height: 24),
            // Summary cards
            Row(
              children: [
                const Expanded(child: SkeletonContainer(height: 120, borderRadius: 24)),
                const SizedBox(width: 16),
                const Expanded(child: SkeletonContainer(height: 120, borderRadius: 24)),
              ],
            ),
            const SizedBox(height: 24),
            // Savings Goal
            const SkeletonContainer(width: double.infinity, height: 100, borderRadius: 24),
          ],
        ),
      ),
    );
  }
}
