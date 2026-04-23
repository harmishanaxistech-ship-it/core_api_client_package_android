// Example usage of the ApiClient package.

import 'dart:io';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:core_api_client_package/core_api_client_package.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize client with base URL and token provider
  ApiClient.initialize(
    config: NetworkConfig(baseUrl: 'https://api.example.com', maxRetries: 3, timeout: Duration(seconds: 10)),
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
    final res = await client.get<Map<String, dynamic>>('/status');
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
      final res = await ApiClient.instance.uploadFile<Map<String, dynamic>>('/upload', file);
      setState(() {
        if (res.success) {
          _result = 'Upload success: ${res.data}';
        } else {
          _result = 'Upload failed: ${res.error}';
        }
      });
    } catch (e, st) {
      developer.log('Upload error: $e', name: 'ExampleWidget', error: e, stackTrace: st);
      setState(() => _result = 'Upload exception: $e');
    }
  }

  Future<void> _retryDemo() async {
    // Use a non-routable IP to force a network failure and trigger retries
    try {
      developer.log('Starting retry demo', name: 'ExampleWidget');
      final dio = ApiClient.instance.dio;
      final response = await dio.get('http://10.255.255.1:81',
          options: Options(connectTimeout: const Duration(seconds: 3), receiveTimeout: const Duration(seconds: 3)));
      setState(() => _result = 'Retry demo response: ${response.data}');
    } catch (e, st) {
      developer.log('Retry demo failed: $e', name: 'ExampleWidget', error: e, stackTrace: st);
      setState(() => _result = 'Retry demo error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_result),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _callApi, child: const Text('Call /status')),
      const SizedBox(height: 8),
      ElevatedButton(onPressed: _uploadFile, child: const Text('Upload file (example)')),
      const SizedBox(height: 8),
      ElevatedButton(onPressed: _retryDemo, child: const Text('Retry demo (network failure)')),
    ]);
  }
}
