import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medic/paramedic user/get_patient_info.dart';
import 'package:medic/paramedic user/appbar.dart';
import 'package:medic/paramedic user/panel.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';


class patientInformation extends StatefulWidget {
  const patientInformation({Key? key}) : super(key: key);

  @override
  State<patientInformation> createState() => _patientInfo();
}

class _patientInfo extends State<patientInformation> {
  BorderRadiusGeometry radius = BorderRadius.only(
    topLeft: Radius.circular(24.0),
    topRight: Radius.circular(24.0),
  );

  final testService = FirebaseService();
  final patientID = patientId();
  final users = FirebaseFirestore.instance.collection('users');
  final user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar('MedIC'),
      body: SlidingUpPanel(
        backdropColor: Color(0xFFba181b),
          panel: Column(
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
                            ],
                          );
                        }
                        return CircularProgressIndicator();
                      }
                  ),
                ]
            ),
          body:Container(),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
      );
  }

}