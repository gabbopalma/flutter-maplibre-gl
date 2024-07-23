import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

void runMyTest() {
  const path = "assets/big_result.json";

  TestWidgetsFlutterBinding.ensureInitialized();

  test("Raw features to FeatureCollections", () async {
    // Leggi il file dagli assets
    final jsonString = await rootBundle.loadString(path);

    // Decodifica il JSON
    final Map<String, dynamic> input = jsonDecode(jsonString);

    // Ottieni il percorso della directory dell'app
    final directory = await getApplicationDocumentsDirectory();
    final outputDirPath = '${directory.path}/output_features';
    final outputDir = Directory(outputDirPath);

    // Crea la directory output_features se non esiste
    if (!outputDir.existsSync()) {
      outputDir.createSync();
    }

    // Raggruppa le features per collection
    final collections = <String, List<dynamic>>{};
    input.forEach((urn, coordinates) {
      // Determina se le coordinate rappresentano un singolo punto o una serie di punti
      final isSinglePoint = coordinates is List && coordinates.length == 2 && coordinates.every((element) => element is double);
      final isListOfPoints = coordinates is List && coordinates.every((element) => element is List && element.length == 2 && element.every((e) => e is double));
      final isPolygon = coordinates is List &&
          coordinates.isNotEmpty &&
          coordinates.every((element) => element is List && element.every((e) => e is List && e.length == 2 && e.every((i) => i is double)));

      List<dynamic> editedCoords;
      if (isSinglePoint) {
        // Gestisce un singolo punto
        editedCoords = [double.parse(coordinates[0].toStringAsFixed(6)), double.parse(coordinates[1].toStringAsFixed(6))];
      } else if (isListOfPoints) {
        // Gestisce una lista di punti
        editedCoords = coordinates.map((coord) => [double.parse(coord[0].toStringAsFixed(6)), double.parse(coord[1].toStringAsFixed(6))]).toList();
      } else if (isPolygon) {
        // Gestisce un poligono
        editedCoords = coordinates.map((ring) => ring.map((coord) => [double.parse(coord[0].toStringAsFixed(6)), double.parse(coord[1].toStringAsFixed(6))]).toList()).toList();
      } else {
        // Se le coordinate non corrispondono a nessuno dei formati attesi, logga un errore
        log("Formato delle coordinate non supportato per $urn: $coordinates");
        return; // Salta questa iterazione
      }

      final collectionName = collectionNameFromUrn(urn);
      collections[collectionName] = collections[collectionName] ?? [];
      collections[collectionName]!.add({
        "type": "Feature",
        "geometry": {
          "type": isSinglePoint
              ? "Point"
              : isListOfPoints
                  ? "LineString"
                  : "Polygon",
          "coordinates": editedCoords,
        },
        "properties": {
          "urn": urn,
          "collection": collectionName,
        }
      });
    });

    // Per ogni collection, crea un file GEOJson
    collections.forEach((collectionName, features) async {
      final filePath = '$outputDirPath/$collectionName.json';
      final file = File(filePath);
      final geoJson = {
        'type': 'FeatureCollection',
        'features': features,
      };

      // Scrivi le features nel file GEOJson
      await file.writeAsString(jsonEncode(geoJson));
    });
  });
}

String collectionNameFromUrn(String urn) => urn.split("V")[3].split("Z").last;
