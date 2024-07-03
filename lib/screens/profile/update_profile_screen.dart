import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile/models/user.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:file_picker/file_picker.dart';

class UpdateProfileScreen extends StatefulWidget {
  final String id;

  const UpdateProfileScreen({Key? key, required this.id}) : super(key: key);

  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  File? _image;
  String? _imagePreview;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    try {
      User user = await Provider.of<AuthProvider>(context, listen: false)
          .fetchUserById(widget.id);
      _nameController.text = user.name ?? '';
      _emailController.text = user.email ?? '';
      if (user.image != null) {
        setState(() {
          _imagePreview = user.image;
        });
      }
    } catch (error) {
      print('Error fetching user data: $error');
    }
  }

  void _pickImage() async {
    // User? user = Provider.of<AuthProvider>(context, listen: false).user;

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.first.name);

      print(file.toString());

      // setState(() {
      //   _image = File(file);
      //   _imagePreview = file;
      // });
    } else {
      print("batal upload");
      // if (user?.image != null) {
      //   setState(() {
      //     _image = File(user!.image!);
      //     _imagePreview = user.image;
      //   });
      // } else {
      //   setState(() {
      //     _image = null;
      //     _imagePreview = null;
      //   });
      // }
    }
  }

  void _updateProfile() async {
    try {
      if (_image != null) {
        String fileName =
            '${widget.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        firebase_storage.Reference ref = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('images/profile/$fileName');
        firebase_storage.UploadTask uploadTask = ref.putFile(_image!);

        uploadTask.snapshotEvents
            .listen((firebase_storage.TaskSnapshot snapshot) {
          setState(() {
            _progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          });
        });

        await uploadTask.whenComplete(() async {
          String imageUrl = await ref.getDownloadURL();
          _updateUserData(imageUrl);
        });
      } else {
        _updateUserData(null);
      }
    } catch (error) {
      print('Error uploading image: $error');
    }
  }

  void _updateUserData(String? imageUrl) async {
    try {
      String name = _nameController.text;
      String email = _emailController.text;

      Provider.of<AuthProvider>(context, listen: false)
          .updateProfile(widget.id, name, email, imageUrl);

      Navigator.pop(context);
    } catch (error) {
      print('Error updating profile: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Profile'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _imagePreview != null
                ? CircleAvatar(
                    radius: 100,
                    backgroundImage: FileImage(File(_imagePreview!)),
                  )
                : CircleAvatar(
                    radius: 100,
                    child: Icon(Icons.person, size: 100),
                  ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pickImage(),
              child: Text('Pick Image'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}