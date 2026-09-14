import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../theme/app_theme.dart';

class EtrnTitlesBlock extends StatelessWidget {
  final List<EtrnTitle> titles;
  final bool compact;

  const EtrnTitlesBlock({
    super.key,
    required this.titles,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (titles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          compact ? 'Титулы' : 'Подписанные документы',
          style: TextStyle(
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        for (final title in titles) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: title.signed
                        ? const Color(0xFFD9E6F5)
                        : AppColors.sand,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    title.code,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: title.signed ? AppColors.navy : AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        title.statusLine,
                        style: TextStyle(
                          fontSize: 12,
                          color: title.signed ? AppColors.ink : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
