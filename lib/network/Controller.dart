import 'dart:convert';
import 'package:http/http.dart' as http;

class TripController {
  Future<Object> getTrips(tripId) async {
    final url = 'https://apimyride.dark-innovations.com/trips/${tripId}/locations';
    final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json'
        }
    );

    if (response.statusCode == 200) {
      final resp = jsonDecode(response.body);
      return resp;
    } else {
      return {
        "ok": false
      };
    }
  }
}