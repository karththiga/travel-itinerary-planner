enum TravelInterest {
  history('History', 'Sigiriya Rock Fortress', 'Sigiriya', [
    'heritage',
    'archaeology',
  ]),
  beach('Beach', 'Mirissa Beach', 'Mirissa', ['beaches', 'coast', 'coastal']),
  nature('Nature', 'Sinharaja Forest Reserve', 'Sinharaja', [
    'forest',
    'waterfall',
  ]),
  wildlife('Wildlife', 'Wilpattu National Park', 'Wilpattu', [
    'safari',
    'national park',
  ]),
  culture('Culture', 'Anuradhapura', 'Anuradhapura', ['cultural', 'heritage']),
  adventure('Adventure', 'Kitulgala', 'Kitulgala', [
    'hiking',
    'trekking',
    'rafting',
  ]),
  food('Food', 'Galle', 'Local eateries', ['culinary', 'dining', 'restaurant']),
  religious('Religious', 'Temple of the Sacred Tooth Relic', 'Kandy', [
    'religion',
    'temple',
    'pilgrimage',
  ]);

  const TravelInterest(
    this.label,
    this.suggestion,
    this.location,
    this.aliases,
  );

  final String label;
  final String suggestion;
  final String location;
  final List<String> aliases;

  bool matchesCategory(String category) {
    final tags = category.toLowerCase().split(RegExp(r'[^a-z ]+'));
    return tags.any((tag) {
      final value = tag.trim();
      return value == label.toLowerCase() || aliases.contains(value);
    });
  }
}
