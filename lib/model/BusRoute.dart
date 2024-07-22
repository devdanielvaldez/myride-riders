import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusRouteModel {
  final String id;
  final String busId;
  final String name;
  final String pointA;
  final String pointB;
  final LatLng pointALatLng;
  final LatLng pointBLatLng;
  final String horaSalida;

  BusRouteModel({
    required this.id,
    required this.busId,
    required this.name,
    required this.pointA,
    required this.pointB,
    required this.pointALatLng,
    required this.pointBLatLng,
    required this.horaSalida,
  });

  factory BusRouteModel.fromJson(Map<String, dynamic> json) {
    return BusRouteModel(
      id: json['_id'],
      busId: json['busId'],
      name: json['name'],
      pointA: json['pointA'],
      pointB: json['pointB'],
      pointALatLng: LatLng(double.parse(json['pointALat']), double.parse(json['pointALong'])),
      pointBLatLng: LatLng(double.parse(json['pointBLat']), double.parse(json['pointBLong'])),
      horaSalida: json['horaSalida'],
    );
  }
}