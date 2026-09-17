import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Простые «скелеты» вместо пустого экрана при первой загрузке.
class TripListSkeleton extends StatelessWidget {
  const TripListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.nightLine : const Color(0xFFE8E2D6);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            height: 118,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(base, width: 140, height: 16),
                const SizedBox(height: 16),
                _bar(base, width: double.infinity, height: 14),
                const SizedBox(height: 10),
                _bar(base, width: 180, height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bar(Color color, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
