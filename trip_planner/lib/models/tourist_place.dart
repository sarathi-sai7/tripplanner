class TouristPlace {
  final String place;
  final String district;
  final String whyVisit;
  final String timing;

  TouristPlace({
    required this.place,
    required this.district,
    required this.whyVisit,
    required this.timing,
  });

  factory TouristPlace.fromCsv(List<dynamic> row) {
    return TouristPlace(
      place: row[0].toString(),
      district: row[1].toString(),
      whyVisit: row[2].toString(),
      timing: row[3].toString(),
    );
  }
}