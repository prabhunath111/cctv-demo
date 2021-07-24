import 'package:flutter/material.dart';
import 'camera.dart';
import 'utils/clear_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ClearCache().deleteCacheMemory();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraClass(),
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    ),
  );
}
