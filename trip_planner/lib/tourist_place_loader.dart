import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'models/tourist_place.dart';

class TouristPlaceLoader {
  static Future<List<TouristPlace>> loadFromCsv() async {
    try {
      final rawData = await rootBundle.loadString('assets/places.csv');

      final rows = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(rawData);

      List<TouristPlace> places = [];

      for (var i = 1; i < rows.length; i++) { // skip header
        final row = rows[i];
        if (row.length >= 5) {
          places.add(TouristPlace(
            place: row[2].toString().trim(),
            district: row[1].toString().trim(),
            whyVisit: row[3].toString().trim(),
            timing: row[4].toString().trim(),
          ));
        }
      }

      return places;
    } catch (e) {
      debugPrint('Error loading CSV: $e');
      return [];
    }
  }
}
