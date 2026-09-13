import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../theme/app_theme.dart';

typedef OpenPlace = void Function({
  required String address,
  double? lat,
  double? lng,
});

class TripStatusThread extends StatelessWidget {
  final Trip trip;
  final OpenPlace onOpenPlace;

  const TripStatusThread({
    super.key,
    required this.trip,
    required this.onOpenPlace,
  });

  @override
  Widget build(BuildContext context) {
    final steps = tripThreadSteps(trip);
    final km = formatDistanceKm(tripDistanceKm(trip));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ход рейса',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
              if (km.isNotEmpty)
                Text(
                  km,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < steps.length; i++)
            _StepTile(
              step: steps[i],
              isLast: i == steps.length - 1,
              onOpenPlace: onOpenPlace,
            ),
        ],
      ),
    );
  }
}

enum ThreadPhase { done, current, upcoming }

class ThreadStep {
  final String id;
  final String title;
  final ThreadPhase phase;
  final String city;
  final String company;
  final String address;
  final String when;
  final String window;
  final String comment;
  final String hint;
  final double? lat;
  final double? lng;

  const ThreadStep({
    required this.id,
    required this.title,
    required this.phase,
    this.city = '',
    this.company = '',
    this.address = '',
    this.when = '',
    this.window = '',
    this.comment = '',
    this.hint = '',
    this.lat,
    this.lng,
  });

  bool get hasPlace =>
      city.isNotEmpty || address.isNotEmpty || lat != null || lng != null;
}

List<ThreadStep> tripThreadSteps(Trip trip) {
  final currentId = _currentStepId(trip);
  ThreadPhase phaseOf(String id, List<String> order) {
    if (trip.isCompleted) return ThreadPhase.done;
    final currentIndex = order.indexOf(currentId);
    final index = order.indexOf(id);
    if (index < 0) return ThreadPhase.upcoming;
    if (index < currentIndex) return ThreadPhase.done;
    if (index == currentIndex) return ThreadPhase.current;
    return ThreadPhase.upcoming;
  }

  if (trip.stops.isNotEmpty) {
    return _stepsFromStops(trip, currentId, phaseOf);
  }

  const order = ['assigned', 'load', 'transit', 'unload', 'delivered'];
  final deadline = tripDeadline(trip);
  return [
    ThreadStep(
      id: 'assigned',
      title: 'Назначен',
      phase: phaseOf('assigned', order),
      hint: 'Рейс выдан водителю',
    ),
    ThreadStep(
      id: 'load',
      title: 'Погрузка',
      phase: phaseOf('load', order),
      city: trip.from,
      company: trip.startCompany,
      address: _extraAddress(trip.startAddress, trip.from),
      when: trip.dateStart,
      window: trip.loadWindowLabel,
      comment: trip.startComment,
      hint: phaseOf('load', order) == ThreadPhase.current
          ? (deadline?.headline ?? 'Сейчас нужно быть на погрузке')
          : '',
      lat: trip.startLat,
      lng: trip.startLng,
    ),
    ThreadStep(
      id: 'transit',
      title: 'В пути',
      phase: phaseOf('transit', order),
      hint: _transitHint(trip, phaseOf('transit', order)),
    ),
    ThreadStep(
      id: 'unload',
      title: 'Выгрузка',
      phase: phaseOf('unload', order),
      city: trip.to,
      company: trip.finishCompany,
      address: _extraAddress(trip.finishAddress, trip.to),
      when: trip.dateEnd,
      window: trip.unloadWindowLabel,
      comment: trip.finishComment,
      hint: phaseOf('unload', order) == ThreadPhase.current
          ? (deadline?.headline ?? 'Следующая точка — выгрузка')
          : '',
      lat: trip.finishLat,
      lng: trip.finishLng,
    ),
    ThreadStep(
      id: 'delivered',
      title: 'Доставлено',
      phase: trip.isCompleted ? ThreadPhase.done : ThreadPhase.upcoming,
      hint: trip.isCompleted ? 'Рейс закрыт' : '',
    ),
  ];
}

