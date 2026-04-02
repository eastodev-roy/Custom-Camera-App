import 'package:camera_app/controller/camera_controller.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CameraScreen extends StatelessWidget {
  final controller = Get.put(CameraControllerX());

   CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (!controller.isInitialized.value) {
          return Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            GestureDetector(
              onScaleUpdate: (details) {
                controller.setZoom(details.scale);
              },
              onTapUp: (details) => controller.focus(details, context),
              child: AspectRatio(
                aspectRatio: controller.cameraController.value.aspectRatio,
                child: CameraPreview(controller.cameraController),
              ),
            ),

            // 🔄 Loader
            if (controller.isLoading.value)
              Center(child: CircularProgressIndicator()),

            // 🎮 Controls
            Positioned(
              bottom: 20,
              left: 20,
              child: IconButton(
                icon: Icon(Icons.switch_camera),
                onPressed: controller.switchCamera,
              ),
            ),

            Positioned(
              bottom: 20,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.flash_on),
                onPressed: controller.toggleFlash,
              ),
            ),

            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  onPressed: () {
                    if (controller.isRecording.value) {
                      controller.stopRecording();
                    } else {
                      controller.takePicture();
                    }
                  },
                  child: Icon(Icons.camera),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
