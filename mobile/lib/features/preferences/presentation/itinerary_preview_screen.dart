import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/explore_lanka_theme.dart';
import '../../attractions/data/attraction.dart';
import '../../auth/data/auth_repository.dart';
import '../data/travel_day.dart';
import '../data/trip_planning_repository.dart';
import 'day_itinerary_screen.dart';

const _routeNote =
    'Suggested order based on straight-line distance. Check travel times and opening hours before leaving.';

class ItineraryPreviewScreen extends StatelessWidget {
  const ItineraryPreviewScreen({
    super.key,
    required this.preferences,
    required this.stops,
    required this.onOpen,
    this.onSave,
  });

  final TripPreferences preferences;
  final List<Attraction> stops;
  final ValueChanged<Attraction> onOpen;
  final Future<void> Function()? onSave;

  void _showDays(BuildContext context, List<TravelDay> days, int initialDay) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DayItineraryScreen(
          days: days,
          tripDays: preferences.tripDays,
          initialDay: initialDay,
          onOpen: onOpen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plannedDays = math.min(preferences.tripDays, stops.length);
    final days = [
      for (var index = 0; index < plannedDays; index++)
        TravelDay(
          index + 1,
          stops.sublist(
            (index * stops.length / plannedDays).ceil(),
            ((index + 1) * stops.length / plannedDays).ceil(),
          ),
        ),
    ];
    final freeDays = preferences.tripDays - plannedDays;
    return Theme(
      data: buildTripPlanningTheme(),
      child: Scaffold(
        appBar: AppBar(
          actions: [if (onSave case final save?) _SaveTripButton(onSave: save)],
          title: const Text(
            'Your Sri Lanka Adventure',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: _ItineraryList(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final value in [
                  '${preferences.tripDays} ${preferences.tripDays == 1 ? 'Day' : 'Days'}',
                  preferences.transport,
                  preferences.interests.join(' + '),
                ])
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF292929),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(value),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  'assets/images/ella.jpg',
                  fit: BoxFit.cover,
                  semanticLabel:
                      'Illustration of the Sri Lankan highlands near Ella',
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TripStat(preferences.tripDays, 'Days'),
                _TripStat(stops.length, 'Attractions'),
                _TripStat(preferences.interests.length, 'Interests'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Your travel plan',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
            const SizedBox(height: 6),
            for (final day in days)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_outlined),
                title: Text(
                  day.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(day.stops.map((stop) => stop.name).join(' · ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDays(context, days, day.number),
              ),
            if (freeDays > 0)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available_outlined),
                onTap: () => _showDays(context, days, plannedDays + 1),
                trailing: const Icon(Icons.chevron_right),
                title: Text(
                  freeDays == 1
                      ? 'Day ${preferences.tripDays} · Free day'
                      : 'Days ${plannedDays + 1}–${preferences.tripDays} · Free days',
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: days.isEmpty
                  ? null
                  : () => _showDays(context, days, 1),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('View Full Itinerary'),
            ),
            const SizedBox(height: 14),
            const Text(
              _routeNote,
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFCCCCCC)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripStat extends StatelessWidget {
  const _TripStat(this.value, this.label);

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFCCCCCC)),
          ),
        ],
      ),
    );
  }
}

class _ItineraryList extends StatelessWidget {
  const _ItineraryList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: children,
        ),
      ),
    );
  }
}

class _SaveTripButton extends StatefulWidget {
  const _SaveTripButton({required this.onSave});

  final Future<void> Function() onSave;

  @override
  State<_SaveTripButton> createState() => _SaveTripButtonState();
}

class _SaveTripButtonState extends State<_SaveTripButton> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave();
      if (!mounted) return;
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip saved. Find it in Saved Trips.')),
      );
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _saved ? 'Trip saved' : 'Save trip',
      onPressed: _saving || _saved ? null : _save,
      icon: _saving
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_saved ? Icons.bookmark : Icons.bookmark_outline),
    );
  }
}