List<ThreadStep> _stepsFromStops(
  Trip trip,
  String currentId,
  ThreadPhase Function(String id, List<String> order) phaseOf,
) {
  final ids = <String>['assigned'];
  final loadIndexes = <int>[];
  for (var i = 0; i < trip.stops.length; i++) {
    ids.add('stop_$i');
    if (trip.stops[i].isLoad) loadIndexes.add(i);
  }
  final lastLoad = loadIndexes.isEmpty ? -1 : loadIndexes.last;
  if (lastLoad >= 0 && lastLoad < trip.stops.length - 1) {
    ids.insert(ids.indexOf('stop_$lastLoad') + 1, 'transit');
  }
  ids.add('delivered');

  final deadline = tripDeadline(trip);
  final steps = <ThreadStep>[
    ThreadStep(
      id: 'assigned',
      title: 'Назначен',
      phase: phaseOf('assigned', ids),
      hint: 'Рейс выдан водителю',
    ),
  ];

  for (var i = 0; i < trip.stops.length; i++) {
    final stop = trip.stops[i];
    final id = 'stop_$i';
    final phase = phaseOf(id, ids);
    steps.add(_stepFromStop(trip, stop, id, phase, deadline));
    if (i == lastLoad && ids.contains('transit')) {
      steps.add(
        ThreadStep(
          id: 'transit',
          title: 'В пути',
          phase: phaseOf('transit', ids),
          hint: _transitHint(trip, phaseOf('transit', ids)),
        ),
      );
    }
  }

  steps.add(
    ThreadStep(
      id: 'delivered',
      title: 'Доставлено',
      phase: trip.isCompleted ? ThreadPhase.done : ThreadPhase.upcoming,
      hint: trip.isCompleted ? 'Рейс закрыт' : '',
    ),
  );
  return steps;
}

ThreadStep _stepFromStop(
  Trip trip,
  TripStop stop,
  String id,
  ThreadPhase phase,
  TripDeadline? deadline,
) {
  final kind = stop.isLoad ? 'Погрузка' : (stop.isUnload ? 'Выгрузка' : stop.type);
  final city = stop.title.isNotEmpty
      ? stop.title
      : (stop.isLoad
          ? trip.from
          : (stop.isUnload ? trip.to : stop.address));
  final company = stop.isLoad
      ? trip.startCompany
      : (stop.isUnload ? trip.finishCompany : '');
  final fallbackComment = stop.isLoad
      ? trip.startComment
      : (stop.isUnload ? trip.finishComment : '');
  final comment = [
    if (stop.queue.isNotEmpty) 'очередь ${stop.queue}',
    if (stop.gate.number.isNotEmpty) 'ворота ${stop.gate.number}',
    if (stop.gate.comment.isNotEmpty) stop.gate.comment,
    if (stop.cargoName.isNotEmpty && !_same(stop.cargoName, trip.cargo))
      stop.cargoName,
    if (stop.comment.isNotEmpty)
      stop.comment
    else if (fallbackComment.isNotEmpty)
      fallbackComment,
  ].join(' · ');
  final when = stop.plannedAt.isNotEmpty
      ? stop.plannedAt
      : (stop.isLoad ? trip.dateStart : trip.dateEnd);
  final window = stop.isLoad
      ? trip.loadWindowLabel
      : (stop.isUnload ? trip.unloadWindowLabel : '');
  String hint = '';
  if (phase == ThreadPhase.current) {
    hint = deadline?.headline ??
        (stop.isLoad ? 'Сейчас нужно быть на погрузке' : 'Следующая точка');
  }
  return ThreadStep(
    id: id,
    title: kind.isEmpty ? 'Точка' : kind,
    phase: phase,
    city: city,
    company: company,
    address: stop.address.isNotEmpty && !_same(stop.address, city)
        ? stop.address
        : '',
    when: when,
    window: window,
    comment: comment,
    hint: hint,
    lat: stop.lat,
    lng: stop.lng,
  );
}

