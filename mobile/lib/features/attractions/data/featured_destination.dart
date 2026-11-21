import 'admission.dart';

enum FeaturedDestination {
  sigiriya('Sigiriya', 'History • Culture', 'sigiriya', sigiriyaAdmission),
  ella('Ella', 'Nature • Adventure', 'ella', 'Nine Arch Bridge · Free'),
  galle('Galle', 'History • Culture', 'galle', 'Galle Fort · Free');

  const FeaturedDestination(
    this.label,
    this.interests,
    this.assetName,
    this.admission,
  );

  final String label;
  final String interests;
  final String assetName;
  final String admission;

  String get image => 'assets/images/$assetName.jpg';
}
