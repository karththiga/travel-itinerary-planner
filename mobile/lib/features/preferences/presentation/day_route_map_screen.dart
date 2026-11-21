import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/explore_lanka_theme.dart';
import '../../attractions/data/attraction.dart';
import '../data/travel_day.dart';

class DayRouteMapScreen extends StatefulWidget {
  const DayRouteMapScreen({
    super.key,
    required this.day,
    required this.stops,
    required this.onOpen,
  });

  final TravelDay day;
  final List<Attraction> stops;
  final ValueChanged<Attraction> onOpen;

  @override
  State<DayRouteMapScreen> createState() => _DayRouteMapScreenState();
}

class _DayRouteMapScreenState extends State<DayRouteMapScreen> {
  final _transform = TransformationController();
  bool _expanded = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    _transform.value = Matrix4.identity();
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final stops = widget.stops;
    final distance = _routeDistance(stops);
    final map = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF38465A)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              transformationController: _transform,
              maxScale: 5,
              child: CustomPaint(painter: _RoutePainter(stops)),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Chip(
                avatar: const Icon(Icons.route_outlined, size: 17),
                label: Text(
                  stops.length == 1
                      ? '1 stop'
                      : '${distance.toStringAsFixed(1)} km direct',
                ),
                backgroundColor: const Color(0xFF262C36),
                side: const BorderSide(color: Color(0xFF465263)),
                shape: const StadiumBorder(),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton.filledTonal(
                tooltip: _expanded ? 'Exit expanded map' : 'Expand map',
                onPressed: _toggleExpanded,
                icon: Icon(
                  _expanded ? Icons.fullscreen_exit : Icons.fullscreen,
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: IconButton.filledTonal(
                tooltip: 'Reset map view',
                onPressed: () => _transform.value = Matrix4.identity(),
                icon: const Icon(Icons.center_focus_strong),
              ),
            ),
          ],
        ),
      ),
    );
    return Theme(
      data: buildTripPlanningTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Day ${widget.day.number} — Route Preview',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: _expanded
            ? Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: map,
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      AspectRatio(aspectRatio: 4 / 3, child: map),
                      const SizedBox(height: 14),
                      const Text(
                        'Straight-line preview of the suggested stop order. Check actual roads and travel times before leaving.',
                        style: TextStyle(color: Color(0xFFCCCCCC)),
                      ),
                      if (stops.length < widget.day.stops.length)
                        const Text('Some stops have no map coordinates.'),
                      const SizedBox(height: 20),
                      const Text(
                        'Stops in order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      for (final (index, stop) in stops.indexed)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(stop.name),
                          subtitle: stop.displayLocation.isEmpty
                              ? null
                              : Text(stop.displayLocation),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => widget.onOpen(stop),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

double _routeDistance(List<Attraction> stops) {
  const radians = math.pi / 180;
  var total = 0.0;
  for (var i = 1; i < stops.length; i++) {
    final start = stops[i - 1];
    final end = stops[i];
    final lat = (end.latitude - start.latitude) * radians;
    final lon = (end.longitude - start.longitude) * radians;
    final a =
        math.pow(math.sin(lat / 2), 2) +
        math.cos(start.latitude * radians) *
            math.cos(end.latitude * radians) *
            math.pow(math.sin(lon / 2), 2);
    total += 2 * 6371 * math.asin(math.sqrt(a.clamp(0, 1)));
  }
  return total;
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter(this.stops);

  final List<Attraction> stops;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 16 || size.height <= 16) return;
    canvas.drawColor(const Color(0xFF172438), BlendMode.src);
    final grid = Paint()..color = const Color(0xFF26364B);
    for (double x = 24; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 24; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final origin = stops.first;
    final correction = math.cos(origin.latitude * math.pi / 180);
    final points = stops
        .map(
          (stop) => Offset(
            (stop.longitude - origin.longitude) * correction,
            origin.latitude - stop.latitude,
          ),
        )
        .toList();
    final minX = points.map((point) => point.dx).reduce(math.min);
    final maxX = points.map((point) => point.dx).reduce(math.max);
    final minY = points.map((point) => point.dy).reduce(math.min);
    final maxY = points.map((point) => point.dy).reduce(math.max);
    final center = Offset((minX + maxX) / 2, (minY + maxY) / 2);
    final scale = math.min(
      math.max(1, size.width - 76) / math.max(maxX - minX, 0.001),
      math.max(1, size.height - 166) / math.max(maxY - minY, 0.001),
    );
    final markers = points
        .map((point) => size.center(Offset.zero) + (point - center) * scale)
        .toList();
    final line = Paint()
      ..color = const Color(0xFFF3F5F8)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    for (var i = 1; i < markers.length; i++) {
      canvas.drawLine(markers[i - 1], markers[i], line);
    }
    for (final (index, marker) in markers.indexed) {
      canvas.drawCircle(marker, 15, Paint()..color = const Color(0xFF657388));
      canvas.drawCircle(marker, 14, Paint()..color = const Color(0xFF273140));
      final label = TextPainter(
        text: TextSpan(
          text: '${index + 1}',
          style: const TextStyle(
            color: Color(0xFFF3F5F8),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, marker - Offset(label.width / 2, label.height / 2));
      label.dispose();

      final name = TextPainter(
        text: TextSpan(
          text: stops[index].name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: math.min(168, size.width - 16));
      final left = (marker.dx - name.width / 2)
          .clamp(8, size.width - name.width - 8)
          .toDouble();
      final top = marker.dy + 19;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left - 4, top - 2, name.width + 8, name.height + 4),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xEE111B2A),
      );
      name.paint(canvas, Offset(left, top));
      name.dispose();
    }
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) => oldDelegate.stops != stops;
}
