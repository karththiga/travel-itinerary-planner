import 'attraction.dart';

class AttractionEditorial {
  const AttractionEditorial({
    required this.image,
    this.suggestedVisit,
    this.hours,
    this.visitorNote,
  });

  final String image;
  final String? suggestedVisit;
  final String? hours;
  final String? visitorNote;

  static const _sigiriya = AttractionEditorial(image: 'sigiriya');
  static const _ella = AttractionEditorial(image: 'ella');
  static const _galle = AttractionEditorial(image: 'galle');
  static const _nallur = AttractionEditorial(
    image: 'nallur',
    suggestedVisit: '30–60 min',
    hours: 'Main entrance: 4–5:30 am, 7:30 am–12:30 pm, 3–6 pm. Fridays: 4 am–6 pm.',
    visitorNote: 'Check temple dress and entry rules when you arrive. Confirm hours locally during festivals.',
  );
  static const _koneswaram = AttractionEditorial(
    image: 'koneswaram',
    suggestedVisit: '45–90 min',
    visitorNote: 'Allow time to walk up to the temple and confirm worship and visitor hours locally.',
  );
  static const _arugamBay = AttractionEditorial(
    image: 'arugam-bay',
    suggestedVisit: '1–2 hrs',
    visitorNote: 'If planning to surf, ask a local operator about conditions and a suitable break.',
  );
  static const _kks = AttractionEditorial(
    image: 'kks-beach',
    suggestedVisit: '45–90 min',
    visitorNote: 'Use designated public beach access and follow local signs near the port.',
  );
  static const _delft = AttractionEditorial(
    image: 'delft',
    suggestedVisit: 'Half day on the island',
    visitorNote: 'Check outbound and return ferry arrangements before leaving. Allow additional time for crossings.',
  );
  static const _kayts = AttractionEditorial(
    image: 'kayts',
    suggestedVisit: '1–2 hrs',
    visitorNote: 'Allow time for the waterfront and confirm onward transport before travelling.',
  );
  static const _pointPedro = AttractionEditorial(
    image: 'point-pedro',
    suggestedVisit: '20–40 min',
    visitorNote: 'This is a fishing harbour. Check local access and keep clear of working areas.',
  );
  static const _elephantPass = AttractionEditorial(
    image: 'elephant-pass',
    suggestedVisit: '15–30 min for a stop',
    visitorNote:
        'Use a designated stopping area away from the main road.',
  );
  static const _sangupiddy = AttractionEditorial(
    image: 'sangupiddy',
    suggestedVisit: '15–30 min at a safe viewpoint',
    visitorNote: 'This is an active road crossing. Use a safe viewpoint off the bridge for photos.',
  );

  static AttractionEditorial? forPlace(Attraction place) {
    for (final name in [place.name, ...place.aliases]) {
      final key = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final editorial = switch (key) {
        'sigiriya' || 'sigiriyarockfortress' || 'sigiriyalionrock' => _sigiriya,
        'ninearchbridge' ||
        'ninearchesbridge' ||
        'ninearchbridgeella' ||
        'ella' => _ella,
        'gallefort' ||
        'gallelighthouse' ||
        'gallefortlighthouse' ||
        'galle' => _galle,
        'nallurkandaswamytemple' ||
        'nallurtemple' ||
        'nallurkandaswamykovil' ||
        'nallurkanthaswamykovil' ||
        'nallurkovil' => _nallur,
        'koneswaramtemple' ||
        'koneswaramkovil' ||
        'konesvaramtemple' ||
        'thirukoneswaram' => _koneswaram,
        'arugambay' || 'arugambaybeach' => _arugamBay,
        'kankesanthurai' ||
        'kankesanthuraibeach' ||
        'kankesanturaibeach' ||
        'kksbeach' => _kks,
        'delftisland' || 'delft' || 'neduntivu' || 'nedunthivu' => _delft,
        'kayts' || 'kytes' || 'kaytstown' || 'urkavalthurai' => _kayts,
        'pointpedrojetty' ||
        'jettypointpedro' ||
        'pointpedrowharf' => _pointPedro,
        'elephantpass' ||
        'aanaiyiravu' ||
        'anaiyiravu' ||
        'alimankada' => _elephantPass,
        'sangupiddybridge' ||
        'sangupiddibridge' ||
        'changkupiddybridge' => _sangupiddy,
        _ => null,
      };
      if (editorial != null) return editorial;
    }
    return null;
  }
}
