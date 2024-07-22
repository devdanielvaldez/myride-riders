import 'package:flutter/material.dart';
import '../model/BusRoute.dart';
import '../utils/Colors.dart';
import '../utils/Extensions/app_common.dart';
import 'BusRouteMapScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BusRouteListScreen extends StatefulWidget {
  @override
  _BusRouteListScreenState createState() => _BusRouteListScreenState();
}

class _BusRouteListScreenState extends State<BusRouteListScreen> {
  late Future<List<BusRouteModel>> futureBusRoutes;

  @override
  void initState() {
    super.initState();
    futureBusRoutes = fetchBusRoutes();
  }

  Future<List<BusRouteModel>> fetchBusRoutes() async {
    final response = await http.get(Uri.parse('https://apimyride.dark-innovations.com/buses'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => BusRouteModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load bus routes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Rutas de Buses", style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: FutureBuilder<List<BusRouteModel>>(
        future: futureBusRoutes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error al cargar las rutas de buses'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay rutas de buses disponibles'));
          } else {
            List<BusRouteModel> busRoutes = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: busRoutes.length,
              itemBuilder: (context, index) {
                BusRouteModel route = busRoutes[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BusRouteMapScreen(route: route),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(route.name, style: boldTextStyle(size: 18)),
                          SizedBox(height: 8),
                          Text("Horario de Salida: ${route.horaSalida}", style: secondaryTextStyle()),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.near_me, color: Colors.green),
                              SizedBox(width: 8),
                              Expanded(child: Text("Partida: ${route.pointA}", style: primaryTextStyle())),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(child: Text("Llegada: ${route.pointB}", style: primaryTextStyle())),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}