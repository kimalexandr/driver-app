import 'package:flutter/material.dart';

import '../models/notification_prefs.dart';
import '../theme/app_theme.dart';

class NotificationSettingsCard extends StatelessWidget {
  final NotificationPrefs prefs;
  final bool permissionGranted;
  final bool busy;
  final String? statusText;
  final ValueChanged<NotificationPrefs>? onChanged;
  final VoidCallback? onRequestPermission;
  final VoidCallback? onTest;

  const NotificationSettingsCard({
    super.key,
    required this.prefs,
    required this.permissionGranted,
    this.busy = false,
    this.statusText,
    this.onChanged,
    this.onRequestPermission,
    this.onTest,
  });

  String get _statusLine {
    if (!permissionGranted) {
      return 'Разрешите уведомления, чтобы получать сообщения о рейсах.';
    }
    if (!prefs.enabled) {
      return 'Уведомления выключены.';
    }
    final raw = (statusText ?? '').trim();
    // Технические строки RuStore водителю не показываем.
    if (raw.isEmpty ||
        raw.toLowerCase().contains('rustore') ||
        raw.toLowerCase().contains('токен')) {
      return 'Будут приходить выбранные события.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final switchesEnabled = permissionGranted && prefs.enabled && !busy;
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                  child: Icon(
                    permissionGranted && prefs.enabled
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusLine,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            if (!permissionGranted) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: busy ? null : onRequestPermission,
                  icon: const Icon(Icons.lock_open_outlined, size: 18),
                  label: const Text('Разрешить'),
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Включить'),
                value: prefs.enabled,
                onChanged: (busy || onChanged == null)
                    ? null
                    : (value) => onChanged!(prefs.copyWith(enabled: value)),
              ),
              if (prefs.enabled) ...[
                _toggle(
                  title: 'Новые рейсы',
                  value: prefs.newTrips,
                  enabled: switchesEnabled,
                  onChanged: (value) =>
                      onChanged?.call(prefs.copyWith(newTrips: value)),
                ),
                _toggle(
                  title: 'Смена статуса',
                  value: prefs.statusChanges,
                  enabled: switchesEnabled,
                  onChanged: (value) =>
                      onChanged?.call(prefs.copyWith(statusChanges: value)),
                ),
                _toggle(
                  title: 'Диспетчер',
                  value: prefs.dispatcher,
                  enabled: switchesEnabled,
                  onChanged: (value) =>
                      onChanged?.call(prefs.copyWith(dispatcher: value)),
                ),
                _toggle(
                  title: 'Сроки погрузки и выгрузки',
                  value: prefs.deadlines,
                  enabled: switchesEnabled,
                  onChanged: (value) =>
                      onChanged?.call(prefs.copyWith(deadlines: value)),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: busy ? null : onTest,
                    child: const Text('Проверить уведомление'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _toggle({
    required String title,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}
