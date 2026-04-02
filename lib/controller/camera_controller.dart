import 'package:camera/camera.dart';
import 'package:camera_app/main.dart';
import 'package:camera_app/screens/preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CameraControllerX extends GetxController with WidgetsBindingObserver {
  late CameraController cameraController;

  var isInitialized = false.obs;
  var isRecording = false.obs;
  var isLoading = false.obs;

  var flashMode = FlashMode.off.obs;

  double minZoom = 1.0;
  double maxZoom = 1.0;
  double currentZoom = 1.0;

  int selectedCameraIndex = 0;

  String? lastCapturedPath;

  // 🔁 INIT CAMERA
  Future<void> initCamera(CameraDescription camera) async {
    isLoading.value = true;

    cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    await cameraController.initialize();

    // ✅ Zoom range
    minZoom = await cameraController.getMinZoomLevel();
    maxZoom = await cameraController.getMaxZoomLevel();

    isInitialized.value = true;
    isLoading.value = false;
  }

  // 📸 TAKE PICTURE
  Future<void> takePicture() async {
    try {
      isLoading.value = true;

      final file = await cameraController.takePicture();
      lastCapturedPath = file.path;

      Get.to(() => PreviewView(path: file.path, isVideo: false));
    } finally {
      isLoading.value = false;
    }
  }

  // 🎥 START VIDEO
  Future<void> startRecording() async {
    await cameraController.startVideoRecording();
    isRecording.value = true;
  }

  // 🎥 STOP VIDEO
  Future<void> stopRecording() async {
    final file = await cameraController.stopVideoRecording();
    isRecording.value = false;

    lastCapturedPath = file.path;

    Get.to(() => PreviewView(path: file.path, isVideo: true));
  }

  // 🔄 SWITCH CAMERA
  Future<void> switchCamera() async {
    selectedCameraIndex = (selectedCameraIndex + 1) % cameras.length;

    await initCamera(cameras[selectedCameraIndex]);
  }

  // ⚡ FLASH
  Future<void> toggleFlash() async {
    flashMode.value = flashMode.value == FlashMode.off
        ? FlashMode.torch
        : FlashMode.off;

    await cameraController.setFlashMode(flashMode.value);
  }

  // 🤳 ZOOM
  Future<void> setZoom(double zoom) async {
    currentZoom = zoom.clamp(minZoom, maxZoom);
    await cameraController.setZoomLevel(currentZoom);
  }

  // 🎯 FOCUS
  Future<void> focus(TapUpDetails details, BuildContext context) async {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.globalPosition);

    final size = box.size;

    await cameraController.setFocusPoint(
      Offset(offset.dx / size.width, offset.dy / size.height),
    );
  }

  // 🔄 LIFECYCLE HANDLING
  @override
  void onInit() {
    WidgetsBinding.instance.addObserver(this);
    initCamera(cameras.first);
    super.onInit();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      initCamera(cameras[selectedCameraIndex]);
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    super.onClose();
  }
}
