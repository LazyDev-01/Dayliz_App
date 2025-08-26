import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Test app for secure storage functionality
class SecureStorageTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Storage Test',
      home: SecureStorageTestScreen(),
    );
  }
}

class SecureStorageTestScreen extends StatefulWidget {
  @override
  _SecureStorageTestScreenState createState() => _SecureStorageTestScreenState();
}

class _SecureStorageTestScreenState extends State<SecureStorageTestScreen> {
  final _storage = const FlutterSecureStorage();
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();
  String _result = '';
  List<String> _allKeys = [];

  @override
  void initState() {
    super.initState();
    _loadAllKeys();
  }

  Future<void> _loadAllKeys() async {
    try {
      final keys = await _storage.readAll();
      setState(() {
        _allKeys = keys.keys.toList();
      });
    } catch (e) {
      setState(() {
        _result = 'Error loading keys: $e';
      });
    }
  }

  Future<void> _writeValue() async {
    try {
      await _storage.write(key: _keyController.text, value: _valueController.text);
      setState(() {
        _result = 'Successfully wrote: ${_keyController.text}';
      });
      _loadAllKeys();
    } catch (e) {
      setState(() {
        _result = 'Error writing: $e';
      });
    }
  }

  Future<void> _readValue() async {
    try {
      final value = await _storage.read(key: _keyController.text);
      setState(() {
        _result = value != null 
            ? 'Value: $value' 
            : 'Key not found: ${_keyController.text}';
      });
    } catch (e) {
      setState(() {
        _result = 'Error reading: $e';
      });
    }
  }

  Future<void> _deleteValue() async {
    try {
      await _storage.delete(key: _keyController.text);
      setState(() {
        _result = 'Deleted: ${_keyController.text}';
      });
      _loadAllKeys();
    } catch (e) {
      setState(() {
        _result = 'Error deleting: $e';
      });
    }
  }

  Future<void> _clearAll() async {
    try {
      await _storage.deleteAll();
      setState(() {
        _result = 'Cleared all secure storage';
        _allKeys = [];
      });
    } catch (e) {
      setState(() {
        _result = 'Error clearing: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Secure Storage Test'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: 'Key',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: 'Value',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _writeValue,
                    child: Text('Write'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _readValue,
                    child: Text('Read'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _deleteValue,
                    child: Text('Delete'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Clear All'),
            ),
            SizedBox(height: 16),
            Text(
              'Result:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(_result.isEmpty ? 'No result yet' : _result),
            ),
            SizedBox(height: 16),
            Text(
              'Stored Keys (${_allKeys.length}):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _allKeys.isEmpty
                    ? Text('No keys stored')
                    : ListView.builder(
                        itemCount: _allKeys.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_allKeys[index]),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _keyController.text = _allKeys[index];
                                _deleteValue();
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }
}

void main() {
  testWidgets('Secure Storage Test App', (WidgetTester tester) async {
    await tester.pumpWidget(SecureStorageTestApp());
    
    // Verify the app loads
    expect(find.text('Secure Storage Test'), findsOneWidget);
    expect(find.text('Write'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });
}
