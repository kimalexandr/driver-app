import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MaxDigitalIdCard extends StatelessWidget {
  final bool busy;
  final VoidCallback? onOpenMax;
  final VoidCallback? onGuide;

  const MaxDigitalIdCard({
    super.key,
    this.busy = false,
    this.onOpenMax,
    this.onGuide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_2_outlined,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Цифровой ID MAX',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'QR прав и СТС — в мессенджере MAX',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onOpenMax,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Открыть в MAX'),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onGuide,
                child: const Text('Как подключить'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
