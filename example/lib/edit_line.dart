import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:maplibre_gl_example/page.dart';
import 'package:maplibre_gl_example/util.dart';
import 'package:turf/helpers.dart' as turf;
import 'package:turf/src/nearest_point_on_line.dart' as turfLine show nearestPointOnLine;

class EditLinePage extends ExamplePage {
  const EditLinePage({super.key}) : super(const Icon(Icons.gesture_outlined), 'Edit Line');

  @override
  Widget build(BuildContext context) {
    return const EditLineBody();
  }
}

class EditLineBody extends StatefulWidget {
  const EditLineBody({super.key});

  @override
  State<StatefulWidget> createState() => EditLineBodyState();
}

class EditLineBodyState extends State<EditLineBody> {
  EditLineBodyState();

  static const LatLng center = LatLng(44.387975, 7.548834);

  MapLibreMapController? controller;
  LineManager? lineManager;

  static const polylinePoints = <LatLng>[
    LatLng(44.38876634816316, 7.547145078554337),
    LatLng(44.38797680237073, 7.548805592059722),
    LatLng(44.387875403906634, 7.548782277210222),
    LatLng(44.387774151082, 7.548844883260671),
    LatLng(44.38774667935502, 7.549005242620325),
    LatLng(44.387798483172304, 7.549134848129796),
    LatLng(44.38790680009623, 7.5491831756086185),
    LatLng(44.38799863385253, 7.549106290983843),
    LatLng(44.38806613550014, 7.549183175612342),
    LatLng(44.388435860404485, 7.549587933416916),
    LatLng(44.38872161965884, 7.549908040147841),
  ];

  void _onMapCreated(MapLibreMapController controller) {
    this.controller = controller;
    controller.onFeatureDrag.add(_onFeatureDrag);
  }

  @override
  void dispose() {
    controller?.onFeatureDrag.remove(_onFeatureDrag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoadedCallback,
      onMapClick: _onMapClick,
      // onMapLongClick: _onMapLongClcick,
      initialCameraPosition: const CameraPosition(target: center, zoom: 16.0),
    );
  }

  Future<void> _onStyleLoadedCallback() async {
    lineManager = controller?.lineManager;
    addImageFromAsset("assetImage", "assets/symbols/custom-icon.png");

    // Add a line to the map
    final lineToEdit = Line(
      "lineToEdit",
      const LineOptions(
        geometry: polylinePoints,
        lineColor: '#ff0000',
        lineWidth: 3.0,
        draggable: false,
      ),
    );

    controller?.lineManager?.add(lineToEdit);

    controller?.setSymbolIconAllowOverlap(true);

    // Add draggable markers for each polyline vertex.
    for (final point in polylinePoints) {
      final symbol = Symbol(
        "${lineToEdit.id}-${polylinePoints.indexOf(point)}",
        SymbolOptions(
          draggable: true,
          geometry: point,
          iconSize: 2.0,
          iconAnchor: "center",
          iconImage: "assetImage",
        ),
      );
      await controller?.symbolManager?.add(symbol);
    }
  }

  Future<void> _onMapClick(Point<double> point, LatLng coordinates) async {
    debugPrint("Click at: $coordinates");
    final lineToEdit = controller?.lineManager?.annotations.firstWhereOrNull((Line line) => line.id.contains("lineToEdit"));

    if (lineToEdit != null) {
      await _addVertexToLine(lineToEdit.id, coordinates);
    }
  }

  // Future<void> _onMapLongClick(Point<double> point, LatLng coordinates) async {
  //   debugPrint("Long click at: $coordinates");
  //   // Find the closest segment (so the point) on the line to the click event
  //   final lineToEdit = controller?.lineManager?.annotations.firstWhereOrNull((Line line) => line.id.contains("lineToEdit"));

  //   if (lineToEdit != null) {
  //     final nearestPoint = nearestSegmentOnLine(coordinates, lineToEdit.options.geometry!)?.first;
  //     if (nearestPoint == null) return;

  //     final pointIndex = nearestPoint + 1;
  //     await _addVertexToLine(lineToEdit.id, coordinates, pointIndex: pointIndex);
  //   }
  // }

  Future<void> _addVertexToLine(String symbolId, LatLng coords, {int? pointIndex}) async {
    if (pointIndex == -1) return;
    final editingLine = lineManager!.annotations.firstWhereOrNull((element) => symbolId.contains(element.id));

    if (editingLine == null) return;

    final List<LatLng> newGeometry;
    if (pointIndex != null) {
      newGeometry = List.from(editingLine.options.geometry!)..insert(pointIndex, coords);
    } else {
      newGeometry = List.from(editingLine.options.geometry!)..add(coords);
    }

    await controller?.updateLine(
      editingLine,
      LineOptions(
        geometry: newGeometry,
        lineColor: '#ff0000',
        lineWidth: 3.0,
        draggable: false,
      ),
    );

    // Add a new marker for the new vertex
    final symbol = Symbol(
      "${editingLine.id}-${newGeometry.indexOf(coords)}",
      SymbolOptions(
        draggable: true,
        geometry: coords,
        iconSize: 2.0,
        iconAnchor: "center",
        iconImage: "assetImage",
      ),
    );

    await controller?.symbolManager?.add(symbol);
  }

  Future<void> _updateLineVertex(String symbolId, int pointIndex, LatLng current) async {
    final editingLine = lineManager!.annotations.firstWhereOrNull((element) => symbolId.contains(element.id));

    if (pointIndex == -1 || editingLine == null) return;
    await controller?.updateLine(
      editingLine,
      LineOptions(
        geometry: List.from(editingLine.options.geometry!)
          ..removeAt(pointIndex)
          ..insert(pointIndex, current),
        lineColor: '#ff0000',
        lineWidth: 3.0,
        draggable: false,
      ),
    );
  }

  int getLineVertexFromId(String id) => int.parse(id.split('-').last);

  Future<void> _onFeatureDrag(id, {required LatLng current, required LatLng delta, required DragEventType eventType, required LatLng origin, required Point<double> point}) async {
    final pointIndex = getLineVertexFromId(id);

    if (eventType == DragEventType.drag) {
      await _updateLineVertex(id, pointIndex, current);
    }
  }

  /// Adds an asset image to the currently displayed style
  Future<void> addImageFromAsset(String name, String assetName) async {
    final bytes = await rootBundle.load(assetName);
    final list = bytes.buffer.asUint8List();
    return controller!.addImage(name, list);
  }
}
