import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //final TextEditingController _inputController = TextEditingController();
  String _prediction = '';
  File? _selectedImage;

  Future<void> _makePrediction() async {
    if (_selectedImage == null) {
      print('No image selected.');
      return;
    }

    final apiUrl = Uri.parse('http://127.0.0.1:5000/predict');

    try {
      // Encode the selected image as bytes and send it in the request.
      final List<int> imageBytes = _selectedImage!.readAsBytesSync();

      final response = await http.post(
        apiUrl,
        body: jsonEncode({'image_bytes': base64Encode(imageBytes)}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _prediction = data['predicted_class'];
          // _confidence = data['confidence'];
        });
      } else {
        throw Exception('Failed to make a prediction.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _selectImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
        _prediction = ''; // Clear any previous prediction.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Image Classifier App'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: _selectImage,
                child: const Text('Select Image'),
              ),
              const SizedBox(height: 20),
              if (_selectedImage != null)
                Image.file(
                  _selectedImage!,
                  height: 200,
                  width: 200,
                )
              else
                const Text('No image selected.'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _makePrediction,
                child: const Text('Get Prediction'),
              ),
              const SizedBox(height: 20),
              Text('Prediction: $_prediction'),
            ],
          ),
        ),
      ),
    );
  }
}
