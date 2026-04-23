// Example usage of the ApiClient package.

import 'dart:io';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:core_api_client_package/core_api_client_package.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize client with base URL and token provider
  ApiClient.initialize(
    config: NetworkConfig(
        baseUrl: 'https://api.example.com',
        maxRetries: 3,
        timeout: const Duration(seconds: 10)),
    tokenProvider: () async {
      // Read token from secure storage in real apps
      return 'your_jwt_token';
    },
    enableLogging: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('API Client Example')),
        body: const Center(child: ExampleWidget()),
      ),
    );
  }
}

class ExampleWidget extends StatefulWidget {
  const ExampleWidget({super.key});

  @override
  State<ExampleWidget> createState() => _ExampleWidgetState();
}

class _ExampleWidgetState extends State<ExampleWidget> {
  String _result = 'No call yet';

  Future<void> _callApi() async {
    final client = ApiClient.instance;

    // New format usage
    final res = await client.get<Map<String, dynamic>>(
      url: '/status',
      params: {'page': 1},
      headers: {'Accept-Language': 'en'},
    );

    setState(() {
      if (res.success) {
        _result = res.data.toString();
      } else {
        _result = 'Error: ${res.error}';
      }
    });
    developer.log('Call /status completed', name: 'ExampleWidget');
  }

  Future<File> _createTempFile() async {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/example_upload.txt');
    await file.writeAsString('example upload content ${DateTime.now()}');
    return file;
  }

  Future<void> _uploadFile() async {
    try {
      final file = await _createTempFile();
      developer.log('Uploading file: ${file.path}', name: 'ExampleWidget');

      // POST with automatic file detection
      final res = await ApiClient.instance.post<Map<String, dynamic>>(
        url: '/upload',
        body: {
          'name': 'Rahul',
          'email': 'rahul@example.com',
          'file': file, // Automatically handled as multipart!
        },
      );

      setState(() {
        if (res.success) {
          _result = 'Upload success: ${res.data}';
        } else {
          _result = 'Upload failed: ${res.error}';
        }
      });
    } catch (e, st) {
      developer.log('Upload error: $e',
          name: 'ExampleWidget', error: e, stackTrace: st);
      setState(() => _result = 'Upload exception: $e');
    }
  }

  Future<void> _putExample() async {
    final res = await ApiClient.instance.put<Map<String, dynamic>>(
      url: '/users/1',
      body: {'name': 'Updated Name'},
    );
    setState(() => _result = 'PUT result: ${res.success}');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_result),
        ),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _callApi, child: const Text('GET /status')),
        const SizedBox(height: 8),
        ElevatedButton(
            onPressed: _uploadFile, child: const Text('POST with File')),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _putExample, child: const Text('PUT /users/1')),
      ]),
    );
  }
}
