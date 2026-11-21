import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/explore_lanka_theme.dart';
import '../../attractions/data/attraction.dart';
import '../../attractions/presentation/attraction_card.dart';
import '../data/travel_day.dart';
import 'day_route_map_screen.dart';

class DayItineraryScreen extends StatefulWidget {
  const DayItineraryScreen({
    super.key,
    required this.days,
    required this.tripDays,
    required this.initialDay,
    required this.onOpen,
  });

  final List<TravelDay> days;
  final int tripDays;
  final int initialDay;
  final ValueChanged<Attraction> onOpen;

  @override
  State<DayItineraryScreen> createState() => _DayItineraryScreenState();
}

class _DayItineraryScreenState extends State<DayItineraryScreen> {
  static const _tabWidth = 112.0;
  late int _selected = widget.initialDay;
  late final _tabs = ScrollController(
    initialScrollOffset: math.max(0, _selected - 2) * _tabWidth,
  );
  final _timeline = ScrollController();

  @override
  void dispose() {
    _tabs.dispose();
    _timeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = _selected <= widget.days.length
        ? widget.days[_selected - 1]
        : TravelDay(_selected, const []);
    final entries = _schedule(day.stops);
    final mappedStops = day.stops.where(_hasCoordinates).toList();
    return Theme(
      data: buildTripPlanningTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Itinerary',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 58,
                  child: ListView.builder(
                    controller: _tabs,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemExtent: _tabWidth,
                    itemCount: widget.tripDays,
                    itemBuilder: (context, index) {
                      final number = index + 1;
                      final selected = number == _selected;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Semantics(
                          selected: selected,
                          child: TextButton(
                            onPressed: () {
                              setState(() => _selected = number);
                              _timeline.jumpTo(0);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: selected
                                  ? const Color(0xFF301407)
                                  : const Color(0xFFECECEC),
                              backgroundColor: selected
                                  ? exploreOrange
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: Text(
                              'Day $number',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: _timeline,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      Text(
                        entries.isEmpty ? 'Free day' : day.theme,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (entries.isEmpty)
                        const Text('No attractions scheduled for this day.'),
                      for (final (index, entry) in entries.indexed)
                        _TimelineRow(
                          number: index + 1,
                          last: index == entries.length - 1,
                          entry: entry,
                          onOpen: widget.onOpen,
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'Daily summary',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Attractions: ${day.stops.length}'),
                      if (entries.length > day.stops.length)
                        const Text('Includes a suggested lunch break'),
                      const SizedBox(height: 20),
                      if (mappedStops.isNotEmpty)
                        FilledButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => DayRouteMapScreen(
                                day: day,
                                stops: mappedStops,
                                onOpen: widget.onOpen,
                              ),
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('View Route on Map'),
                        ),
                      if (entries.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Suggested schedule. Check travel times and opening hours before visiting.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFCCCCCC)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

typedef _Entry = ({int minute, Attraction? stop});

List<_Entry> _schedule(List<Attraction> stops) {
  const noon = 12 * 60;
  var minute = 8 * 60 + 30;
  var lunchAdded = false;
  final entries = <_Entry>[];
  for (final (index, stop) in stops.indexed) {
    final duration = stop.estimatedVisitDuration > 0
        ? stop.estimatedVisitDuration
        : 90;
    if (!lunchAdded &&
        index > 0 &&
        (minute >= noon || (minute >= 11 * 60 && minute + duration >= noon))) {
      final lunchStart = math.max(minute, noon);
      entries.add((minute: lunchStart, stop: null));
      minute = lunchStart + 60;
      lunchAdded = true;
    }
    entries.add((minute: minute, stop: stop));
    minute += duration + 30;
  }
  return entries;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.number,
    required this.last,
    required this.entry,
    required this.onOpen,
  });

  final int number;
  final bool last;
  final _Entry entry;
  final ValueChanged<Attraction> onOpen;

  @override
  Widget build(BuildContext context) {
    final stop = entry.stop;
    final time = entry.minute < 24 * 60
        ? MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay(hour: entry.minute ~/ 60, minute: entry.minute % 60),
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          )
        : 'Time to confirm';
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(36, 0, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$time — ${stop?.name ?? 'Lunch break'}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            stop == null
                ? 'Suggested meal and rest period'
                : [
                    if (stop.visitDuration case final duration?)
                      'Estimated visit: $duration',
                    'Entry · ${stop.admissionLabel}',
                  ].join('  •  '),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (stop != null) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: AttractionPhoto(place: stop),
              ),
            ),
          ],
        ],
      ),
    );
    return Stack(
      children: [
        if (!last)
          const Positioned(
            top: 27,
            bottom: 4,
            left: 9,
            child: SizedBox(
              width: 2,
              child: ColoredBox(color: Color(0xFF343434)),
            ),
          ),
        Positioned(
          top: 0,
          left: 0,
          width: 22,
          child: Text(
            '$number',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (stop == null)
          content
        else
          InkWell(onTap: () => onOpen(stop), child: content),
      ],
    );
  }
}

bool _hasCoordinates(Attraction stop) =>
    stop.latitude.isFinite &&
    stop.latitude.abs() <= 90 &&
    stop.longitude.isFinite &&
    stop.longitude.abs() <= 180 &&
    (stop.latitude != 0 || stop.longitude != 0);
