import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:maplibre_gl_example/google/google_keys.dart';
import 'package:maplibre_gl_example/page.dart';

class CompositeMap extends ExamplePage {
  const CompositeMap({super.key}) : super(const Icon(Icons.map), 'Composite Map');

  @override
  Widget build(BuildContext context) {
    return const CompositeMapBody();
  }
}

class CompositeMapBody extends StatefulWidget {
  const CompositeMapBody({super.key});

  @override
  State<StatefulWidget> createState() => CompositeMapBodyState();
}

class CompositeMapBodyState extends State<CompositeMapBody> {
  CompositeMapBodyState();

  static const LatLng center = LatLng(43.910472688446106, 12.911362502572898);
  MapLibreMapController? controller;

  String? sessionToken;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapLibreMap(
          styleString: "assets/transparent_style.json",
          trackCameraPosition: true,
          onMapCreated: _onMapLibreMapCreated,
          onStyleLoadedCallback: _onMapLibreStyleLoaded,
          initialCameraPosition: const CameraPosition(target: center, zoom: 13.0),
          onCameraIdle: () {},
          attributionButtonPosition: AttributionButtonPosition.topRight,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Image.asset("assets/google/3.0x/google_on_white@3x.png", scale: 3.0),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: FutureBuilder(
                  future: _getGoogleAttribution(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        color: Colors.white,
                        child: Text(
                          snapshot.data.toString(),
                        ),
                      );
                    } else {
                      return const SizedBox();
                    }
                  }),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _onMapLibreMapCreated(MapLibreMapController controller) async {
    this.controller = controller;

    // controller.addListener(() {
    //   if (controller.isCameraMoving) {
    //     _onMapCameraMove(controller.cameraPosition);
    //   }
    // });
  }

  Future<void> _onMapLibreStyleLoaded() async {
    final sessionToken = await _createGoogleSessionToken();
    final attribution = await _getGoogleAttribution();
    controller?.addSource(
      "raster-test",
      RasterSourceProperties(
        tiles: [
          "https://tile.googleapis.com/v1/2dtiles/{z}/{x}/{y}?session=$sessionToken&key=${GoogleKeys.apiKey}",
        ], //&orientation=0_or_90_or_180_or_270"],
        tileSize: 256,
        attribution: '<a href="https://www.maptiler.com/copyright/" target="_blank">&copy; $attribution</a>',
      ),
    );
    controller?.addRasterLayer("raster-test", "raster-test", const RasterLayerProperties());

    // mapController?.addSource(
    //     "vector-test-source",
    //     const RasterSourceProperties(
    //       url: "https://api.maptiler.com/maps/openstreetmap/256/{z}/{x}/{y}.jpg?key=vtLC2eJ5637uotCVnHyu",
    //       tileSize: 256,
    //       attribution: "© OpenStreetMap contributors",
    //     ));
    // mapController?.addLineLayer(
    //     "vector-test-source",
    //     "vector-test",
    //     const LineLayerProperties(
    //       lineColor: "#ff0000",
    //       lineWidth: 2.0,
    //     ));
  }

  Future<String> _createGoogleSessionToken() async {
    final uri = Uri.parse("https://tile.googleapis.com/v1/createSession?key=${GoogleKeys.apiKey}");

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        {"mapType": "roadmap", "language": "it-IT", "region": "IT"},
      ),
    );

    final Map<String, dynamic> data = jsonDecode(response.body);
    return data["session"];
  }

  Future<String?> _getGoogleAttribution() async {
    final token = await _createGoogleSessionToken();
    final visibleRegion = await controller?.getVisibleRegion();

    if (visibleRegion == null) return null;

    final north = visibleRegion.northeast.latitude;
    final south = visibleRegion.southwest.latitude;
    final east = visibleRegion.northeast.longitude;
    final west = visibleRegion.southwest.longitude;

    final uri = Uri.parse(
        "https://tile.googleapis.com/tile/v1/viewport?session=$token&key=${GoogleKeys.apiKey}&zoom=${controller?.cameraPosition?.zoom.round() ?? 0}&north=$north&south=$south&east=$east&west=$west");

    final response = await http.get(uri);
    final Map<String, dynamic> data = jsonDecode(response.body);
    return data["copyright"];
  }
}
