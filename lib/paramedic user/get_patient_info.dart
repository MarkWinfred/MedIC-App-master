import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class patientId{

  Future<dynamic> updatePatientStatusField(String field, String value, String assignedID, String hospitalID) async {
      final documentReference =
      FirebaseFirestore.instance
          .collection('hospitals')
          .doc(hospitalID)
          .collection('patient')
          .doc(assignedID);

      await documentReference.update({
        field: value,
      });
  }

  Future<dynamic> updateUserStatusField(String field, String newValue) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return 'No user signed in';
      }
      final uid = user.uid;
      final users = FirebaseFirestore.instance.collection('users');

      final snapshot = await users.where('Email', isEqualTo: user.email).get();
      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs[0].id;
        await users.doc(docId).update({
          field: newValue,
        });
      } else {
        return 'Field not found';
      }
    } catch (e) {
      return 'Error occurred';
    }
  }

}

class patientInfo extends StatelessWidget {
  final String field;
  final String assignedID;
  final String hospitalID;

  const patientInfo(this.field, this.assignedID, this.hospitalID, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('hospitals')
          .doc(hospitalID)
          .collection('patient')
          .doc(assignedID)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!.data();
          if (data != null && data.containsKey(field)) {
            return Text(data[field].toString());
          } else {
            return Text('Field not found');
          }
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}

class FirebaseService {
  Future<dynamic> getFieldData(String assignedID, String fieldName) async {
    // Get a reference to the document you want to retrieve the field value from
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('hospitals')
        .doc('qGEKaY2Cl0ec7qG0tI6pOzxoWQo1')
        .collection('patient')
        .doc(assignedID)
        .get();

    if (docSnapshot.exists) {
      var fieldValue = docSnapshot.get(fieldName);
      if (fieldName=="Location" || fieldName == "assigned_patient" ){
        return fieldValue;
      }
      return Text(fieldValue.data().toString());
    }
    return ''; // Return an empty string if the document or field does not exist
  }

  Future<dynamic> getHospitalLocation(String fieldName) async {
    // Get a reference to the document you want to retrieve the field value from
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('hospitals')
        .doc('qGEKaY2Cl0ec7qG0tI6pOzxoWQo1')
        .get();

    if (docSnapshot.exists) {
      var fieldValue = docSnapshot.get(fieldName);
      if (fieldName=="Location"){
        return fieldValue;
      }
      return Text(fieldValue.data().toString());
    }
    return ''; // Return an empty string if the document or field does not exist
  }
}
