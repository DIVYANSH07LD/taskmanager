import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService{

    final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
    final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;


    /// create task in firestore
    Future<void> createTask({required String title, required String description,required String url})async{
      if(url!=null)
        {
          await _firebaseFirestore.collection("task").doc().set({
            'title': title,
            'description':description,
            'currentTime': DateTime.now(),
            'imageUrl':url,
            'status':false
          });
        }


    }

    ///Delete task from firestore
     Future<bool> deleteTask(String id) async {
      await _firebaseFirestore.collection('task').doc(id).delete().catchError((e) {
        print("delete");
      });
      return true;
    }

}