// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:maplibre_gl_example/all_collections.dart';
import 'package:maplibre_gl_example/cartografia.dart';
import 'package:maplibre_gl_example/edit_line.dart';
import 'package:path_provider/path_provider.dart';

import 'page.dart';

final List<ExamplePage> _allPages = <ExamplePage>[
  const EditLinePage(),
  const CartografiaPage(),
  const AllCollectionsPage(),
];

class MapsDemo extends StatefulWidget {
  const MapsDemo({super.key});

  @override
  State<MapsDemo> createState() => _MapsDemoState();
}

class _MapsDemoState extends State<MapsDemo> {
  /// Determine the android version of the phone and turn off HybridComposition
  /// on older sdk versions to improve performance for these
  ///
  /// !!! Hybrid composition is currently broken do no use !!!
  Future<void> initHybridComposition() async {
    if (!kIsWeb && Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;
      if (sdkVersion >= 29) {
        MapLibreMap.useHybridComposition = true;
      } else {
        MapLibreMap.useHybridComposition = false;
      }
    }
  }

  Future<void> _pushPage(BuildContext context, ExamplePage page) async {
    if (!kIsWeb && page.needsLocationPermission) {
      final location = Location();
      final hasPermissions = await location.hasPermission();
      if (hasPermissions != PermissionStatus.granted) {
        await location.requestPermission();
      }
    }
    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) {
          if (page.title == "All Collections (Stress test)") {
            return Scaffold(body: page);
          }
          return Scaffold(
            appBar: AppBar(title: Text(page.title)),
            body: page,
          );
        },
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smartfield Demo with MapLibre')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _allPages.length,
              itemBuilder: (_, int index) => ListTile(
                leading: _allPages[index].leading,
                title: Text(_allPages[index].title),
                onTap: () => _pushPage(context, _allPages[index]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Powered by Flutter MapLibre GL',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await createFeaturesFolders();

  runApp(const MaterialApp(home: MapsDemo()));
}

Future<void> createFeaturesFolders() async {
  const path = "assets/big_result.json";

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
      editedCoords = [double.parse(coordinates[0].toStringAsFixed(6)), double.parse(coordinates[1].toStringAsFixed(6))];
    } else if (isListOfPoints) {
      editedCoords = coordinates.map((coord) => [double.parse(coord[0].toStringAsFixed(6)), double.parse(coord[1].toStringAsFixed(6))]).toList();
    } else if (isPolygon) {
      editedCoords = coordinates.map((ring) => ring.map((coord) => [double.parse(coord[0].toStringAsFixed(6)), double.parse(coord[1].toStringAsFixed(6))]).toList()).toList();
    } else {
      log("Formato delle coordinate non supportato per $urn: $coordinates");
      return;
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
}

String collectionNameFromUrn(String urn) => urn.split("V")[3].split("Z").last;
