import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MaxDigitalIdCard extends StatelessWidget {
  final bool linked;
  final bool busy;
  final VoidCallback? onOpenMax;
  final VoidCallback? onMarkLinked;
  final VoidCallback? onUnlink;
  final VoidCallback? onGuide;

  const MaxDigitalIdCard({
    super.key,
    required this.linked,
    this.busy = false,
    this.onOpenMax,
    this.onMarkLinked,
    this.onUnlink,
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
        border: Border.all(
          color: linked ? AppColors.green.withValues(alpha: 0.35) : AppColors.line,
        ),
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
                  color: linked
                      ? AppColors.green.withValues(alpha: 0.12)
                      : AppColors.navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  linked ? Icons.verified_user_outlined : Icons.qr_code_2_outlined,
                  color: linked ? AppColors.green : AppColors.navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Цифровой ID MAX',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      linked
                          ? 'Отмечен на этом телефоне · QR прав и СТС — в MAX'
                          : 'Права и СТС через мессенджер MAX (Госуслуги)',
                      style: const TextStyle(
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
          const SizedBox(height: 12),
          const Text(
            'QR-код документов формируется только в MAX. Из нашего приложения '
            'можно быстро открыть Цифровой ID и показать его инспектору или на КПП.',
            style: TextStyle(color: AppColors.ink, height: 1.4, fontSize: 14),
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (!linked)
                  TextButton(
                    onPressed: onMarkLinked,
                    child: const Text('У меня уже есть Цифровой ID'),
                  )
                else
                  TextButton(
                    onPressed: onUnlink,
                    child: const Text('Снять отметку'),
                  ),
                TextButton(
                  onPressed: onGuide,
                  child: const Text('Как подключить'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
