import 'package:flutter/material.dart';

import '../../../core/theme/explore_lanka_theme.dart';
import '../data/attraction.dart';
import '../data/attraction_editorial.dart';

class AttractionCard extends StatelessWidget {
  const AttractionCard({super.key, required this.place, required this.onOpen});

  final Attraction place;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = place.visitDuration;
    final suggested = AttractionEditorial.forPlace(place)?.suggestedVisit;
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.sizeOf(context).width < 360 ? 76 : 100,
                height: 132,
                child: AttractionPhoto(place: place),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (place.displayLocation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _CardLine(
                        icon: Icons.place_outlined,
                        text: place.displayLocation,
                      ),
                    ],
                    const SizedBox(height: 5),
                    _CardLine(
                      icon: Icons.confirmation_number_outlined,
                      text: 'Entry · ${place.admissionLabel}',
                    ),
                    if (place.category.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(place.category, style: theme.textTheme.bodySmall),
                    ],
                    if (duration != null || suggested != null) ...[
                      const SizedBox(height: 5),
                      _CardLine(
                        icon: Icons.schedule,
                        text: duration != null
                            ? 'Estimated visit: $duration'
                            : 'Suggested visit: $suggested',
                      ),
                    ],
                    TextButton.icon(
                      onPressed: onOpen,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFA63F18),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        textStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View details'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AttractionPhoto extends StatelessWidget {
  const AttractionPhoto({super.key, required this.place});

  final Attraction place;

  @override
  Widget build(BuildContext context) {
    final editorial = AttractionEditorial.forPlace(place);
    const unavailable = ColoredBox(
      color: Color(0xFFD8EEEA),
      child: Center(
        child: Icon(Icons.landscape_outlined, color: exploreTeal, size: 32),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: editorial == null
          ? unavailable
          : Image.asset(
              'assets/images/${editorial.image}.jpg',
              fit: BoxFit.cover,
              semanticLabel: 'Illustration of ${place.name}',
              errorBuilder: (context, error, stack) => unavailable,
            ),
    );
  }
}

class _CardLine extends StatelessWidget {
  const _CardLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: exploreTeal),
        const SizedBox(width: 5),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
