// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:path_provider/path_provider.dart';

import 'page.dart';

class AllCollectionsPage extends ExamplePage {
  static const String pageTitle = "All Collections (Stress test)";
  const AllCollectionsPage({super.key}) : super(const Icon(Icons.layers_rounded), pageTitle);

  @override
  Widget build(BuildContext context) {
    return const AllCollectionsBody();
  }
}

class AllCollectionsBody extends StatefulWidget {
  const AllCollectionsBody({super.key});

  @override
  State<AllCollectionsBody> createState() => AllCollectionsBodyState();
}

class AllCollectionsBodyState extends State<AllCollectionsBody> {
  AllCollectionsBodyState();

  static const LatLng center = LatLng(44.375627, 7.532688);

  MapLibreMapController? controller;

  int linesCount = 0;
  bool layerVisibility = true;

  Map<String, bool> collLayerVisibility = {};

  @override
  void dispose() {
    controller?.onFeatureDrag.remove(_onFeatureDrag);
    controller?.onFeatureTapped.remove(_onFeatureTapped);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AllCollectionsPage.pageTitle),
        actions: [
          // Display a menu button with a visible enable/disable layer option.
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            enabled: collLayerVisibility.isNotEmpty,
            icon: const Icon(Icons.filter_list_rounded),
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  enabled: false,
                  child: Text(
                    "Collections visibility",
                    style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
                  ),
                ),
                const PopupMenuDivider(),
                ...collLayerVisibility.entries.map((e) {
                  return CheckedPopupMenuItem<String>(
                    value: e.key,
                    checked: e.value,
                    onTap: () {
                      print("Toggled ${e.key} to ${!e.value}");
                      setState(() => collLayerVisibility[e.key] = !e.value);
                      controller?.setLayerVisibility(e.key, !e.value);
                    },
                    child: Text(collectionNameFromLayerId(e.key)),
                  );
                }),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MapLibreMap(
              styleString: "assets/transparent_style.json",
              onMapCreated: _onMapCreated,
              onStyleLoadedCallback: () async {
                addImageFromAsset("assetImage", "assets/symbols/custom-icon.png");
                addImageFromAsset("ebwLogo", "assets/black-logo.png");
                await addTiles();
                await addFeaturesCollections(context);
              },
              initialCameraPosition: const CameraPosition(target: center, zoom: 13.0),
              minMaxZoomPreference: const MinMaxZoomPreference(6.0, 23.0),
              annotationOrder: const [
                AnnotationType.symbol,
                AnnotationType.circle,
                AnnotationType.line,
                AnnotationType.fill,
              ],
              annotationConsumeTapEvents: const [
                AnnotationType.symbol,
                AnnotationType.circle,
                AnnotationType.line,
                AnnotationType.fill,
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Drawn features: ${!layerVisibility ? 0 : linesCount}'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          setState(() => layerVisibility = !layerVisibility);
          var layersIds = await controller?.getLayerIds();
          if (layersIds == null) return;

          layersIds = layersIds.where((element) => element.toString().contains("feat")).toList();
          for (final layerId in layersIds) {
            await controller?.setLayerVisibility(layerId, layerVisibility);
          }
          for (final entry in collLayerVisibility.entries) {
            collLayerVisibility[entry.key] = layerVisibility;
          }

          debugPrint("Feature visibility toggle: $layerVisibility");
        },
        child: Icon(layerVisibility ? Icons.visibility_off : Icons.visibility),
      ),
    );
  }

  Future<void> addFeaturesCollections(BuildContext context) async {
    // Get the "output_features" from device storage.
    final featuresPath = await listFeatureFiles;

    if (featuresPath == null) {
      return;
    }

    final directory = await getApplicationDocumentsDirectory();

    for (final featurePath in featuresPath) {
      // Read the file from the device storage
      final jsonString = await File("${directory.path}/output_features/$featurePath").readAsString();

      final Map<String, dynamic> features = jsonDecode(jsonString);
      final collectionName = featurePath.replaceAll(".json", "");
      final collectionGeomType = features["features"][0]["geometry"]["type"].toString().toLowerCase();
      final layerId = "$collectionName-feat-$collectionGeomType-layer";

      await controller?.addGeoJsonSource("$collectionName-source", features);

      switch (collectionGeomType) {
        case "point":
          await controller?.addSymbolLayer(
            "$collectionName-source",
            layerId,
            SymbolLayerProperties(
              iconImage: getRandomIcon,
              iconSize: [
                'interpolate',
                ['exponential', 2],
                ['zoom'],
                6,
                0.2,
                23,
                7.5,
              ],
              iconRotate: 35,
              iconAllowOverlap: true,
              iconRotationAlignment: "map",
            ),
            enableInteraction: true,
          );
        case "linestring":
          await controller?.addLineLayer(
            "$collectionName-source",
            layerId,
            LineLayerProperties(
              lineColor: getRandomColor,
              lineWidth: 2.0,
              lineDasharray: [
                "literal",
                getRandomLinePattern,
              ],
            ),
            enableInteraction: true,
          );
        case "polygon":
          await controller?.addFillLayer(
            "$collectionName-source",
            layerId,
            const FillLayerProperties(
              fillColor: ['rgba', 0, 0, 0, 0.2],
              fillOutlineColor: "red",
              fillOpacity: 1.0,
            ),
            enableInteraction: true,
          );
      }
      // Update the lines count.
      setState(() => linesCount += (features["features"] as List).length);

      // Add the layer visibility to the collLayerVisibility map.
      collLayerVisibility[layerId] = true;

      print("Added $collectionName-source with ${(features["features"] as List).length} features.");
    }
  }

  String collectionNameFromLayerId(String layerId) {
    return layerId.split("-").first;
  }

  String collectionGeomType(Map<String, dynamic> feature) {
    return feature["geometry"]["type"];
  }

  Future<List<String>?> get listFeatureFiles async {
    final result = <String>[];

    // Ottieni il percorso della directory delle applicazioni
    final directory = await getApplicationDocumentsDirectory();

    // Costruisci il percorso della cartella output_features
    final featuresDir = Directory('${directory.path}/output_features');

    // Controlla se la cartella esiste
    if (featuresDir.existsSync()) {
      // Elenco dei file nella cartella output_features
      final files = await featuresDir.list().toList();

      // Filtra per ottenere solo i file (escludendo le cartelle)
      final featureFiles = files.whereType<File>().toList();

      // Stampa i percorsi dei file
      for (final file in featureFiles) {
        result.add(file.path.split('/').last);
      }

      return result;
    } else {
      print('La cartella output_features non esiste.');
      return null;
    }
  }

  Future<void> addTiles() async {
    await controller?.addSource(
      "osm-tiles",
      const RasterSourceProperties(
        tiles: [
          "https://api.maptiler.com/maps/topo-v2/{z}/{x}/{y}.png?key=vtLC2eJ5637uotCVnHyu",
        ],
        tileSize: 512,
        attribution:
            '<a href="https://www.maptiler.com/copyright/" target="_blank">&copy; MapTiler</a> <a href="https://www.openstreetmap.org/copyright" target="_blank">&copy; OpenStreetMap contributors</a>',
      ),
    );
    await controller?.addRasterLayer("osm-tiles", "osm-tiles", const RasterLayerProperties());
  }

  Future<void> _onMapCreated(MapLibreMapController controller) async {
    this.controller = controller;
    controller.onFeatureDrag.add(_onFeatureDrag);
    controller.onFeatureTapped.add(_onFeatureTapped);
  }

  /// Adds an asset image to the currently displayed style
  Future<void> addImageFromAsset(String name, String assetName) async {
    final bytes = await rootBundle.load(assetName);
    final list = bytes.buffer.asUint8List();

    controller?.addImage(name, list);
  }

  String get getRandomColor {
    final random = Random();
    return Color.fromARGB(255, random.nextInt(255), random.nextInt(255), random.nextInt(255)).toHexStringRGB();
  }

  List<int> get getRandomLinePattern {
    final random = Random();
    return [random.nextInt(10) + 5, random.nextInt(5)];
  }

  String get getRandomIcon {
    final random = Random();
    return random.nextBool() ? "assetImage" : "ebwLogo";
  }

  void _showSnackBar(String type, String id) {
    final snackBar = SnackBar(
        content: Text(
          'Tapped $type $id',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _onFeatureTapped(dynamic feature, Point<double> point, LatLng coords) {
    _showSnackBar('feature', coords.toString());
  }

  void _onFeatureDrag(dynamic, {required LatLng current, required LatLng delta, required DragEventType eventType, required LatLng origin, required Point<double> point}) {
    _showSnackBar('feature', "$origin to $current");
  }
}
