import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';

class VictimTrackingLivePage extends StatefulWidget {
  @override
  _VictimTrackingLivePageState createState() => _VictimTrackingLivePageState();
}

class _VictimTrackingLivePageState extends State<VictimTrackingLivePage> {
  GoogleMapController? _mapController;
  Map<String, LatLng> _trackedUsers = {};
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('users_tracking');

  @override
  void initState() {
    super.initState();
    _listenToUserLocations();
  }

  void _listenToUserLocations() {
    _databaseReference.onValue.listen((event) {
      try {
        final data = event.snapshot.value as Map?;
        if (data != null) {
          Map<String, LatLng> users = {};
          data.forEach((key, value) {
            if (value is Map && value['isTracking'] == true) {
              final latitude = value['location']?['latitude'];
              final longitude = value['location']?['longitude'];

              if (latitude != null && longitude != null) {
                users[key] = LatLng(latitude, longitude);
              } else {
                debugPrint("Skipping user $key due to missing coordinates.");
              }
            }
          });

          setState(() {
            _trackedUsers = users;
          });

          if (users.isNotEmpty) {
            _showDataFoundPopup(users.length);
          }

          if (_mapController != null && users.isNotEmpty) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(users.values.first),
            );
          }
        } else {
          setState(() {
            _trackedUsers.clear();
          });
          _showNoDataPopup();
          debugPrint("No data found for users tracking.");
        }
      } catch (e) {
        debugPrint("Error processing user location data: $e");
        _showErrorPopup();
      }
    });
  }

  // Popup dialog for no data found
  void _showNoDataPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("No Data"),
          content: Text("No tracking data is available."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Popup dialog for error handling
  void _showErrorPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text("An error occurred while fetching tracking data."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Popup dialog when data is found
  void _showDataFoundPopup(int userCount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Data Found"),
          content: Text("$userCount user(s) are being tracked."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live User Tracking")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(11.2588, 75.7804), // Default position
          zoom: 13,
        ),
        onMapCreated: (controller) => _mapController = controller,
        markers: _trackedUsers.entries.map((entry) {
          return Marker(
            markerId: MarkerId(entry.key),
            position: entry.value,
            infoWindow: InfoWindow(title: "User: ${entry.key}"),
          );
        }).toSet(),
      ),
    );
  }
}
