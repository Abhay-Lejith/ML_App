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
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Center(child: const Text('Image Classifier App')),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(),
            FundusScreen(),
            MRIScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services),
              label: 'Fundus',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.science),
              label: 'MRI',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _prediction = '';
  double _confidence = 0.0;
  File? _selectedImage;

  Future<void> _makePrediction() async {
    if (_selectedImage == null) {
      print('No image selected.');
      return;
    }

    final apiUrl = Uri.parse('http://127.0.0.1:5000/predict');

    try {
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
          _confidence = data['confidence'];
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
        _prediction = '';
        _confidence; // Clear any previous prediction.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _makePrediction,
            child: const Text('Get Prediction'),
          ),
          const SizedBox(height: 20),
          Text('Prediction: $_prediction \nConfidence level: $_confidence'),
        ],
      ),
    );
  }
}

class FundusScreen extends StatefulWidget {
  @override
  _FundusScreenState createState() => _FundusScreenState();
}

class _FundusScreenState extends State<FundusScreen> {
  String _prediction = '';
  double _confidence = 0.0;
  File? _selectedImage;

  Future<void> _makePrediction() async {
    if (_selectedImage == null) {
      print('No image selected.');
      return;
    }

    final apiUrl = Uri.parse('http://127.0.0.1:5000/predict');

    try {
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
          _confidence = data['confidence'];
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
        _prediction = '';
        _confidence; // Clear any previous prediction.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'Fundus Image Classifier',
              style: TextStyle(
                fontSize: 24, // Set your desired font size
                fontWeight: FontWeight.bold, // You can customize the style
              ),
            ),
          ),
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
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _makePrediction,
            child: const Text('Get Prediction'),
          ),
          const SizedBox(height: 20),
          Text('Prediction: $_prediction \nConfidence level: $_confidence'),
        ],
      ),
    );
  }
}

class MRIScreen extends StatefulWidget {
  _MRIScreenState createState() => _MRIScreenState();
}

class _MRIScreenState extends State<MRIScreen> {
  String _prediction = '';
  double _confidence = 0.0;
  File? _selectedImage;

  Future<void> _makePrediction() async {
    if (_selectedImage == null) {
      print('No image selected.');
      return;
    }

    final apiUrl = Uri.parse('http://127.0.0.1:5000/predict');

    try {
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
          _confidence = data['confidence'];
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
        _prediction = '';
        _confidence; // Clear any previous prediction.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'MRI Image Classifier',
              style: TextStyle(
                fontSize: 24, // Set your desired font size
                fontWeight: FontWeight.bold, // You can customize the style
              ),
            ),
          ),
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
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _makePrediction,
            child: const Text('Get Prediction'),
          ),
          const SizedBox(height: 20),
          Text('Prediction: $_prediction \nConfidence level: $_confidence'),
        ],
      ),
    );
  }
}
