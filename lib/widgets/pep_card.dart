import 'package:flutter/material.dart';

import '../models/external_auth.dart';
import '../models/pep.dart';
import '../theme/app_theme.dart';

class PepCard extends StatelessWidget {
  final PepRecord? record;
  final Set<AuthProviderKind> linked;
  final bool busy;
  final VoidCallback? onIssue;
  final VoidCallback? onRevoke;
  final VoidCallback? onGosuslugi;
  final VoidCallback? onGoskey;

  const PepCard({
    super.key,
    required this.record,
    required this.linked,
    this.busy = false,
    this.onIssue,
    this.onRevoke,
    this.onGosuslugi,
    this.onGoskey,
  });

  @override
  Widget build(BuildContext context) {
    final issued = record != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.ink],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ПЭП',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  issued ? 'Подпись на этом телефоне' : 'Подпись ещё не выпущена',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                issued ? Icons.verified_user : Icons.draw_outlined,
                color: issued ? const Color(0xFF8FCB9B) : Colors.white54,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            issued ? 'Ключ ${record!.kid}' : 'Простая электронная подпись',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            issued
                ? 'Выпущена ${record!.issuedLabel} · ${record!.issuedVia.title}'
                : 'Ключ создаётся на устройстве и не уходит в облако. Им можно подтверждать приём и сдачу груза.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Телефон', linked.contains(AuthProviderKind.sms)),
              _chip('Госуслуги', linked.contains(AuthProviderKind.gosuslugi)),
              _chip('Госключ', linked.contains(AuthProviderKind.goskey)),
            ],
          ),
          const SizedBox(height: 16),
          if (issued)
            OutlinedButton(
              onPressed: busy ? null : onRevoke,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                minimumSize: const Size(double.infinity, 46),
              ),
              child: Text(busy ? 'Удаление...' : 'Отозвать подпись'),
            )
          else
            ElevatedButton(
              onPressed: busy ? null : onIssue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
              ),
              child: Text(busy ? 'Выпуск...' : 'Выпустить ПЭП'),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onGosuslugi,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    minimumSize: const Size(0, 44),
                  ),
                  child: const Text('Госуслуги'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onGoskey,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    minimumSize: const Size(0, 44),
                  ),
                  child: const Text('Госключ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool on) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: on ? AppColors.orange : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        on ? '$label · связан' : label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: on ? 1 : 0.7),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
