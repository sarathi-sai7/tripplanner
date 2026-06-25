import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class TrainLoader {
  List<Map<String, String>> trainCsv = [];

  Future<void> loadCSV() async {
    final csvString = await rootBundle.loadString('assets/trains.csv');
    List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);

    List<Map<String, String>> tempList = [];
    for (var i = 1; i < rows.length; i++) { // skip header
      final row = rows[i];
      if (row.length < 7) continue;

      tempList.add({
        'destination': row[0].toString().trim(),
        'trainName': row[1].toString().trim(),
        'departure': row[2].toString().trim(),
        'arrival': row[3].toString().trim(),
        'duration': row[4].toString().trim(),
        'fare': row[5].toString().trim(),
        'link': row[6].toString().trim(),
      });
    }
    trainCsv = tempList;
  }

  List<Map<String, String>> getTrains({required String destination}) {
    return trainCsv
        .where((t) =>
            t['destination']!.toLowerCase().contains(destination.toLowerCase()))
        .toList();
  }
}
