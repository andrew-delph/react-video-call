// import 'dart:html' as html;
// import 'dart:ui' as ui;
//
// import 'package:flutter/material.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart' as mobile;
// import 'package:google_maps/google_maps.dart' as maps;
//
// import '../../utils.dart';
//
// class MapWidget extends StatelessWidget {
//   final Pair<double, double> posPair;
//   final double radius;
//
//   const MapWidget({Key? key, required this.posPair, required this.radius})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return _buildWebMap();
//     // return kIsWeb ? _buildWebMap() : _buildMobileMap();
//   }
//
//   // Widget _buildMobileMap() {
//   //   return mobile.GoogleMap(
//   //     initialCameraPosition: mobile.CameraPosition(
//   //       target: mobile.LatLng(center.latitude, center.longitude),
//   //       zoom: 12,
//   //     ),
//   //     circles: {
//   //       mobile.Circle(
//   //         circleId: mobile.CircleId('radius_circle'),
//   //         center: mobile.LatLng(center.latitude, center.longitude),
//   //         radius: radius,
//   //         fillColor: Colors.blue.withOpacity(0.2),
//   //         strokeWidth: 2,
//   //         strokeColor: Colors.blue,
//   //       ),
//   //     },
//   //   );
//   // }
//
//   Widget _buildWebMap() {
//     String htmlId = "map";
//
//     final center = maps.LatLng(posPair.first, posPair.second);
//
//     // ignore: undefined_prefixed_name
//     ui.platformViewRegistry.registerViewFactory(htmlId, (int viewId) {
//       final mapOptions = maps.MapOptions();
//       mapOptions.zoom = 5;
//       mapOptions.center = center;
//
//       final elem = html.DivElement();
//       elem.id = htmlId;
//       elem.style.width = "100%";
//       elem.style.height = "100%";
//       elem.style.border = 'none';
//
//       final map = maps.GMap(elem, mapOptions);
//
//       maps.Marker(maps.MarkerOptions()
//         ..position = center
//         ..map = map
//         ..title = 'Hello World!');
//
//       return elem;
//     });
//
//     return HtmlElementView(viewType: htmlId);
//   }
// }

import 'dart:html';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps/google_maps.dart';

import 'map_widget.dart';

MapWidget getMapWidget() => WebMap();

class WebMap extends StatefulWidget implements MapWidget {
  WebMap({Key? key}) : super(key: key);

  @override
  State<WebMap> createState() => WebMapState();
}

class WebMapState extends State<WebMap> {
  @override
  Widget build(BuildContext context) {
    final String htmlId = "map";

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(htmlId, (int viewId) {
      final mapOptions = MapOptions()
        ..zoom = 15.0
        ..center = LatLng(35.7560423, 139.7803552);

      final elem = DivElement()..id = htmlId;
      final map = GMap(elem, mapOptions);

      map.onCenterChanged.listen((event) {});
      map.onDragstart.listen((event) {});
      map.onDragend.listen((event) {});

      Marker(MarkerOptions()
        ..position = map.center
        ..map = map);

      return elem;
    });
    return HtmlElementView(viewType: htmlId);
  }
}
