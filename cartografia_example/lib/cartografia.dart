import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:maplibre_gl_example/page.dart';

class CartografiaPage extends ExamplePage {
  const CartografiaPage({super.key}) : super(const Icon(Icons.shape_line_sharp), 'Cartografia');

  @override
  Widget build(BuildContext context) {
    return const CartografiaBody();
  }
}

class CartografiaBody extends StatefulWidget {
  const CartografiaBody({super.key});

  @override
  State<StatefulWidget> createState() => CartografiaBodyState();
}

class CartografiaBodyState extends State<CartografiaBody> {
  CartografiaBodyState();

  static const LatLng center = LatLng(44.375627, 7.532688);

  MapLibreMapController? controller;

  int linesCount = 0;
  bool layerVisibility = true;

  @override
  void dispose() {
    controller?.onFeatureDrag.remove(_onFeatureDrag);
    controller?.onFeatureTapped.remove(_onFeatureTapped);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children: [
            Expanded(
              child: MapLibreMap(
                styleString: "assets/transparent_style.json",
                onMapCreated: _onMapCreated,
                onStyleLoadedCallback: () async {
                  controller?.addSource(
                    "raster-test",
                    const RasterSourceProperties(
                      tiles: [
                        "https://api.maptiler.com/maps/topo-v2/{z}/{x}/{y}.png?key=vtLC2eJ5637uotCVnHyu",
                      ],
                      tileSize: 512,
                      attribution:
                          '<a href="https://www.maptiler.com/copyright/" target="_blank">&copy; MapTiler</a> <a href="https://www.openstreetmap.org/copyright" target="_blank">&copy; OpenStreetMap contributors</a>',
                    ),
                  );
                  controller?.addRasterLayer("raster-test", "raster-test", const RasterLayerProperties());

                  final featuresString = await DefaultAssetBundle.of(context).loadString("assets/features.json");
                  final Map<String, dynamic> featuresRaw = jsonDecode(featuresString);

                  await controller?.addGeoJsonSource("cartografia-source", featuresRaw);

                  await controller?.addLineLayer(
                    "cartografia-source",
                    "cartografia-layer-lines",
                    const LineLayerProperties(
                      lineColor: "#000000",
                      lineWidth: 2.0,
                      lineOpacity: 0.3,
                    ),
                    enableInteraction: true,
                  );

                  setState(() => linesCount = (featuresRaw["features"] as List).length);

                  print("Added source and lineLayer (features: $linesCount)");
                },
                initialCameraPosition: const CameraPosition(target: center, zoom: 13.0),
                minMaxZoomPreference: const MinMaxZoomPreference(6.0, 23.0),
                // dragEnabled: false,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Features drawn: ${!layerVisibility ? 0 : linesCount}'),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            setState(() => layerVisibility = !layerVisibility);
            await controller?.setLayerVisibility("cartografia-layer-lines", layerVisibility);
            debugPrint("Feature visibility toggle: $layerVisibility");
          },
          child: Icon(layerVisibility ? Icons.visibility_off : Icons.visibility),
        ));
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
    return controller!.addImage(name, list);
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
