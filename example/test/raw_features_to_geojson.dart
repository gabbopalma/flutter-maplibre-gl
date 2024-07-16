import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  const path = "assets/result.json";

  TestWidgetsFlutterBinding.ensureInitialized();

  test('Converti in GeoJSON', () async {
    // Leggi il file dagli assets
    final jsonString = await rootBundle.loadString(path);

    // Decodifica il JSON
    final Map<String, dynamic> input = jsonDecode(jsonString);

    // Converti in GeoJSON
    final geoJson = _toGeoJSON(input);

    // Converti l'oggetto GeoJSON in stringa
    final geoJsonString = jsonEncode(geoJson);

    // Salva il risultato in un nuovo file JSON
    await _saveToFile('output.json', geoJsonString);

    print('File salvato con successo!');
  });
}

// Funzione per convertire in GeoJSON LineString
Map<String, dynamic> _toGeoJSON(Map<String, dynamic> data) {
  final List<Map<String, dynamic>> features = data.entries.map((entry) {
    final coordinates = <List<double>>[];
    if (entry.value is List<dynamic> && (entry.value as List<dynamic>).length >= 2) {
      for (final pos in entry.value) {
        coordinates.add([pos[0], pos[1]]);
      }
    }

    return {
      "type": "Feature",
      "geometry": {"type": "LineString", "coordinates": coordinates},
      "properties": {}
    };
  }).toList();

  return {"type": "FeatureCollection", "features": features};
}

// Funzione per salvare la stringa JSON in un file
Future<void> _saveToFile(String fileName, String content) async {
  final directory = await getApplicationDocumentsDirectory();
  final path = '${directory.path}/$fileName';
  final file = File(path);

  // Scrivi il file
  await file.writeAsString(content);
}
