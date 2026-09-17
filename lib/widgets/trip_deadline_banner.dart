import 'dart:async';

import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../theme/app_theme.dart';

class TripDeadlineBanner extends StatefulWidget {
  final Trip trip;
  final bool compact;

  const TripDeadlineBanner({
    super.key,
    required this.trip,
    this.compact = false,
  });

  @override
  State<TripDeadlineBanner> createState() => _TripDeadlineBannerState();
}

class _TripDeadlineBannerState extends State<TripDeadlineBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deadline = tripDeadline(widget.trip);
    if (deadline == null) return const SizedBox.shrink();
    final color = switch (deadline.urgency) {
      DeadlineUrgency.late => AppColors.red,
      DeadlineUrgency.soon => AppColors.orange,
      DeadlineUrgency.ok => AppColors.green,
    };
    final bg = switch (deadline.urgency) {
      DeadlineUrgency.late => const Color(0xFFF8D9D5),
      DeadlineUrgency.soon => const Color(0xFFFFE8D2),
      DeadlineUrgency.ok => const Color(0xFFDCEFE3),
    };
    if (widget.compact) {
      return Text(
        deadline.headline,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            deadline.late
                ? Icons.warning_amber_rounded
                : Icons.timer_outlined,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              deadline.headline,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
