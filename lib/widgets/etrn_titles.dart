import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../theme/app_theme.dart';

class EtrnTitlesBlock extends StatelessWidget {
  final List<EtrnTitle> titles;
  final List<EpdDocument> documents;
  final bool compact;

  const EtrnTitlesBlock({
    super.key,
    this.titles = const [],
    this.documents = const [],
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final docs = documents.isNotEmpty
        ? documents
        : _docsFromTitles(titles);
    if (docs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          const Text(
            'ЭТрН и договоры',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _summary(docs),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < docs.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _DocumentSection(document: docs[i], compact: compact),
        ],
      ],
    );
  }

  List<EpdDocument> _docsFromTitles(List<EtrnTitle> items) {
    if (items.isEmpty) return const [];
    final grouped = <String, List<EtrnTitle>>{};
    for (final title in items) {
      grouped.putIfAbsent(title.kind, () => []).add(title);
    }
    return grouped.entries
        .map(
          (entry) => EpdDocument(
            kind: entry.key,
            kindLabel: entry.value.first.resolvedKindLabel,
            number: entry.value.first.documentNumber,
            titles: entry.value,
          ),
        )
        .toList();
  }

  String _summary(List<EpdDocument> docs) {
    final pending = docs
        .expand((doc) => doc.titles)
        .where((title) => !title.signed && _driverTitle(title))
        .toList();
    if (pending.isEmpty) {
      return 'Все титулы водителя подписаны или ждут другие стороны';
    }
    final next = pending.first;
    return 'Сейчас нужна подпись: ${next.code} · ${next.title}';
  }
}

class _DocumentSection extends StatelessWidget {
  final EpdDocument document;
  final bool compact;

  const _DocumentSection({
    required this.document,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    EtrnTitle? next;
    for (final title in document.titles) {
      if (!title.signed && _driverTitle(title)) {
        next = title;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                document.resolvedKindLabel,
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ),
            if (document.number.isNotEmpty)
              Text(
                '№ ${document.number}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
          ],
        ),
        if (document.documentDate.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            document.documentDate,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
        const SizedBox(height: 8),
        if (document.titles.isEmpty)
          const Text(
            'Титулы пока не загружены',
            style: TextStyle(color: AppColors.muted),
          )
        else
          for (final title in document.titles)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TitleRow(title: title, next: next),
            ),
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  final EtrnTitle title;
  final EtrnTitle? next;

  const _TitleRow({required this.title, required this.next});

  @override
  Widget build(BuildContext context) {
    final isNext = next != null &&
        title.code == next!.code &&
        title.kind == next!.kind &&
        !title.signed;

    return Container(
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
                        : (isNext ? AppColors.orange : AppColors.muted),
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
                if (_driverTitle(title)) ...[
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
                : (isNext ? Icons.edit_outlined : Icons.hourglass_empty),
            color: title.signed
                ? AppColors.navy
                : (isNext ? AppColors.orange : AppColors.muted),
            size: 22,
          ),
        ],
      ),
    );
  }

  Color _bg(EtrnTitle title) {
    if (title.signed) return const Color(0xFFD9E6F5);
    if (_driverTitle(title)) return const Color(0xFFFFF1E4);
    return AppColors.sand;
  }

  Color _border(EtrnTitle title) {
    if (title.signed) return const Color(0xFFB7C9DE);
    if (_driverTitle(title)) return const Color(0xFFF0C39A);
    return AppColors.line;
  }

  String _statusLabel(EtrnTitle title) {
    if (title.signed) return 'Подписан';
    if (_driverTitle(title)) return 'Ожидает подпись водителя';
    return 'Ожидает подпись другой стороны';
  }
}

bool _driverTitle(EtrnTitle title) {
  if (title.kind == 'forwarding_order' || title.kind == 'forwarding_receipt') {
    return title.code == 'T1' || title.code == 'T2';
  }
  return title.code == 'T2' || title.code == 'T4';
}
