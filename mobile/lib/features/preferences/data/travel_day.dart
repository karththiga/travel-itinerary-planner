import '../../attractions/data/attraction.dart';

class TravelDay {
  const TravelDay(this.number, this.stops);

  final int number;
  final List<Attraction> stops;

  String get title => 'Day $number · $theme';

  String get theme {
    final categories = stops
        .expand((stop) => stop.category.split('•'))
        .map((category) => category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .take(2);
    return categories.isEmpty ? 'Sightseeing' : categories.join(' and ');
  }
}
