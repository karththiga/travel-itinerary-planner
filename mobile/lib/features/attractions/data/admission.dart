const admissionNotListed = 'Price not listed';
const sigiriyaAdmission = 'USD 35 · foreign adult';
const _listedAdmission = {
  'sigiriya rock fortress': sigiriyaAdmission,
  'nine arch bridge': 'Free',
  'nine arches bridge': 'Free',
  'galle fort': 'Free',
  'galle dutch fort': 'Free',
  'arugam bay beach': 'Free',
  'nallur kandaswamy temple': 'Free',
  'koneswaram temple': 'Free',
};

String? curatedAdmission(Iterable<String> names) {
  for (final name in names) {
    final price = _listedAdmission[name.trim().toLowerCase()];
    if (price != null) return price;
  }
  return null;
}
