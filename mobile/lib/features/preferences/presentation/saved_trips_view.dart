import 'package:flutter/material.dart';

import '../../auth/data/auth_repository.dart';
import '../data/saved_trip_repository.dart';

class SavedTripsView extends StatefulWidget {
  const SavedTripsView({
    super.key,
    required this.repository,
    required this.onOpen,
  });

  final SavedTripRepository repository;
  final ValueChanged<SavedTrip> onOpen;

  @override
  State<SavedTripsView> createState() => _SavedTripsViewState();
}

class _SavedTripsViewState extends State<SavedTripsView> {
  late Future<List<SavedTrip>> _trips = widget.repository.load();
  bool _removing = false;

  Future<void> _remove(SavedTrip trip) async {
    setState(() => _removing = true);
    try {
      await widget.repository.remove(trip.id);
      if (!mounted) return;
      final current = await _trips;
      if (mounted) {
        setState(() {
          _trips = Future.value(
            current.where((item) => item.id != trip.id).toList(),
          );
        });
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _trips,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error is AuthException
                        ? error.message
                        : 'Could not load saved trips.',
                  ),
                  TextButton(
                    onPressed: () {
                      final request = widget.repository.load();
                      setState(() {
                        _trips = request;
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final trips = snapshot.data!;
        if (trips.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Save an itinerary from the trip preview to find it here.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];
            final days = trip.preferences.tripDays;
            final name = trip.stops.first.name;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.route_outlined),
                title: Text('$name itinerary'),
                subtitle: Text(
                  '$days ${days == 1 ? 'day' : 'days'} · ${trip.stops.length} ${trip.stops.length == 1 ? 'stop' : 'stops'} · ${trip.preferences.transport}',
                ),
                onTap: () => widget.onOpen(trip),
                trailing: IconButton(
                  tooltip: 'Remove $name itinerary',
                  icon: const Icon(Icons.bookmark_remove_outlined),
                  onPressed: _removing ? null : () => _remove(trip),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
