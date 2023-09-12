import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
//import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
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
          title: Center(
              child: const Text(
            'DiagnoTech',
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.bold,
            ),
          )),
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
            'DiagnoTech',
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
  TextEditingController _nameController =
      TextEditingController(); // Add name controller

  final _databaseHelper = DatabaseHelper();

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
          final name = _nameController.text; // Get the user's name
          _databaseHelper.insertData(name, _prediction, _confidence);
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

  Future<void> _navigateToHistoryPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: const Text(
            'Fundus Image Classifier',
            style: TextStyle(
              fontSize: 24, // Set your desired font size
              fontWeight: FontWeight.bold, // You can customize the style
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              _navigateToHistoryPage(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
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
      ),
    );
  }
}

class DatabaseHelper {
  Database? _database;

  Future<void> initializeDatabase() async {
    if (_database == null) {
      final dbPath = await getDatabasesPath();
      //final documentsDirectory = await getApplicationDocumentsDirectory();
      final databasePath = join(dbPath, 'Fundus.db');

      _database = await openDatabase(
        databasePath,
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE predictions(id INTEGER PRIMARY KEY, name TEXT, prediction TEXT, confidence REAL)',
          );
        },
        version: 1,
      );
    }
  }

  Future<void> insertData(
      String name, String prediction, double confidence) async {
    final db = await database;
    await db.insert(
      'predictions',
      {'name': name, 'prediction': prediction, 'confidence': confidence},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPredictions() async {
    final db = await database;
    return db.query('predictions');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  Future<Database> get database async {
    if (_database == null) {
      await initializeDatabase();
    }
    return _database!;
  }
}

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _databaseHelper = DatabaseHelper();

  List<Map<String, dynamic>> _historyData = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    final history = await _databaseHelper.getPredictions();
    setState(() {
      _historyData = history;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prediction History'),
      ),
      body: ListView.builder(
        itemCount: _historyData.length,
        itemBuilder: (context, index) {
          final prediction = _historyData[index];
          return ListTile(
            title: Text('Name: ${prediction['name']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prediction: ${prediction['prediction']}'),
                Text('Confidence level: ${prediction['confidence']}'),
              ],
            ),
          );
        },
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
  TextEditingController _nameController =
      TextEditingController(); // Add name controller

  final _databaseHelperX = DatabaseHelperX();

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
          _prediction = data['predicted_class'];
          _confidence = data['confidence'];
          final name = _nameController.text; // Get the user's name
          _databaseHelperX.insertData(name, _prediction, _confidence);
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

  Future<void> _navigateToHistoryPageX(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryPageX()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: const Text(
            'MRI Image Classifier',
            style: TextStyle(
              fontSize: 25, // Set your desired font size
              fontWeight: FontWeight.bold, // You can customize the style
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              _navigateToHistoryPageX(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
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
      ),
    );
  }
}

class DatabaseHelperX {
  Database? _database;

  Future<void> initializeDatabase() async {
    if (_database == null) {
      final dbPath = await getDatabasesPath();
      //final documentsDirectory = await getApplicationDocumentsDirectory();
      final databasePath = join(dbPath, 'ChestXRay.db');

      _database = await openDatabase(
        databasePath,
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE predictions(id INTEGER PRIMARY KEY, name TEXT, prediction TEXT, confidence REAL)',
          );
        },
        version: 1,
      );
    }
  }

  Future<void> insertData(
      String name, String prediction, double confidence) async {
    final db = await database;
    await db.insert(
      'predictions',
      {'name': name, 'prediction': prediction, 'confidence': confidence},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPredictions() async {
    final db = await database;
    return db.query('predictions');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  Future<Database> get database async {
    if (_database == null) {
      await initializeDatabase();
    }
    return _database!;
  }
}

class HistoryPageX extends StatefulWidget {
  @override
  _HistoryPageStateX createState() => _HistoryPageStateX();
}

class _HistoryPageStateX extends State<HistoryPageX> {
  final _databaseHelperX = DatabaseHelperX();

  List<Map<String, dynamic>> _historyData = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    final history = await _databaseHelperX.getPredictions();
    setState(() {
      _historyData = history;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prediction History'),
      ),
      body: ListView.builder(
        itemCount: _historyData.length,
        itemBuilder: (context, index) {
          final prediction = _historyData[index];
          return ListTile(
            title: Text('Name: ${prediction['name']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prediction: ${prediction['prediction']}'),
                Text('Confidence level: ${prediction['confidence']}'),
              ],
            ),
          );
        },
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
              'DiagnoTech',
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
              "\n\nThe 'DiagnoTech' app is a powerful tool for doctors, leveraging advanced machine learning algorithms\n to analyze patient data, medical images, and symptoms. It aids in the rapid and accurate\nidentification of diseases, providing real-time diagnostic insights, treatment recommendations, \nand relevant medical literature, enhancing clinical decision-making and patient care.",
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
