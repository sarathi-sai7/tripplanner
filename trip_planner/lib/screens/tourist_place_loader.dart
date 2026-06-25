import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:trip_planner/models/tourist_place.dart';

class TouristPlaceLoader {
  static Future<List<TouristPlace>> loadFromCsv() async {
    final rawData = await rootBundle.loadString('assets/places.csv');
    final rows = const CsvToListConverter().convert(rawData, eol: '\n');
    return rows.skip(1).map((row) => TouristPlace.fromCsv(row)).toList();
  }
}
