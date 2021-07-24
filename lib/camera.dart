import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'utils/clear_cache.dart';
import 'utils/permission_handler.dart';

class CameraClass extends StatefulWidget {
  @override
  _CameraClassState createState() => _CameraClassState();
}

class _CameraClassState extends State<CameraClass> {
  CameraController controller;
  List cameras;
  int selectedCameraIdx = 1;
  String videoPath = '';

  @override
  void initState() {
    // TODO: implement initState

    // 1

    availableCameras().then((availableCameras) {
      cameras = availableCameras;
      if (cameras.length > 0) {
        setState(
          () {
            // 2
            selectedCameraIdx = 0;
          },
        );
        _initCameraController(cameras[selectedCameraIdx]).then(
          (void v) async {
            await startPeriodicRecording();
            final a = await PermissionHandler()
                .checkPermissionStatus(PermissionGroup.storage);
            if (a == PermissionStatus.denied) {
              await permissionAccessPhone();
            }
          },
        );
      } else {
        print("No camera available");
      }
    }).catchError((err) {
      // 3
      print('Error: $err.code\nError Message: $err.message');
    });
    super.initState();
  }

  // 1, 2
  Future _initCameraController(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }

    // 3
    controller = CameraController(cameraDescription, ResolutionPreset.medium);

    // If the controller is updated then update the UI.
    // 4
    controller.addListener(
      () {
        // 5
        if (mounted) {
          setState(() {});
        }

        if (controller.value.hasError) {
          print('Camera error ${controller.value.errorDescription}');
        }
      },
    );

    // 6
    try {
      await controller.initialize();
    } on CameraException catch (e) {
//      _showCameraException(e);
    }
    print('exception $e');

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: (!controller.value.isInitialized)
            ? Container(
                child: Center(
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(
                      height: 8.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Please wait for a moment otherwise kill the app and open again to allow the camera permissions',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                )),
              )
            : SafeArea(
                child: Stack(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      child: CameraPreview(controller),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> startPeriodicRecording() async {
    setState(() {
      controller.startVideoRecording();
    });
    var time = const Duration(minutes: 1);
    Timer.periodic(
      time,
      (timer) async {
        await stopAndSave();
        Future.delayed(const Duration(seconds: 2), () {
          setState(
            () {
              controller.startVideoRecording();
            },
          );
        });
      },
    );
  }

  Future<File> moveFile(File sourceFile, String newPath) async {
    try {
      // prefer using rename as it is probably faster
      return await sourceFile.rename(newPath);
    } on FileSystemException catch (e) {
      // if rename fails, copy the source file and then delete it
      final newFile = await sourceFile.copy(newPath);
      await sourceFile.delete();
      return newFile;
    }
  }

  Future<void> stopAndSave() async {
    XFile video = await controller.stopVideoRecording();
    File file = File(video.path);
    File renamedVideo = await moveFile(file,
        "/data/user/0/com.example.ll_cctv/cache/llctv${DateTime.now().millisecondsSinceEpoch}.mp4");
    videoPath = renamedVideo.path;
    await GallerySaver.saveVideo(videoPath, albumName: "LL_CCTV")
        .then((value) {});
    await ClearCache().deleteCacheMemory();
    setState(() {});
  }

  Future permissionAccessPhone() async {
    await PermissionService().requestPermission(
      onPermissionDenied: () async {
        permissionAccessPhone();
      },
    );
  }
}
