import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Flip Coordinates', () async {
    const path = "assets/features.json";

    // Leggi il file dagli assets
    final jsonString = await rootBundle.loadString(path);

    // Decodifica il JSON
    final List<dynamic> input = jsonDecode(jsonString)["features"];

    // Inverti le coordinate del GeoJSON
    final geoJson = _flipCoordinates(input);

    // Converti l'oggetto GeoJSON in stringa
    final geoJsonString = jsonEncode(geoJson);

    // Salva il risultato in un nuovo file JSON
    await _saveToFile('output.json', geoJsonString);

    print('File salvato con successo!');
  });
}

Map<String, dynamic> _flipCoordinates(List<dynamic> features) {
  final flippedFeatures = features.map((feature) {
    // Assumi che feature sia una mappa e accedi direttamente a "geometry" e "coordinates"
    final List<dynamic> originalCoordinates = feature["geometry"]["coordinates"];
    final flippedCoordinates = originalCoordinates.map((coords) {
      // Inverti le coordinate qui
      return [coords[1], coords[0]];
    }).toList();

    // Costruisci e restituisci la nuova feature con le coordinate invertite
    return {
      "type": feature["type"],
      "geometry": {"type": feature["geometry"]["type"], "coordinates": flippedCoordinates},
      "properties": feature["properties"]
    };
  }).toList();

  return {"type": "FeatureCollection", "features": flippedFeatures};
}

// Funzione per salvare la stringa JSON in un file
Future<void> _saveToFile(String fileName, String content) async {
  final directory = await getApplicationDocumentsDirectory();
  final path = '${directory.path}/$fileName';
  final file = File(path);

  // Scrivi il file
  await file.writeAsString(content);
}
