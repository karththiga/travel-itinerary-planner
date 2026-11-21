import 'package:flutter/material.dart';

import '../data/featured_destination.dart';

class DestinationCard extends StatelessWidget {
  const DestinationCard({
    super.key,
    required this.destination,
    required this.saved,
    required this.onSave,
    this.onOpen,
    this.footer,
  });

  final FeaturedDestination destination;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback? onOpen;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: footer == null ? 1.4 : 1.85,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  destination.image,
                  fit: BoxFit.cover,
                  semanticLabel: destination.label,
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xD9223734),
                      foregroundColor: Colors.white,
                    ),
                    tooltip: saved
                        ? 'Remove ${destination.label} from Saved'
                        : 'Save ${destination.label}',
                    onPressed: onSave,
                    icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                  ),
                ),
              ],
            ),
          ),
          footer ??
              ListTile(
                title: Text(
                  destination.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${destination.interests}\n${destination.admission}',
                ),
                onTap: onOpen,
              ),
        ],
      ),
    );
  }
}
