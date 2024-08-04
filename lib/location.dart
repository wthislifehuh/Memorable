import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';

class LocationPage extends StatefulWidget {
  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  Location location = new Location();
  LocationData? currentPosition;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  _getLocation() async {
    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        currentPosition = currentLocation;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Location Example"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (currentPosition != null)
              Text(
                "Latitude: ${currentPosition}, Longitude: ${currentPosition}",
              ),
            ElevatedButton(
              onPressed: () {
                _getLocation();
              },
              child: Text("Get Location"),
            ),
          ],
        ),
      ),
    );
  }
}
