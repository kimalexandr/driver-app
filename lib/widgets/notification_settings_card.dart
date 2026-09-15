import 'package:flutter/material.dart';

import '../models/notification_prefs.dart';
import '../theme/app_theme.dart';

class NotificationSettingsCard extends StatelessWidget {
  final NotificationPrefs prefs;
  final bool permissionGranted;
  final bool busy;
  final ValueChanged<NotificationPrefs>? onChanged;
  final VoidCallback? onRequestPermission;
  final VoidCallback? onTest;

  const NotificationSettingsCard({
    super.key,
    required this.prefs,
    required this.permissionGranted,
    this.busy = false,
    this.onChanged,
    this.onRequestPermission,
    this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    final switchesEnabled = permissionGranted && prefs.enabled && !busy;
    // Material вместо DecoratedBox: иначе SwitchListTile падает в тестах
    // (ink splash рисуется на Material выше DecoratedBox с фоном).
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
                    permissionGranted
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Пуш-уведомления',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        permissionGranted
                            ? 'Разрешение ОС получено'
                            : 'Нужно разрешение системы',
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
              'Серверные пуши подключим позже; настройки сохраняются на этом телефоне.',
              style: TextStyle(color: AppColors.ink, height: 1.4, fontSize: 14),
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
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Включить уведомления'),
              value: prefs.enabled,
              onChanged: (!permissionGranted || busy || onChanged == null)
                  ? null
                  : (value) => onChanged!(prefs.copyWith(enabled: value)),
            ),
            _toggle(
              title: 'Новые рейсы',
              subtitle: 'Назначение заявки',
              value: prefs.newTrips,
              enabled: switchesEnabled,
              onChanged: (value) =>
                  onChanged?.call(prefs.copyWith(newTrips: value)),
            ),
            _toggle(
              title: 'Смена статуса',
              subtitle: 'Обновления по рейсу',
              value: prefs.statusChanges,
              enabled: switchesEnabled,
              onChanged: (value) =>
                  onChanged?.call(prefs.copyWith(statusChanges: value)),
            ),
            _toggle(
              title: 'Диспетчер',
              subtitle: 'Сообщения и важные звонки',
              value: prefs.dispatcher,
              enabled: switchesEnabled,
              onChanged: (value) =>
                  onChanged?.call(prefs.copyWith(dispatcher: value)),
            ),
            _toggle(
              title: 'Сроки погрузки и выгрузки',
              subtitle: 'Напоминания о окне времени',
              value: prefs.deadlines,
              enabled: switchesEnabled,
              onChanged: (value) =>
                  onChanged?.call(prefs.copyWith(deadlines: value)),
            ),
            if (permissionGranted) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: (busy || !prefs.enabled) ? null : onTest,
                  icon: const Icon(Icons.notification_add_outlined, size: 18),
                  label: const Text('Проверить'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toggle({
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}
