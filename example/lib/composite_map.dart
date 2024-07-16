import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:maplibre_gl/maplibre_gl.dart';
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
  gm.GoogleMapController? googleMapController;
  MapLibreMapController? mapController;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Stack(
      children: [
        gm.GoogleMap(
          onMapCreated: _onGoogleMapCreated,
          initialCameraPosition: gm.CameraPosition(target: gm.LatLng(center.latitude, center.longitude), zoom: 13.0),
        ),
        Opacity(
          opacity: 0.5,
          child: MapLibreMap(
            // styleString: "https://api.maptiler.com/maps/topo-v2/tiles.json?key=vtLC2eJ5637uotCVnHyu",
            trackCameraPosition: true,
            onMapCreated: _onMapLibreMapCreated,
            onStyleLoadedCallback: _onMapLibreStyleLoaded,
            initialCameraPosition: const CameraPosition(target: center, zoom: 13.0),
            onCameraIdle: () {},
          ),
        ),
      ],
    );
  }

  void _onMapLibreMapCreated(MapLibreMapController controller) {
    mapController = controller;
    controller.addListener(() {
      if (controller.isCameraMoving) {
        _onMapCameraMove(controller.cameraPosition);
      }
    });
  }

  void _onGoogleMapCreated(gm.GoogleMapController controller) {
    googleMapController = controller;
  }

  void _onMapCameraMove(CameraPosition? newPosition) {
    if (newPosition == null || googleMapController == null) return;

    googleMapController!.moveCamera(
      gm.CameraUpdate.newCameraPosition(
        gm.CameraPosition(
          target: gm.LatLng(newPosition.target.latitude, newPosition.target.longitude),
          zoom: newPosition.zoom,
          bearing: mapController?.cameraPosition?.bearing ?? 0.0,
        ),
      ),
    );
  }

  void _onMapLibreStyleLoaded() {
    mapController?.addSource(
      "raster-test",
      const RasterSourceProperties(
        tiles: ["https://api.maptiler.com/maps/topo-v2/{z}/{x}/{y}.png?key=vtLC2eJ5637uotCVnHyu"],
        tileSize: 512,
        attribution:
            '<a href="https://www.maptiler.com/copyright/" target="_blank">&copy; MapTiler</a> <a href="https://www.openstreetmap.org/copyright" target="_blank">&copy; OpenStreetMap contributors</a>',
      ),
    );
    mapController?.addRasterLayer("raster-test", "raster-test", const RasterLayerProperties());

    final pesaroArea = Fill(
        "pesaro-area",
        const FillOptions(
          geometry: [
            [
              LatLng(43.898018872796854, 12.883228013054463),
              LatLng(43.896215107319506, 12.881929086519165),
              LatLng(43.894897197026495, 12.882506406992519),
              LatLng(43.89302514409863, 12.884529093301097),
              LatLng(43.89163892727356, 12.887995159144594),
              LatLng(43.89066674790544, 12.890592383154853),
              LatLng(43.889701050211386, 12.896657995028761),
              LatLng(43.88921329940956, 12.900602257746186),
              LatLng(43.88782452469428, 12.905221468591463),
              LatLng(43.887479285759184, 12.909070076238322),
              LatLng(43.888597956675255, 12.912815136528621),
              LatLng(43.88914346960709, 12.916575882784059),
              LatLng(43.88886768941606, 12.91840210313444),
              LatLng(43.88914606193876, 12.922056654286024),
              LatLng(43.88838658151499, 12.925418173560047),
              LatLng(43.88832089220915, 12.928149054289634),
              LatLng(43.887160157153886, 12.933206723439838),
              LatLng(43.888390045611374, 12.938531735735637),
              LatLng(43.89070814369691, 12.943223977154076),
              LatLng(43.89247100915253, 12.948574446307788),
              LatLng(43.894893063447256, 12.946491358484025),
              LatLng(43.90252649972342, 12.934917520315537),
              LatLng(43.908771230169634, 12.926842330332363),
              LatLng(43.91473821805832, 12.918368648816084),
              LatLng(43.9229242043142, 12.90758239743559),
              LatLng(43.923409543131214, 12.901129825699542),
              LatLng(43.916330908704225, 12.90286276721767),
              LatLng(43.91327674060469, 12.902380874706722),
              LatLng(43.91119317614235, 12.90103280776134),
              LatLng(43.910638132185966, 12.89362305645085),
              LatLng(43.91056548438016, 12.884295054787799),
              LatLng(43.90876883896479, 12.879084150527234),
              LatLng(43.90654995809007, 12.88312528048965),
            ]
          ],
          fillColor: "#FF0000",
          fillOpacity: 0.5,
        ));

    mapController?.fillManager?.add(pesaroArea);
    debugPrint("FillManager length: ${mapController?.fillManager?.annotations.length}");

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
}
