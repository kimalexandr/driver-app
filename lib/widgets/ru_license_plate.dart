import 'package:flutter/material.dart';

import '../models/license_plate.dart';

enum RuLicensePlateSize { compact, regular }

class RuLicensePlateBadge extends StatelessWidget {
  final String number;
  final RuLicensePlateSize size;

  const RuLicensePlateBadge({
    super.key,
    required this.number,
    this.size = RuLicensePlateSize.regular,
  });

  @override
  Widget build(BuildContext context) {
    final plate = parseRuLicensePlate(number);
    if (number.trim().isEmpty) return const SizedBox.shrink();

    final compact = size == RuLicensePlateSize.compact;
    final height = compact ? 32.0 : 48.0;
    final radius = compact ? 4.0 : 6.0;
    final letterSize = compact ? 15.0 : 22.0;
    final digitSize = compact ? 18.0 : 26.0;
    final regionSize = compact ? 14.0 : 20.0;
    final rusSize = compact ? 6.5 : 8.0;
    final flagW = compact ? 12.0 : 16.0;
    final flagH = compact ? 7.0 : 10.0;
    final stripW = compact
        ? (plate.parsed && plate.region.length > 2 ? 36.0 : 32.0)
        : (plate.parsed && plate.region.length > 2 ? 52.0 : 46.0);

    return Semantics(
      label: plate.parsed ? plate.compact : plate.raw,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F4),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: const Color(0xFF1A1A1A), width: compact ? 1.6 : 2.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: compact ? 4 : 8,
              offset: Offset(0, compact ? 1 : 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(compact ? 7 : 10, 0, compact ? 6 : 8, 0),
              child: plate.parsed
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _glyph(plate.letter, letterSize),
                        SizedBox(width: compact ? 4 : 7),
                        _glyph(plate.digits, digitSize),
                        SizedBox(width: compact ? 4 : 7),
                        _glyph(plate.series, letterSize),
                      ],
                    )
                  : _glyph(plate.raw.toUpperCase(), letterSize),
            ),
            Container(
              width: stripW,
              decoration: BoxDecoration(
                color: const Color(0xFF1E4B9C),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(radius - 1),
                  bottomRight: Radius.circular(radius - 1),
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RusFlag(width: flagW, height: flagH),
                  SizedBox(height: compact ? 1 : 2),
                  Text(
                    'RUS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: rusSize,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: 0.4,
                    ),
                  ),
                  if (plate.parsed) ...[
                    SizedBox(height: compact ? 1 : 2),
                    Text(
                      plate.region,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: regionSize,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glyph(String text, double fontSize) {
    return Text(
      text,
      style: TextStyle(
        color: const Color(0xFF111111),
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        height: 1,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _RusFlag extends StatelessWidget {
  final double width;
  final double height;

  const _RusFlag({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        children: [
          Expanded(child: Container(color: Colors.white)),
          Expanded(child: Container(color: const Color(0xFF0039A6))),
          Expanded(child: Container(color: const Color(0xFFD52B1E))),
        ],
      ),
    );
  }
}
