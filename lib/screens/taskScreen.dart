import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taskmanager/service/firebaseService.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({Key? key}) : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FirebaseService _service = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? imageUrl;
  File? file;
  List<bool> isChecked=<bool>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        title: const Text("Task Manager"),
      ),
      body: StreamBuilder(
          stream: _firestore
              .collection('task')
              .orderBy('currentTime', descending: true)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasData) {
              return taskList(snapshot);
            } else {
              return const Text("you didn't created any task yet");
            }
          }),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orangeAccent,
        onPressed: () {
          taskCreateDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text("Create Task"),
      ),
    );
  }

  /// task list
  Widget taskList(AsyncSnapshot<QuerySnapshot<Object?>> snapshot) {
    // isChecked = List<bool>.filled(snapshot.data!.docs.length, false);
    return ListView.builder(
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          var item = snapshot.data!.docs[index];
          return Dismissible(
            onDismissed: (dir) {
              setState(() {
                taskDeleteDialog(context, item.id);
              });
            },
            key: UniqueKey(),
            child: Card(
              color: Colors.indigo.shade300,
              child: ListTile(
                onTap: (){
                  showTaskDialog(
                    context: context,
                    title: snapshot.data!.docs[index]['title'],
                    decription: snapshot.data!.docs[index]['description'],
                    imageUrl: snapshot.data!.docs[index]['imageUrl'],
                  );
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  snapshot.data!.docs[index]['title'],
                  style: const TextStyle(color: Colors.white),
                ),

              ),
            ),
          );
        });
  }

  /// Create Task Field
  Widget taskFilled() {
    return TextFormField(
      controller: _title,
      decoration: const InputDecoration(hintText: "Enter your task name"),
      validator: (val) {
        if (val!.isEmpty) {
          return "This Filled is Required";
        }
      },
    );
  }

  /// Description Filled
  Widget descriptionFilled() {
    return TextFormField(
      controller: _description,
      decoration:
          const InputDecoration(hintText: "Enter your task description"),
    );
  }

  ///Save Button
  Widget saveButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(primary: Colors.orangeAccent),
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          _service
              .createTask(
            title: _title.text.trim(),
            description: _description.text.trim(),
            url: imageUrl.toString()
          )
              .then((value) {
            _title.clear();
            _description.clear();
            Navigator.of(context).pop();
          });
        }
      },
      child: const Text(
        "Save Task",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  ///Dialog Box for creating Task
  Future<void> taskCreateDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            insetPadding: const EdgeInsets.all(10),
            insetAnimationCurve: Curves.easeInCubic,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    taskFilled(),
                    descriptionFilled(),
                    const SizedBox(
                      height: 10,
                    ),
                    filePickButton(),
                    saveButton()
                  ],
                ),
              ),
            ),
          );
        });
  }

  ///file picker
  filePickButton() {
    return TextButton(
      onPressed: () {
        uploadImage();
      },
      child: Text("Pick File"),
      style: TextButton.styleFrom(primary: Colors.green),
    );
  }

  ///Dialog to delete task
  Future<void> taskDeleteDialog(BuildContext context, String id) async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Do you really want to delete?"),
            actions: [
              TextButton(
                  onPressed: () {
                    _service.deleteTask(id).then((value) {
                      Navigator.of(context).pop();
                    });
                  },
                  child: const Text('Yes')),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('No')),
            ],
          );
        });
  }

  ///Show Dialog Box for showing Task Detail
  Future<void> showTaskDialog(
      {
      required BuildContext context,
      String? title,
      String? decription,
      String? imageUrl
      })
  async {
    return showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            insetPadding: const EdgeInsets.all(10),
            insetAnimationCurve: Curves.easeInCubic,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Title: ${title.toString()}",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    "Description: ${decription.toString()}",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  imageUrl!=null?
                  Image.network(imageUrl.toString(),height: 60,width: 60):
                      SizedBox()
                ],
              ),
            ),
          );
        });
  }




  /// Upload Image
  uploadImage() async {
    final _firebaseStorage = FirebaseStorage.instance;
    final _imagePicker = ImagePicker();
    PickedFile image;
      ///Select Image
      final pickedImage = await ImagePicker().getImage(source: ImageSource.gallery);

      file = pickedImage != null ? File(pickedImage.path) : null;
      if(file != null)
        {
          setState((){
            file = File(pickedImage!.path);
          });
        }
    var path = file!.path;
      String fileName = path.split('/').last;
      if (pickedImage != null){
        var snapshot = await _firebaseStorage.ref()
            .child('images/${fileName}')
            .putFile(file!);
          var downloadUrl = await snapshot.ref.getDownloadURL();
          setState(() {
            imageUrl = downloadUrl;
          });
      }

  }
}
