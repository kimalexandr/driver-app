import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/driver_profile.dart';
import '../theme/app_theme.dart';

List<String> splitRuName(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  return parts.toList();
}

Future<void> copyDocumentText(BuildContext context, String label, String value) async {
  final text = value.trim();
  if (text.isEmpty) return;
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label скопирован')),
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
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFF3E4E8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC9A0A8)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B1D2A).withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: const Color(0xFF8B2C3A),
                  child: const Text(
                    'РОССИЙСКАЯ ФЕДЕРАЦИЯ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 78,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7D3D8),
                          border: Border.all(color: const Color(0xFFB98992)),
                        ),
                        child: const Icon(Icons.person, size: 42, color: Color(0xFF8B2C3A)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ПАСПОРТ',
                              style: TextStyle(
                                color: Color(0xFF8B2C3A),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: const Color(0xFFE8D5DA),
                  child: Text(
                    passport.hasContent
                        ? 'Нажмите, чтобы скопировать номер'
                        : 'Серия и номер не указаны',
                    style: const TextStyle(color: AppColors.muted, fontSize: 11),
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
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8B2C3A), fontSize: 10)),
          Text(
            value.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
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

  void _flip() => setState(() => _back = !_back);

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
            if ((details.primaryVelocity ?? 0).abs() > 180) _flip();
          },
          onTap: _flip,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) {
              final rotate = Tween(begin: 1.0, end: 0.0).animate(animation);
              return AnimatedBuilder(
                animation: rotate,
                child: child,
                builder: (context, child) {
                  final angle = (1 - rotate.value) * 3.141592653589793;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(_back ? angle : -angle),
                    child: child,
                  );
                },
              );
            },
            child: _back
                ? _backFace(last, first, middle, place)
                : _frontFace(last, first, middle, place),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _flip,
                icon: const Icon(Icons.rotate_right, size: 18),
                label: const Text('Повернуть'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.license.hasContent ? _copy : null,
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Копировать'),
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
            child: FittedBox(
              alignment: Alignment.topLeft,
              fit: BoxFit.scaleDown,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E4B9C),
                        borderRadius: BorderRadius.circular(4),
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
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'ВОДИТЕЛЬСКОЕ УДОСТОВЕРЕНИЕ',
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _vuLine('1, 2', [last, first, middle].where((part) => part.isNotEmpty).join(' ')),
                _vuLine('4a–4b', widget.license.issueDate),
                _vuLine('5', widget.license.displayNumber),
                _vuLine('8', place),
              ],
            ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 72,
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0xFFE8DDE1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFC9B4BA)),
            ),
            child: const Icon(Icons.badge_outlined, color: Color(0xFF8B3A5A), size: 36),
          ),
        ],
      ),
    );
  }

  Widget _backFace(String last, String first, String middle, String place) {
    return _plastic(
      key: const ValueKey('vu-back'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ОБОРОТ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8B3A5A),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          _vuLine('Номер', widget.license.displayNumber),
          _vuLine('Выдано', widget.license.issueDate),
          _vuLine('Кем', place),
          _vuLine('Владелец', [last, first, middle].where((part) => part.isNotEmpty).join(' ')),
          const Spacer(),
          const Text(
            'Смахните или нажмите «Повернуть»',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _plastic({required Key key, required Widget child}) {
    return Container(
      key: key,
      width: double.infinity,
      height: 176,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7F4), Color(0xFFF3D5DC)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7A8B4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B3A5A).withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _vuLine(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppColors.navy, fontSize: 13, height: 1.25),
          children: [
            TextSpan(
              text: '$label  ',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
