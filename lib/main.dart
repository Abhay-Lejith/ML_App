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
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Center(child: const Text('MediPal Lens PRO')),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(),
            FundusScreen(),
            MRIScreen(),
          ],
        ),
        drawer: NavigationDrawer(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.remove_red_eye),
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
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'MediPal Lens PRO',
            style: TextStyle(
              fontSize: 40, // Set your desired font size
              fontWeight: FontWeight.bold, // You can customize the style
              color: Colors.red,
            ),
          ),
          // Text(
          //   "\n\nThe 'MediPal LENS PRO' app is a powerful tool for doctors, leveraging advanced machine learning algorithms\n to analyze patient data, medical images, and symptoms. It aids in the rapid and accurate\nidentification of diseases, providing real-time diagnostic insights, treatment recommendations, \nand relevant medical literature, enhancing clinical decision-making and patient care.",
          //   style: TextStyle(
          //     fontSize: 18, // Set your desired font size
          //     color: Colors.blue,
          //   ),
          // )
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

    final apiUrl = Uri.parse('http://127.0.0.1:5000/predict/fundus');

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
  String _prediction1 = '';
  double _confidence1 = 0.0;
  String _prediction2 = '';
  double _confidence2 = 0.0;

  File? _selectedImage;

  Future<void> _makePrediction() async {
    if (_selectedImage == null) {
      print('No image selected.');
      return;
    }

    final apiUrl = Uri.parse('http://127.0.0.1:5000/predict/xray');

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
          _prediction1 = data['predicted_class_1'];
          _confidence1 = data['confidence_1'];
          _prediction2 = data['predicted_class_2'];
          _confidence2 = data['confidence_2'];
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
        _prediction1 = '';
        _confidence1;
        _prediction2 = '';
        _confidence2; // Clear any previous prediction.
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
          Text('Prediction 1: $_prediction1 \nConfidence level: $_confidence1'),
          Text('Prediction 2: $_prediction2 \nConfidence level: $_confidence2'),
        ],
      ),
    );
  }
}

class NavigationDrawer extends StatefulWidget {
  @override
  _NavigationDrawerScreen createState() => _NavigationDrawerScreen();
}

class _NavigationDrawerScreen extends State<NavigationDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'More',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About App'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AboutAppPage()),
              );
              // Navigate to the about page or perform an action.
              // Add your code here.
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AboutHelpPage()),
              );
              // Navigate to the help page or perform an action.
              // Add your code here.
            },
          ),
          ListTile(
            leading: Icon(Icons.library_books),
            title: Text('References'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AboutReferencePage()),
              );
              // Navigate to the references page or perform an action.
              // Add your code here.
            },
          ),
        ],
      ),
    );
  }
}

class AboutAppPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'MediPal Lens PRO',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Version: 1.0.0',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Description:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "\n\nThe 'MediPal LENS PRO' app is a powerful tool for doctors, leveraging advanced machine learning algorithms\n to analyze patient data, medical images, and symptoms. It aids in the rapid and accurate\nidentification of diseases, providing real-time diagnostic insights, treatment recommendations, \nand relevant medical literature, enhancing clinical decision-making and patient care.",
              style: TextStyle(
                fontSize: 18, // Set your desired font size
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Our Incredible Team:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Abhay Lejith',
              style: TextStyle(
                fontSize: 18, // Set your desired font size
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                "Shreesha M",
                style: TextStyle(
                  fontSize: 18, // Set your desired font size
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutHelpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('Help')],
        ),
      ),
    );
  }
}

class AboutReferencePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\References\n\n',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '1) "Automatic detection of 39 fundus diseases and conditions in retinal photographs using deep neural networks"\n https://www.nature.com/articles/s41467-021-25138-w',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('   -our fundus AI model was trained using this dataset'),
            Text(
              '2) https://teachablemachine.withgoogle.com/train/image',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('   -our model was trained using teachable machine'),
            Text(
              '3) https://docs.flutter.dev/ ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('   -our application was built using Flutter'),
          ],
        ),
      ),
    );
  }
}
