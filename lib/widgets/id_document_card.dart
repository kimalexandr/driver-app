import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/driver_profile.dart';
import '../theme/app_theme.dart';

class PassportDocumentCard extends StatelessWidget {
  final DriverPassport passport;

  const PassportDocumentCard({super.key, required this.passport});

  @override
  Widget build(BuildContext context) {
    return _IdDocumentCard(
      kindLabel: 'Паспорт',
      countryLabel: 'РФ',
      number: passport.hasContent ? passport.displaySeriesNumber : '',
      numberCaption: 'Серия и номер',
      emptyHint: 'Серия и номер не указаны',
      lines: [
        if (passport.issueDate.isNotEmpty) _DocLine('Выдан', passport.issueDate),
      ],
      colors: const [Color(0xFF6B1D2A), Color(0xFF3D1018)],
      watermark: Icons.menu_book_outlined,
      copyValue: passport.seriesNumber,
    );
  }
}

class LicenseDocumentCard extends StatelessWidget {
  final DriverLicense license;

  const LicenseDocumentCard({super.key, required this.license});

  @override
  Widget build(BuildContext context) {
    final place = [
      license.issuedBy,
      license.issueCity,
    ].where((part) => part.isNotEmpty).join(', ');
    return _IdDocumentCard(
      kindLabel: 'Водительское удостоверение',
      countryLabel: 'ВУ',
      number: license.hasContent ? license.displayNumber : '',
      numberCaption: 'Номер',
      emptyHint: 'Номер не указан',
      lines: [
        if (license.issueDate.isNotEmpty) _DocLine('Выдано', license.issueDate),
        if (place.isNotEmpty) _DocLine('Кем', place),
      ],
      colors: const [Color(0xFF9A3F5C), Color(0xFF5C2438)],
      accent: AppColors.orange,
      watermark: Icons.badge_outlined,
      copyValue: license.number,
    );
  }
}

class _DocLine {
  final String label;
  final String value;

  const _DocLine(this.label, this.value);
}

class _IdDocumentCard extends StatelessWidget {
  final String kindLabel;
  final String countryLabel;
  final String number;
  final String numberCaption;
  final String emptyHint;
  final List<_DocLine> lines;
  final List<Color> colors;
  final Color? accent;
  final IconData watermark;
  final String copyValue;

  const _IdDocumentCard({
    required this.kindLabel,
    required this.countryLabel,
    required this.number,
    required this.numberCaption,
    required this.emptyHint,
    required this.lines,
    required this.colors,
    required this.watermark,
    required this.copyValue,
    this.accent,
  });

  Future<void> _copy(BuildContext context) async {
    final value = copyValue.trim();
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$kindLabel скопирован')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filled = number.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: filled ? () => _copy(context) : null,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  bottom: -22,
                  child: Icon(
                    watermark,
                    size: 140,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                if (accent != null)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 5, color: accent),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              countryLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              kindLabel.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          Icon(
                            filled ? Icons.copy_outlined : Icons.hourglass_empty,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          filled ? number : emptyHint,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: filled ? 1 : 0.55),
                            fontSize: filled ? 26 : 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: filled ? 1.4 : 0,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        numberCaption,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                      if (lines.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 20,
                          runSpacing: 8,
                          children: [
                            for (final line in lines)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.label,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    line.value,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