String _currentStepId(Trip trip) {
  if (trip.isCompleted) return 'delivered';
  if (trip.canStart) {
    if (trip.stops.isNotEmpty) {
      final index = trip.stops.indexWhere((stop) => stop.isLoad);
      return 'stop_${index < 0 ? 0 : index}';
    }
    return 'load';
  }
  if (trip.isInTransit && trip.stops.isNotEmpty) {
    final lastLoad = trip.stops.lastIndexWhere((stop) => stop.isLoad);
    if (lastLoad >= 0 && lastLoad < trip.stops.length - 1) return 'transit';
    final unload = trip.stops.lastIndexWhere((stop) => stop.isUnload);
    return 'stop_${unload >= 0 ? unload : trip.stops.length - 1}';
  }
  if (trip.isInTransit) return 'transit';
  if (trip.stops.isNotEmpty) {
    final index = trip.stops.lastIndexWhere((stop) => stop.isUnload);
    return index >= 0 ? 'stop_$index' : 'stop_${trip.stops.length - 1}';
  }
  return 'unload';
}

String _transitHint(Trip trip, ThreadPhase phase) {
  final km = formatDistanceKm(tripDistanceKm(trip));
  if (phase == ThreadPhase.current) {
    final to = trip.to.isNotEmpty ? trip.to : 'выгрузке';
    if (km.isNotEmpty) return '$km до $to';
    return 'Сейчас едете на выгрузку';
  }
  if (km.isNotEmpty) return '$km между пунктами';
  return '';
}

String _extraAddress(String address, String city) {
  if (address.isEmpty || _same(address, city)) return '';
  return address;
}

bool _same(String a, String b) {
  final left = a.trim().toLowerCase();
  final right = b.trim().toLowerCase();
  return left.isNotEmpty && left == right;
}

class _StepTile extends StatelessWidget {
  final ThreadStep step;
  final bool isLast;
  final OpenPlace onOpenPlace;

  const _StepTile({
    required this.step,
    required this.isLast,
    required this.onOpenPlace,
  });

  @override
  Widget build(BuildContext context) {
    final current = step.phase == ThreadPhase.current;
    final done = step.phase == ThreadPhase.done;
    final color = current
        ? AppColors.orange
        : (done ? AppColors.green : AppColors.line);
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  step.title,
                  style: TextStyle(
                    fontSize: current ? 16 : 15,
                    fontWeight: current ? FontWeight.w800 : FontWeight.w700,
                    color: current ? AppColors.navy : AppColors.ink,
                  ),
                ),
              ),
              if (current)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8D2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Сейчас',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          if (step.city.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              step.city,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ],
          if (step.company.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(step.company, style: const TextStyle(color: AppColors.ink)),
          ],
          if (step.address.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              step.address,
              style: const TextStyle(
                color: AppColors.ink,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
          if (step.when.isNotEmpty || step.window.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (step.when.isNotEmpty) step.when,
                if (step.window.isNotEmpty) 'окно ${step.window}',
              ].join(' · '),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: current ? AppColors.orange : AppColors.muted,
              ),
            ),
          ],
          if (step.hint.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              step.hint,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: step.hint.startsWith('Опаздываете')
                    ? AppColors.red
                    : (current ? AppColors.orange : AppColors.muted),
              ),
            ),
          ],
          if (step.comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              step.comment,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: current ? 16 : 12,
                  height: current ? 16 : 12,
                  margin: EdgeInsets.only(top: current ? 2 : 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done || current ? color : Colors.white,
                    border: Border.all(color: color, width: current ? 4 : 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: done ? AppColors.green.withValues(alpha: 0.45) : AppColors.line,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: current
                ? Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6EC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _maybeTappable(body),
                  )
                : _maybeTappable(body),
          ),
        ],
      ),
    );
  }

  Widget _maybeTappable(Widget child) {
    if (!step.hasPlace) return child;
    return InkWell(
      onTap: () => onOpenPlace(
        address: step.address.isNotEmpty ? step.address : step.city,
        lat: step.lat,
        lng: step.lng,
      ),
      borderRadius: BorderRadius.circular(14),
      child: child,
    );
  }
}
