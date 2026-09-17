import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/driver_profile.dart';
import '../theme/app_theme.dart';

List<String> splitRuName(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  return parts.toList();
}

Future<void> copyDocumentText(
  BuildContext context,
  String label,
  String value,
) async {
  final text = value.trim();
  if (text.isEmpty) return;
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  HapticFeedback.selectionClick();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label скопирован')),
  );
}

/// Компактная плитка: один тап открывает документ в sheet.
class DocumentOpenTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onOpen;

  const DocumentOpenTile({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onOpen();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showPassportSheet({
  required BuildContext context,
  required DriverPassport passport,
  required String holderName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.sand,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Паспорт',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Нажмите на карточку, чтобы скопировать номер',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              PassportDocumentCard(
                passport: passport,
                holderName: holderName,
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showLicenseSheet({
  required BuildContext context,
  required DriverLicense license,
  required String holderName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.sand,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Водительское удостоверение',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Свайп или «Повернуть» — категории на обороте',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                LicenseDocumentCard(
                  license: license,
                  holderName: holderName,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class PassportDocumentCard extends StatelessWidget {
  final DriverPassport passport;
  final String holderName;

  const PassportDocumentCard({
    super.key,
    required this.passport,
    this.holderName = '',
  });

  @override
  Widget build(BuildContext context) {
    final names = splitRuName(holderName);
    final last = names.isNotEmpty ? names.first : '';
    final first = names.length > 1 ? names[1] : '';
    final middle = names.length > 2 ? names.sublist(2).join(' ') : '';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => copyDocumentText(context, 'Паспорт', passport.seriesNumber),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF1F3), Color(0xFFFCE7EB)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0C2CB)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFBE123C).withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF9F1239), Color(0xFFBE123C)],
                    ),
                  ),
                  child: const Text(
                    'РОССИЙСКАЯ ФЕДЕРАЦИЯ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 82,
                        height: 104,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5D0D8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE8A4B0)),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 44,
                          color: Color(0xFF9F1239),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ПАСПОРТ',
                              style: TextStyle(
                                color: Color(0xFF9F1239),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _field('Фамилия', last),
                            _field('Имя', first),
                            _field('Отчество', middle),
                            _field('Серия и номер', passport.displaySeriesNumber),
                            _field('Дата выдачи', passport.issueDate),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  color: const Color(0xFFF8D7DE),
                  child: Text(
                    passport.hasContent
                        ? 'Нажмите, чтобы скопировать номер'
                        : 'Серия и номер не указаны',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9F1239), fontSize: 10),
          ),
          Text(
            value.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class LicenseDocumentCard extends StatefulWidget {
  final DriverLicense license;
  final String holderName;

  const LicenseDocumentCard({
    super.key,
    required this.license,
    this.holderName = '',
  });

  @override
  State<LicenseDocumentCard> createState() => _LicenseDocumentCardState();
}

class _LicenseDocumentCardState extends State<LicenseDocumentCard> {
  bool _back = false;

  void _flip() {
    HapticFeedback.selectionClick();
    setState(() => _back = !_back);
  }

  Future<void> _copy() {
    return copyDocumentText(context, 'ВУ', widget.license.number);
  }

  @override
  Widget build(BuildContext context) {
    final names = splitRuName(widget.holderName);
    final last = names.isNotEmpty ? names.first : '';
    final first = names.length > 1 ? names[1] : '';
    final middle = names.length > 2 ? names.sublist(2).join(' ') : '';
    final place = [
      widget.license.issuedBy,
      widget.license.issueCity,
    ].where((part) => part.isNotEmpty).join(', ');
    return Column(
      children: [
        GestureDetector(
          onHorizontalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0).abs() > 160) _flip();
          },
          onTap: _flip,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
                  child: child,
                ),
              );
            },
            child: _back
                ? _backFace()
                : _frontFace(last, first, middle, place),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _flip,
                icon: const Icon(Icons.flip, size: 18),
                label: Text(_back ? 'Лицевая' : 'Повернуть'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.license.hasContent ? _copy : null,
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Копировать'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _frontFace(String last, String first, String middle, String place) {
    return _plastic(
      key: const ValueKey('vu-front'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ВОДИТЕЛЬСКОЕ УДОСТОВЕРЕНИЕ',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0369A1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'RUS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _vuLine(
                  '1, 2',
                  [last, first, middle].where((part) => part.isNotEmpty).join(' '),
                ),
                _vuLine('4a–4b', widget.license.issueDate),
                _vuLine('5', widget.license.displayNumber),
                _vuLine('8', place),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 76,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: Color(0xFF0369A1),
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _backFace() {
    final categories = widget.license.openCategories;
    return _plastic(
      key: const ValueKey('vu-back'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ОТКРЫТЫЕ КАТЕГОРИИ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F766E),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          if (categories.isEmpty)
            const Text(
              'Категории не указаны',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final code in categories)
                  Container(
                    width: 48,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF0D9488),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        color: Color(0xFF0F766E),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 14),
          const Text(
            'Свайпните или нажмите «Лицевая», чтобы вернуться.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _plastic({required Key key, required Widget child}) {
    return Container(
      key: key,
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 168),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0FDFA), Color(0xFFE0F2FE)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF99F6E4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _vuLine(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        '$label  $value',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
