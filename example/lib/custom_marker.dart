import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart'; // ignore: unnecessary_import
import 'package:maplibre_gl/maplibre_gl.dart';

import 'page.dart';

const randomMarkerNum = 100;

class CustomMarkerPage extends ExamplePage {
  const CustomMarkerPage({super.key}) : super(const Icon(Icons.place), 'Custom marker');

  @override
  Widget build(BuildContext context) {
    return const CustomMarker();
  }
}

class CustomMarker extends StatefulWidget {
  const CustomMarker({super.key});

  @override
  State createState() => CustomMarkerState();
}

class CustomMarkerState extends State<CustomMarker> {
  final _rnd = Random();

  late MapLibreMapController _mapController;
  final _markers = <Marker>[];
  final _markerStates = <MarkerState>[];

  void _addMarkerStates(MarkerState markerState) {
    _markerStates.add(markerState);
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    controller.addListener(() {
      if (controller.isCameraMoving) {
        _updateMarkerPosition();
      }
    });
  }

  void _onStyleLoadedCallback() {
    debugPrint('onStyleLoadedCallback');
  }

  // void _onMapLongClickCallback(Point<double> point, LatLng coordinates) {
  //   _addMarker(point, coordinates);
  // }

  void _onCameraIdleCallback() {
    _updateMarkerPosition();
  }

  void _updateMarkerPosition() {
    final coordinates = <LatLng>[];

    for (final markerState in _markerStates) {
      coordinates.add(markerState.getCoordinate());
    }

    _mapController.toScreenLocationBatch(coordinates).then((points) {
      _markerStates.asMap().forEach((i, value) {
        _markerStates[i].updatePosition(points[i]);
      });
    });
  }

  void _addMarker(Point<double> point, LatLng coordinates, Widget child) {
    setState(() {
      _markers.add(
        Marker(
          _rnd.nextInt(100000).toString(),
          coordinates,
          child,
          // point,
          _addMarkerStates,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        MapLibreMap(
          trackCameraPosition: true,
          onMapCreated: _onMapCreated,
          // onMapLongClick: _onMapLongClickCallback,
          onCameraIdle: _onCameraIdleCallback,
          onStyleLoadedCallback: _onStyleLoadedCallback,
          initialCameraPosition: const CameraPosition(target: LatLng(35.0, 135.0), zoom: 5),
          iosLongClickDuration: const Duration(milliseconds: 200),
        ),
        IgnorePointer(
            ignoring: false,
            child: Stack(
              children: _markers,
            ))
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //_measurePerformance();

          // Generate random markers
          final param = <LatLng>[];
          for (var i = 0; i < randomMarkerNum; i++) {
            final lat = _rnd.nextDouble() * 20 + 30;
            final lng = _rnd.nextDouble() * 20 + 125;
            param.add(LatLng(lat, lng));
          }

          _mapController.toScreenLocationBatch(param).then((value) {
            for (var i = 0; i < randomMarkerNum; i++) {
              final point = Point<double>(value[i].x as double, value[i].y as double);
              _addMarker(point, param[i], const Icon(Icons.place));
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ignore: unused_element
  void _measurePerformance() {
    const trial = 10;
    final batches = [500, 1000, 1500, 2000, 2500, 3000];
    final results = <int, List<double>>{};
    for (final batch in batches) {
      results[batch] = [0.0, 0.0];
    }

    _mapController.toScreenLocation(const LatLng(0, 0));
    final sw = Stopwatch();

    for (final batch in batches) {
      //
      // primitive
      //
      for (var i = 0; i < trial; i++) {
        sw.start();
        final list = <Future<Point<num>>>[];
        for (var j = 0; j < batch; j++) {
          final p = _mapController.toScreenLocation(LatLng(j.toDouble() % 80, j.toDouble() % 300));
          list.add(p);
        }
        Future.wait(list);
        sw.stop();
        results[batch]![0] += sw.elapsedMilliseconds;
        sw.reset();
      }

      //
      // batch
      //
      for (var i = 0; i < trial; i++) {
        sw.start();
        final param = <LatLng>[];
        for (var j = 0; j < batch; j++) {
          param.add(LatLng(j.toDouble() % 80, j.toDouble() % 300));
        }
        Future.wait([_mapController.toScreenLocationBatch(param)]);
        sw.stop();
        results[batch]![1] += sw.elapsedMilliseconds;
        sw.reset();
      }

      debugPrint(
        'batch=$batch,primitive=${results[batch]![0] / trial}ms, batch=${results[batch]![1] / trial}ms',
      );
    }
  }
}

class Marker extends StatefulWidget {
  // final Point initialPosition;
  final LatLng coordinate;
  final Widget child;
  final void Function(MarkerState) addMarkerState;

  Marker(
    String key,
    this.coordinate,
    this.child,
    this.addMarkerState,
  ) : super(key: Key(key));

  @override
  State<StatefulWidget> createState() {
    return MarkerState();
  }
}

class MarkerState extends State<Marker> with TickerProviderStateMixin {
  final _iconSize = 20.0;
  late Point _position;

  MarkerState();

  @override
  void initState() {
    super.initState();
    // Get Point from Coordinates
    _position = coordinateToPoint(widget.coordinate);
    widget.addMarkerState(this);
  }

  @override
  Widget build(BuildContext context) {
    var ratio = 1.0;

    //web does not support Platform._operatingSystem
    if (!kIsWeb) {
      // iOS returns logical pixel while Android returns screen pixel
      ratio = Platform.isIOS ? 1.0 : MediaQuery.of(context).devicePixelRatio;
    }

    return Positioned(
      width: _iconSize,
      height: _iconSize,
      left: _position.x / ratio - _iconSize / 2,
      top: _position.y / ratio - _iconSize / 2,
      child: GestureDetector(
        key: widget.key,
        onTap: () {
          debugPrint('onTap');
        },
        onLongPressMoveUpdate: (details) {
          debugPrint('onLongPressMoveUpdate ${details.localPosition}');
          updatePosition(Point(details.localPosition.dx, details.localPosition.dy));
        },
        child: widget.child,
      ),
    );
  }

  void updatePosition(Point<num> point) {
    setState(() {
      _position = point;
    });
  }

  LatLng getCoordinate() {
    return widget.coordinate;
  }

  Point coordinateToPoint(LatLng coordinate) {
    return Point(coordinate.longitude, coordinate.latitude);
  }
}
