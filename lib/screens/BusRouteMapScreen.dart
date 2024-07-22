import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:rider_my/model/BusRoute.dart';
import 'package:http/http.dart' as http;
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/images.dart';

class BusRouteMapScreen extends StatefulWidget {
  final BusRouteModel route;

  BusRouteMapScreen({required this.route});

  @override
  _BusRouteMapScreenState createState() => _BusRouteMapScreenState();
}

class _BusRouteMapScreenState extends State<BusRouteMapScreen> {
  Completer<GoogleMapController> _controller = Completer();
  List<LatLng> polylineCoordinates = [];
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  BitmapDescriptor? vehicleIcon; // Changed to nullable
  late BitmapDescriptor driverIcon;
  late LatLng currentPosition;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadVehicleIcon();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setInitialLocation() {
    LatLng startLocation = widget.route.pointALatLng;
    LatLng endLocation = widget.route.pointBLatLng;

    setState(() {
      currentPosition = startLocation;
      _markers.add(Marker(
        markerId: MarkerId('start'),
        position: startLocation,
        icon: BitmapDescriptor.defaultMarker, // Use a default marker initially
        infoWindow: InfoWindow(title: "Partida"),
      ));
      _markers.add(Marker(
        markerId: MarkerId('end'),
        position: endLocation,
        infoWindow: InfoWindow(title: "Llegada"),
      ));

      _markers.add(
        Marker(
          markerId: MarkerId('Bus'),
          position: startLocation,
          infoWindow: InfoWindow(title: 'Bus'),
          icon: driverIcon,
          rotation: calculateAngle(startLocation, endLocation)
        ),
      );

      _createPolylines(startLocation, endLocation);
    });
  }

  double calculateAngle(LatLng start, LatLng end) {
    double dx = end.latitude - start.latitude;
    double dy = end.longitude - start.longitude;
    double angle = (atan2(dy, dx) * 180.0 / pi) + 90.0;  // +90 para ajustar el ángulo
    return angle;
  }

  void _createPolylines(LatLng start, LatLng end) async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineRequest request = PolylineRequest(
      origin: PointLatLng(start.latitude, start.longitude),
      destination: PointLatLng(end.latitude, end.longitude), mode: TravelMode.driving,
      // Aquí puedes agregar otros parámetros opcionales si es necesario
    );
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: GOOGLE_MAP_API_KEY,
      request: request
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });

      setState(() {
        _polylines.add(Polyline(
          polylineId: PolylineId("poly"),
          color: Color.fromARGB(255, 40, 122, 198),
          points: polylineCoordinates,
          width: 8,
        ));
      });
    }
  }

  void _loadVehicleIcon() async {
    driverIcon = await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 0.5), MultipleDriver);
    _setInitialLocation(); // Moved here to ensure vehicleIcon is loaded
    _startFetchingVehicleLocation();
  }

  void _startFetchingVehicleLocation() {
    _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
      await _fetchVehicleLocation();
    });
  }

  Future<void> _fetchVehicleLocation() async {
    final response = await http.get(Uri.parse('https://apimyride.dark-innovations.com/buses/${widget.route.id}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      double latitude = data['locations'][0]['latitude'];
      double longitude = data['locations'][0]['longitude'];

      setState(() {
        currentPosition = LatLng(latitude, longitude);
        _markers.removeWhere((marker) => marker.markerId.value == 'vehicle');
        _markers.add(Marker(
          markerId: MarkerId('Bus'),
          position: currentPosition,
          icon: driverIcon, // Ensure vehicleIcon is not null
          infoWindow: InfoWindow(title: "Bus"),
        ));
      });

      if (_controller.isCompleted) {
        GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLng(currentPosition));
      }
    } else {
      throw Exception('Failed to load vehicle location');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.route.name, style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.route.pointALatLng,
          zoom: 17,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        trafficEnabled: true,
        markers: _markers,
        polylines: _polylines,
        buildingsEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }
}