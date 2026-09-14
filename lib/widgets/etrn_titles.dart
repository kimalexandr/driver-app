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
    EtrnTitle? next;
    for (final title in titles) {
      if (!title.signed && _driverTitle(title.code)) {
        next = title;
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          const Text(
            'Подпись документов по титулам',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            next == null
                ? 'Все титулы водителя подписаны или ждут другие стороны'
                : 'Сейчас нужна подпись: ${next.code} · ${next.title}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: next == null ? AppColors.muted : AppColors.orange,
            ),
          ),
          const SizedBox(height: 12),
        ] else ...[
          const Text(
            'Титулы ЭТрН',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
        ],
        for (final title in titles) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: _bg(title),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border(title)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      title.code,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
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
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _statusLabel(title),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: title.signed
                                ? AppColors.navy
                                : (_isNext(title, next)
                                    ? AppColors.orange
                                    : AppColors.muted),
                          ),
                        ),
                        if (title.signed &&
                            (title.signedAt.isNotEmpty || title.signedBy.isNotEmpty)) ...[
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (title.signedAt.isNotEmpty) title.signedAt,
                              if (title.signedBy.isNotEmpty) title.signedBy,
                            ].join(' · '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                        if (_driverTitle(title.code)) ...[
                          const SizedBox(height: 2),
                          Text(
                            title.signed
                                ? 'Титул перевозчика подписан'
                                : 'Подписывает водитель (ПЭП)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    title.signed
                        ? Icons.check_circle_outline
                        : (_isNext(title, next)
                            ? Icons.edit_outlined
                            : Icons.hourglass_empty),
                    color: title.signed
                        ? AppColors.navy
                        : (_isNext(title, next) ? AppColors.orange : AppColors.muted),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _driverTitle(String code) => code == 'T2' || code == 'T4';

  bool _isNext(EtrnTitle title, EtrnTitle? next) =>
      next != null && title.code == next.code && !title.signed;

  Color _bg(EtrnTitle title) {
    if (title.signed) return const Color(0xFFD9E6F5);
    if (_driverTitle(title.code)) return const Color(0xFFFFF1E4);
    return AppColors.sand;
  }

  Color _border(EtrnTitle title) {
    if (title.signed) return const Color(0xFFB7C9DE);
    if (_driverTitle(title.code)) return const Color(0xFFF0C39A);
    return AppColors.line;
  }

  String _statusLabel(EtrnTitle title) {
    if (title.signed) return 'Подписан';
    if (_driverTitle(title.code)) return 'Ожидает подпись водителя';
    return 'Ожидает подпись другой стороны';
  }
}
