import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutterapp/mobiletourism.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../widgets/progressIndicator.dart'; // Import the custom widget
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';

class CameraOverlayPage extends StatefulWidget {
  final String imagePath;
  final List<CameraDescription> cameras;

  const CameraOverlayPage(
      {required this.imagePath, required this.cameras, Key? key})
      : super(key: key);

  @override
  _CameraOverlayPageState createState() => _CameraOverlayPageState();
}

class _CameraOverlayPageState extends State<CameraOverlayPage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  double _progress = 0.0;
  bool _isVertical = false;
  late StreamSubscription accel;
  late StreamSubscription<LocationData> _locationSubscription;
  Location location = new Location();
  LocationData? currentPosition;
  final int hardcodeHeading = 155;
  final double hardcodeLatitude = 4.3398998;
  final double hardcodeLongitude = 101.1377792;

  @override
  void initState() {
    super.initState();
    Geolocator.requestPermission();
    _cameraController = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _cameraController.initialize();
    _simulateProgress();
    // _monitorDeviceOrientation();
    _getLocation();
  }

  _getLocation() async {
    _locationSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        currentPosition = currentLocation;
      });
    });
  }

  void _simulateProgress() {
    // Simulate progress for demonstration purposes
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_progress < 1.0) {
        setState(() {
          _progress += 0.01;
        });
        _simulateProgress();
      }
    });
  }

  void _monitorDeviceOrientation() {
    accel = accelerometerEvents.listen((AccelerometerEvent event) {
      double x = event.x;
      double y = event.y;

      // Determine if the device is held vertically or horizontally
      if ((y).abs() > (x).abs()) {
        setState(() {
          _isVertical = true;
        });
      } else {
        setState(() {
          _isVertical = false;
        });
      }
    });
  }

  int _calculateMatchPercentage(heading, latitude, longitude) {
    // Hardcoded values for demonstration purposes
    // In a real-world scenario, these values would be obtained from the device's sensors
    // and the device's location
    double deviceHeading = hardcodeHeading.toDouble();
    double deviceLatitude = hardcodeLatitude;
    double deviceLongitude = hardcodeLongitude;

    // Calculate the difference between the device's heading and the heading of the object
    double headingDifference = (heading - deviceHeading).abs();
    if (headingDifference > 180) {
      headingDifference = 360 - headingDifference;
    }

    // Calculate the difference between the device's latitude and the latitude of the object
    double latitudeDifference = (latitude - deviceLatitude).abs();

    // Calculate the difference between the device's longitude and the longitude of the object
    double longitudeDifference = (longitude - deviceLongitude).abs();

    // Calculate the match percentage based on the differences
    double matchPercentage = 100 -
        (headingDifference + latitudeDifference + longitudeDifference) / 3;

    if (matchPercentage.round() == 100) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => MobileTourismWidget(uid: 'o7hYM5Rw6fO71Jhm81Lt8sIkeiC3',)));
    }
    return matchPercentage.round();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    accel.cancel();
    _locationSubscription.cancel();
    super.dispose();
  }

  Widget _buildCompass() {
    return StreamBuilder(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error reading heading: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        double? direction = snapshot.data!.heading;

        // if direction is null, then device does not support this sensor
        // show error message
        if (direction == null)
          return Center(
            child: Text("Device does not have sensors !"),
          );

        return Material(
          shape: CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          child: Container(
            padding: EdgeInsets.all(16.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Transform.rotate(
              angle: (direction * (math.pi / 180) * -1),
              child: Image.asset('assets/compass.jpg'),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_cameraController);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          Center(
            child: Opacity(
              opacity: 1,
              child: Image.asset(
                widget.imagePath,
                width: 300,
                height: 300,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: StreamBuilder(
                stream: FlutterCompass.events,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error reading heading: ${snapshot.error}');
                  }
                  double? direction = snapshot.data!.heading;
                  return CircularPercentageIndicator(
                      progress: _calculateMatchPercentage(
                                  direction,
                                  currentPosition?.latitude,
                                  currentPosition?.longitude)
                              .toDouble() /
                          100);
                },
              ),
            ),
          ),
          Positioned(
            top: 35,
            left: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Image.asset(
                'assets/back.png',
                width: 50,
                height: 50,
              ),
            ),
          ),
          // if (_isVertical)
          Stack(
            children: [
              // Center(
              //   child: Container(
              //       padding: const EdgeInsets.all(16),
              //       color: Colors.red.withOpacity(0.7),
              //       child: Row(
              //         mainAxisAlignment: MainAxisAlignment.center,
              //         children: [
              //           Image.asset(
              //             'assets/warning.png',
              //             width: 20,
              //             height: 20,
              //           ),
              //           const SizedBox(width: 10),
              //           const Text(
              //             'Please hold the device horizontally.',
              //             style: TextStyle(color: Colors.white, fontSize: 20),
              //             textAlign: TextAlign.center,
              //           ),
              //         ],
              //       )),
              // ),
              // Align(
              //   alignment: Alignment.bottomCenter,
              //   child: Padding(
              //     padding: const EdgeInsets.only(bottom: 30),
              //     child: Image.asset(
              //       'assets/horizontalDevice.png',
              //       width: 100,
              //       height: 100,
              //     ),
              //   ),
              // ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: StreamBuilder(
                    stream: FlutterCompass.events,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error reading heading: ${snapshot.error}');
                      }
                      double? direction = snapshot.data!.heading;
                      return Text(
                        'Heading: ${direction != null ? direction.toStringAsFixed(0) : '0'}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    "Latitude: ${currentPosition?.latitude}, Longitude: ${currentPosition?.longitude}",
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: StreamBuilder(
                    stream: FlutterCompass.events,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error reading heading: ${snapshot.error}');
                      }
                      double? direction = snapshot.data!.heading;
                      return Text(
                        "Match Percentage: ${_calculateMatchPercentage(direction, currentPosition?.latitude, currentPosition?.longitude)}%",
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
