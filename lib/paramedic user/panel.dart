import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medic/paramedic user/patient_info.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medic/paramedic user/appbar.dart';
import 'package:medic/paramedic%20user/paramedic_profile_SettingsButtons.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:geolocator_platform_interface/src/enums/location_accuracy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medic/paramedic user/get_patient_info.dart';
import 'package:medic/paramedic user/paramedic_profile.dart';


class Online extends StatefulWidget {
  const Online({Key? key}) : super(key: key);

  @override
  State<Online> createState() => _Online();
}

class _Online extends State<Online> {
  //patient id and hospital id
  var result1;
  var patientHospital;

  //User's Assigned patient
  String assignedPatientID = '';

  //Proximity Checking
  final double proximityThreshold = 100;
  bool showAlert = false;
  double destinationLat = 0;
  double destinationLong = 0;

  //Patient Info, class initializations
  final testService = FirebaseService();
  final patientID = patientId();
  final users = FirebaseFirestore.instance.collection('users');
  final user = FirebaseAuth.instance.currentUser!;

  //Polypoints or routes of the map between locations
  List<LatLng> _polylineCoordinates = [];

  Future<List<LatLng>> getPolyPoints(latitude1, longitude1, latitude2, longitude2) async {
    List<LatLng> polylineCoordinates = [];

    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        "AIzaSyAS8T5voHU_bam5GCQIELBbWirb9bCZZOA",
        PointLatLng(latitude1, longitude1),
        PointLatLng(latitude2, longitude2),
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    return polylineCoordinates;
  }

//"AIzaSyAS8T5voHU_bam5GCQIELBbWirb9bCZZOA"

  //Marker Section of the map
  Set<Marker> _markers = {};

