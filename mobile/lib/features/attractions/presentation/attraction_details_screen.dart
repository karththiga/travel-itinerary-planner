import 'package:flutter/material.dart';

import '../data/attraction.dart';
import '../data/attraction_editorial.dart';
import 'attraction_card.dart';

class AttractionDetailsScreen extends StatefulWidget {
  const AttractionDetailsScreen({
    super.key,
    required this.place,
    required this.saved,
    required this.onToggleSaved,
  });

  final Attraction place;
  final bool saved;
  final Future<void> Function() onToggleSaved;

  @override
  State<AttractionDetailsScreen> createState() =>
      _AttractionDetailsScreenState();
}

class _AttractionDetailsScreenState extends State<AttractionDetailsScreen> {
  bool _updating = false;

  Future<void> _toggleSaved() async {
    setState(() => _updating = true);
    try {
      await widget.onToggleSaved();
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final theme = Theme.of(context);
    final editorial = AttractionEditorial.forPlace(place);
    final opening = place.openingTime.trim();
    final closing = place.closingTime.trim();
    final hours = [
      if (opening.isNotEmpty) 'Opens $opening',
      if (closing.isNotEmpty) 'Closes $closing',
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(title: const Text('Attraction details')),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 688),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: Icon(
                  widget.saved ? Icons.bookmark : Icons.bookmark_border,
                ),
                label: Text(
                  widget.saved ? 'Remove from Saved' : 'Save Attraction',
                ),
                onPressed: _updating ? null : _toggleSaved,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SizedBox(height: 222, child: AttractionPhoto(place: place)),
                if (editorial != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      'Destination illustration',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 18),
                Text(
                  place.name,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (place.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(place.description),
                ],
                const SizedBox(height: 16),
                Card(
                  color: Colors.white,
                  elevation: 0,
                  child: Column(
                    children: [
                      _Detail(
                        icon: Icons.place_outlined,
                        title: 'Location',
                        value: place.displayLocation,
                      ),
                      _Detail(
                        icon: Icons.category_outlined,
                        title: 'Category',
                        value: place.category,
                      ),
                      _Detail(
                        icon: Icons.schedule,
                        title:
                            place.visitDuration == null &&
                                editorial?.suggestedVisit != null
                            ? 'Suggested visit'
                            : 'Estimated visit',
                        value:
                            place.visitDuration ??
                            editorial?.suggestedVisit ??
                            '',
                      ),
                      _Detail(
                        icon: Icons.access_time,
                        title: 'Opening hours',
                        value: hours.isNotEmpty
                            ? hours
                            : editorial?.hours ?? '',
                      ),
                      _Detail(
                        icon: Icons.payments_outlined,
                        title: 'Indicative entry cost',
                        value: place.admissionLabel,
                      ),
                      if (editorial?.visitorNote case final note?)
                        _Detail(
                          icon: Icons.info_outline,
                          title: 'Before you go',
                          value: note,
                        ),
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

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(title),
      subtitle: Text(value.trim().isEmpty ? 'Not listed' : value),
    );
  }
}
