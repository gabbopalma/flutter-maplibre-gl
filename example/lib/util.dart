import 'dart:math';

import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

const num earthRadius = 6371009.0;

/// Adds an asset image to the currently displayed style
Future<void> addImageFromAsset(MapLibreMapController controller, String name, String assetName) async {
  final bytes = await rootBundle.load(assetName);
  final list = bytes.buffer.asUint8List();
  return controller.addImage(name, list);
}

/// Finds the nearest segment on a line string from a given point.
///
/// [test] is the point to find the nearest segment from.
/// [target] is the list of points defining the line string.
///
/// Returns the indexes of the points defining the nearest segment on the target line.
List<int>? nearestSegmentOnLine(LatLng test, List<LatLng> target) {
  var distance = -1.0;
  LatLng? nearestPoint;

  // Define the resulting segment points.
  var startIndex = 0;
  var endIndex = 1;

  // Check for distance against each segment of the given line string to find the nearest one.
  for (var i = 0; i < target.length; i++) {
    // end = index of second point in current segment
    final end = i + 1;
    if (end >= target.length) {
      // do not consider the segment between last and first point
      continue;
    }

    // Compute distance between test point and the current segment.
    final currentDistance = distanceToLine(test, target[i], target[end]);

    // Update minimum found distance.
    if (distance == -1.0 || currentDistance < distance) {
      distance = currentDistance.toDouble();
      nearestPoint = findNearestPoint(test, target[i], target[end]);
      startIndex = i;
      endIndex = end;
    }
  }

  return nearestPoint != null ? [startIndex, endIndex] : null;
}

/// Finds the nearest point on a line string from a given point.
///
/// [test] is the point to find the nearest segment from.
/// [target] is the list of points defining the line string.
///
/// Returns the LatLng indicating the nearest point on that segment.
LatLng? nearestPointOnLine(LatLng test, List<LatLng> target) {
  var distance = -1.0;
  LatLng? nearestPoint;

  // Check for distance against each segment of the given line string to find the nearest one.
  for (var i = 0; i < target.length; i++) {
    // end = index of second point in current segment
    final end = i + 1;
    if (end >= target.length) {
      // do not consider the segment between last and first point
      continue;
    }

    // Compute distance between test point and the current segment.
    final currentDistance = distanceToLine(test, target[i], target[end]);

    // Update minimum found distance.
    if (distance == -1.0 || currentDistance < distance) {
      distance = currentDistance.toDouble();
      nearestPoint = findNearestPoint(test, target[i], target[end]);
    }
  }

  return nearestPoint;
}

/// Finds the point on the segment defined by start and end that is nearest to p.
/// Performs a projection of the point p on the given segment and returns the projected point,
/// clamped between start and end. @param p the point to project on the segment.
/// @param start the starting point of the segment.
/// @param end the ending point of the segment.
/// @return The point on the segment that is nearest to p.
LatLng findNearestPoint(LatLng p, LatLng start, LatLng end) {
  if (start == end) {
    return start;
  }
  final s0lat = degreesToRadians(p.latitude);
  final s0lng = degreesToRadians(p.longitude);
  final s1lat = degreesToRadians(start.latitude);
  final s1lng = degreesToRadians(start.longitude);
  final s2lat = degreesToRadians(end.latitude);
  final s2lng = degreesToRadians(end.longitude);
  final s2s1lat = s2lat - s1lat;
  final s2s1lng = s2lng - s1lng;
  final u = ((s0lat - s1lat) * s2s1lat + (s0lng - s1lng) * s2s1lng) / (s2s1lat * s2s1lat + s2s1lng * s2s1lng);
  if (u <= 0) {
    return start;
  }
  return u >= 1 ? end : LatLng(start.latitude + u * (end.latitude - start.latitude), start.longitude + u * (end.longitude - start.longitude));
}

/// Computes the distance on the sphere between the point p and the line
/// segment start to end.
///
/// @param p     the point to be measured
/// @param start the beginning of the line segment
/// @param end   the end of the line segment
/// @return the distance in meters (assuming spherical earth)
num distanceToLine(LatLng p, LatLng start, LatLng end) {
  if (start == end) {
    return computeDistanceBetween(end, p);
  }

  final s0lat = degreesToRadians(p.latitude);
  final s0lng = degreesToRadians(p.longitude);
  final s1lat = degreesToRadians(start.latitude);
  final s1lng = degreesToRadians(start.longitude);
  final s2lat = degreesToRadians(end.latitude);
  final s2lng = degreesToRadians(end.longitude);

  final s2s1lat = s2lat - s1lat;
  final s2s1lng = s2lng - s1lng;
  final u = ((s0lat - s1lat) * s2s1lat + (s0lng - s1lng) * s2s1lng) / (s2s1lat * s2s1lat + s2s1lng * s2s1lng);
  if (u <= 0) {
    return computeDistanceBetween(p, start);
  }
  if (u >= 1) {
    return computeDistanceBetween(p, end);
  }
  final su = LatLng(start.latitude + u * (end.latitude - start.latitude), start.longitude + u * (end.longitude - start.longitude));
  return computeDistanceBetween(p, su);
}

/// Converts degree to radian
double degreesToRadians(double deg) => deg * (pi / 180.0);

/// Returns the distance between two LatLngs, in meters.
num computeDistanceBetween(LatLng from, LatLng to) => computeAngleBetween(from, to) * earthRadius;

/// Returns the angle between two LatLngs, in radians. This is the same as the
/// distance on the unit sphere.
num computeAngleBetween(LatLng from, LatLng to) =>
    distanceRadians(degreesToRadians(from.latitude), degreesToRadians(from.longitude), degreesToRadians(to.latitude), degreesToRadians(to.longitude));

/// Returns distance on the unit sphere; the arguments are in radians.
num distanceRadians(num lat1, num lng1, num lat2, num lng2) => arcHav(havDistance(lat1, lat2, lng1 - lng2));

/// Computes inverse haversine. Has good numerical stability around 0.
/// arcHav(x) == acos(1 - 2 * x) == 2 * asin(sqrt(x)).
/// The argument must be in [0, 1], and the result is positive.
num arcHav(num x) => 2 * asin(sqrt(x));

/// Returns hav() of distance from (lat1, lng1) to (lat2, lng2) on the unit
/// sphere.
num havDistance(num lat1, num lat2, num dLng) => hav(lat1 - lat2) + hav(dLng) * cos(lat1) * cos(lat2);

/// Returns haversine(angle-in-radians).
/// hav(x) == (1 - cos(x)) / 2 == sin(x / 2)^2.
num hav(num x) => sin(x * 0.5) * sin(x * 0.5);