  void _addMarker(LatLng position, String markerId) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: position,
        ),
      );
    });
  }

  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();

  //Position Values
  Position? currentPosition;
  LatLng newloc = LatLng(14.345999,121);
  StreamSubscription<Position>? positionStream;

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
    /// don't forget to cancel stream once no longer needed
  }

  @override
  void initState() {
    super.initState();
    listenToLocationChanges();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar('MedIC'),
      body: WillPopScope(
        onWillPop: () async {
          bool shouldPop = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content:
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 30, 0, 30),
                  child: Text(
                    'Going Offline?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inria Sans',
                      color: Color(0xFFA60101),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                        Radius.circular(32.0))),
                actions: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          patientID.updateUserStatusField("availability","Offline");
                          _markers.clear();
                          _polylineCoordinates.clear();
                          dispose();
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ParamedPage()));
                          // Navigator.pop(context);
                          // Navigator.pop(context);
                          // Navigator.pop(context);
                        },
                        child: Text(
                          'Yes',
                          style: TextStyle(color: Color.fromRGBO(123, 189,
                              99, 1)),
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 5,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent.withOpacity(
                              0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: VerticalDivider(
                          width: 0,
                          thickness: 1,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, 'Cancel'),
                        child: Text(
                          'No',
                          style: TextStyle(color: Color.fromRGBO(227, 0,
                              42, 1)),
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 5,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent.withOpacity(
                              0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
          return shouldPop;
        },
        child: SlidingUpPanel(
          panel: Center(
            child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(15, 15, 0, 0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Paramedic Status',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(195, 0, 36, 1),
                              ),
                            ),
                          ]
                      )
                  ),
                  FutureBuilder(
                      future: users.where('Email', isEqualTo: user.email).get(),
                      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          var result1 = snapshot.data?.docs[0].get('assigned_patient')['assign_patient'];
                          var status = snapshot.data?.docs[0].get('status');
                          var availability = snapshot.data?.docs[0].get('availability');
                          var time = snapshot.data?.docs[0].get('time remaining');
                          var patientHospital = snapshot.data?.docs[0].get('assigned_patient')['hospital_id'];
                          print(result1+" "+patientHospital);
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(15, 15, 0, 5),
                                      child: Row(
                                          children: [
                                            Text(
                                              'Availability: ',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color.fromRGBO(227, 0, 42, 1),
                                              ),
                                            ),
                                            Text(
                                              "$availability",
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color.fromRGBO(54, 205, 1, 1),
                                              ),
                                            ),
                                          ]
                                      )
                                  ),
                                  Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(15, 15, 15, 5),
                                      child: Row(
                                          children: [
                                            Text(
                                              'Status: ',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color.fromRGBO(227, 0, 42, 1),
                                              ),
                                            ),
                                            Text(
                                              "$status",
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color.fromRGBO(54, 205, 1, 1),
                                              ),
                                            ),
                                          ]
                                      )
                                  ),
                                ],
                              ),
                              const Divider(
                                height: 0,
                                thickness: 2,
                              ),
                              Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(15, 15, 0, 0),
                                  child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.personal_injury, // Replace with your desired icon
                                          size: 30.0, // Customize the icon size
                                          color: Color(0xFFba181b), // Customize the icon color
                                        ),
                                        Text(
                                          'Patient Information',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromRGBO(195, 0, 36, 1),
                                          ),
                                        ),
                                      ]
                                  )
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(0, 5, 0, 0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(15, 5, 0, 0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Name:',
                                            style: TextStyle(color: Color.fromRGBO(195, 0, 36, 1),),
                                          ),patientInfo("Name","$result1","$patientHospital"),
                                          Text(
                                            'Age: ',
                                            style: TextStyle(color: Color.fromRGBO(195, 0, 36, 1),),
                                          ),patientInfo("Age","$result1","$patientHospital"),
                                          Text(
                                            'Sex:',
                                            style: TextStyle(color: Color.fromRGBO(195, 0, 36, 1),),
                                          ),patientInfo("Sex","$result1","$patientHospital"),
                                          Text(
                                            'Concerns:',
                                            style: TextStyle(color: Color.fromRGBO(195, 0, 36, 1),),
                                          ),patientInfo("Main Concerns","$result1","$patientHospital"),
                                          Text(
                                            'Symptoms:',
                                            style: TextStyle(color: Color.fromRGBO(195, 0, 36, 1),),
                                          ),patientInfo("Symptoms","$result1","$patientHospital"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(0, 10, 0, 0),
                                child: Divider(
                                  height: 0,
                                  thickness: 2,
                                ),
                              ),
                              Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(15, 15, 0, 5),
                                  child: Row(
                                      children: [
                                        Text(
                                          'ETA: ',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromRGBO(227, 0, 42, 1),
                                          ),
                                        ),
                                        Text(
                                          "$time",
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromRGBO(54, 205, 1, 1),
                                          ),
                                        ),
                                      ]
                                  )
                              ),
                              const Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(0, 10, 0, 0),
                                child: Divider(
                                  height: 0,
                                  thickness: 2,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(15, 10, 0, 0),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Patient Options:',
                                      style: TextStyle(
                                        color: Color.fromRGBO(195, 0, 36, 1),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          var locationValue = await testService.getFieldData("$result1", "Location");
                                          print(locationValue);
                                          setState(() {
                                            destinationLat = 10.653628;
                                            destinationLong = 122.227449;
                                            // destinationLat = double.tryParse(locationValue['Latitude']) ?? 0.0;
                                            // destinationLong = double.tryParse(locationValue['Longitude']) ?? 0.0;
                                          });
                                          _addMarker(
                                            LatLng(
                                              destinationLat,
                                              destinationLong,
                                            ),
                                            'Patient Location',
                                          );
                                          List<LatLng> coordinates = await getPolyPoints(
                                            currentPosition!.latitude,
                                            currentPosition!.longitude,
                                            destinationLat,
                                            destinationLong,
                                          );
                                          setState(() {
                                            _polylineCoordinates = coordinates;
                                          });
                                        } catch (e) {
                                          print('Error fetching location data: $e');
                                        }
                                      },

                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFFba181b)),
                                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20.0),
                                          ),
                                        ),
                                      ),
                                      child: Text("Display Route"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          setState(() {
                                            destinationLat = 10.648623;
                                            destinationLong = 122.226581;
                                          });
                                          _addMarker(
                                            LatLng(
                                              destinationLat,
                                              destinationLong,
                                            ),
                                            'Hospital Location',
                                          );
                                          List<LatLng> coordinates = await getPolyPoints(
                                            currentPosition!.latitude,
                                            currentPosition!.longitude,
                                            destinationLat,
                                            destinationLong,
                                          );
                                          setState(() {
                                            _polylineCoordinates = coordinates;
                                          });
                                        } catch (e) {
                                          print('Error fetching location data: $e');
                                        }
                                      },

                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFFba181b)),
                                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20.0),
                                          ),
                                        ),
                                      ),
                                      child: Text("Overwrite Location Value to Mercury"),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        return CircularProgressIndicator();
                      }
                  ),
                ]
            ),
          ),
          body:
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: newloc, // Initial map position
              zoom: 5,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers: Set.of(_markers),
            polylines: {
              Polyline(
                polylineId: PolylineId('route'),
                points: _polylineCoordinates,
                color: Colors.blue,
                width: 4,
              ),
            },
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
    );
  }

  /// Determine the current position of the device
  Future<dynamic> _determinePosition() async {
    // Test if location services are enabled.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
      print('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      print('Location permissions are denied');
      return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      print('Location permissions are permanently denied, we cannot request permissions.');

      /// open app settings so that user changes permissions
      // await Geolocator.openAppSettings();
      // await Geolocator.openLocationSettings();

      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition();
    print("Current Position $position");

    setState(() {
      currentPosition = position;
    });
    //return position;
    }

  void getLastKnownPosition() async {
    Position? position = await Geolocator.getLastKnownPosition();
  }

  void listenToLocationChanges() {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position? position) {
            setState(() {
              currentPosition = position;
              LatLng currentloc = LatLng(currentPosition!.latitude,currentPosition!.longitude) ;
              _addMarker(currentloc, "current Location");
              animateToLocation(currentloc);

                if (destinationLat != 0 && destinationLong != 0) {
                  updatePolyPoints();
                }

                double distanceInMeters = Geolocator.distanceBetween(
                  currentPosition!.latitude,
                  currentPosition!.longitude,
                  destinationLat,
                  destinationLong,
                );

                if (distanceInMeters <= proximityThreshold && !showAlert) {
                  //Code to check if marker is for hospital
                  final List<Marker> markerList = _markers.toList();
                  Marker? hospitalMarker;

                  for (final marker in markerList) {
                    if (marker.markerId.value == 'Hospital Location') {
                      hospitalMarker = marker;
                      break;
                    }
                  }

                  if (hospitalMarker != null) {
                    _showHospitalAlertDialog();
                  }else{
                    _showProximityAlertDialog();
                  }
                }
            });
            },

    );
  }

  void animateToLocation(LatLng location) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(location,15),
    );
  }

  void calculateDistance() {
    /// startLatitude, startLongitude, endLatitude, endLongitude
    double distanceInMeters = Geolocator.distanceBetween(52.2165157, 6.9437819, 52.3546274, 4.8285838);
  }

  void _showProximityAlertDialog() {
    showAlert = true;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return
          AlertDialog(
            content:
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0, 30, 0, 30),
              child: Text(
                "Have you arrived at the Patient's Location?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inria Sans',
                  color: Color(0xFFA60101),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                    Radius.circular(32.0))),
            actions: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _markers.clear();
                      _polylineCoordinates.clear();
                      showAlert = false;
                      destinationLat = 0.0;
                      destinationLong =  0.0;
                      //getHospitalLocation();

                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 5,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent.withOpacity(
                          0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Yes',
                      style: TextStyle(color: Color.fromRGBO(123, 189,
                          99, 1)),
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                    child: VerticalDivider(
                      width: 0,
                      thickness: 1,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showAlert = false;// Dismiss the dialog
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 5,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent.withOpacity(
                          0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'No',
                      style: TextStyle(color: Color.fromRGBO(227, 0,
                          42, 1)),
                    ),
                  ),
                ],
              ),
            ],
          );
      },
    );
  }


  void _showHospitalAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return
          AlertDialog(
            content:
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0, 30, 0, 30),
              child: Text(
                'Have you arrived at the Hospital?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inria Sans',
                  color: Color(0xFFA60101),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                    Radius.circular(32.0))),
            actions: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _markers.clear();
                      _polylineCoordinates.clear();
                      patientID.updateUserStatusField("status","Unassigned");
                      patientID.updatePatientStatusField("Service in use", "Emergency Room", result1, patientHospital);
                      patientID.updatePatientStatusField("Status", "In-Patient", result1, patientHospital);
                      setState(() {});
                    },
                    child: Text(
                      'Yes',
                      style: TextStyle(color: Color.fromRGBO(123, 189,
                          99, 1)),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 5,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent.withOpacity(
                          0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: VerticalDivider(
                      width: 0,
                      thickness: 1,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Dismiss the dialog
                    },
                    child: Text(
                      'No',
                      style: TextStyle(color: Color.fromRGBO(227, 0,
                          42, 1)),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 5,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent.withOpacity(
                          0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
      },
    );
  }

  void updatePolyPoints() async {
    List<LatLng> coordinates = await getPolyPoints(
      currentPosition!.latitude,
      currentPosition!.longitude,
      destinationLat,
      destinationLong,
    );
  }

  void getHospitalLocation() async {
    var HospitallocationValue = await testService.getHospitalLocation("Location");
    setState(() {
      destinationLat = double.tryParse(HospitallocationValue['Latitude']) ?? 0.0;
      destinationLong = double.tryParse(HospitallocationValue['Longitude']) ?? 0.0;
    });
    _addMarker(
      LatLng(
        destinationLat,
        destinationLong,
      ),
      'Hospital Location',
    );
    List<LatLng> coordinates = await getPolyPoints(
      currentPosition!.latitude,
      currentPosition!.longitude,
      destinationLat,
      destinationLong,
    );
    setState(() {
      _polylineCoordinates = coordinates;
    });
  }

}



