import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ClearCache {
  deleteCacheMemory() async{
    var appDir = (await getTemporaryDirectory()).path;
    new Directory(appDir).delete(recursive: true);
  }
}