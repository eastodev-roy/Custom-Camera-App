import 'package:camera/camera.dart';
import 'package:camera_app/controller/camera_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedModeIndex = 2; // PHOTO is default
  int _selectedZoomIndex = 1; // 1x is default

  final List<String> _modes = [
    'CINEMATIC',
    'VIDEO',
    'PHOTO',
    'PORTRAIT',
    'PANO',
  ];
  final List<String> _zoomLevels = ['0.5', '1', '2', '3'];
  final List<double> _zoomValues = [0.5, 1.0, 2.0, 3.0];

  late AnimationController _shutterAnimController;
  late Animation<double> _shutterScaleAnim;

  late final CameraControllerX _camController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Initialize camera controller via GetX
    _camController = Get.put(CameraControllerX());

    _shutterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _shutterScaleAnim = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _shutterAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shutterAnimController.dispose();
    super.dispose();
  }

  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  void _onShutterTap() async {
    HapticFeedback.mediumImpact();
    _shutterAnimController.forward();
    await Future.delayed(const Duration(milliseconds: 120));
    _shutterAnimController.reverse();

    if (_selectedModeIndex == 1) {
      // VIDEO mode
      if (_camController.isRecording.value) {
        await _camController.stopRecording();
      } else {
        await _camController.startRecording();
        _showToast("Recording started");
      }
    } else {
      // PHOTO / other modes — take picture
      await _camController.takePicture();
    }
  }

  void _onFlashToggle() {
    _camController.toggleFlash();
  }

  void _onFlipCamera() {
    HapticFeedback.mediumImpact();
    _camController.switchCamera();
  }

  void _onZoomSelected(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedZoomIndex = index);
    double targetZoom = _zoomValues[index];
    // Clamp to camera's supported range
    targetZoom = targetZoom.clamp(
      _camController.minZoom,
      _camController.maxZoom,
    );
    _camController.setZoom(targetZoom);
    _showToast("${_zoomLevels[index]}x zoom");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Camera viewfinder area
            Expanded(
              child: Stack(
                children: [
                  // Live camera preview
                  _buildCameraPreview(),

                  // Top controls overlay
                  _buildTopBar(),

                  // Grid overlay lines
                  _buildGridOverlay(),

                  // Zoom selector — positioned at bottom of viewfinder
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: _buildZoomSelector(),
                  ),
                ],
              ),
            ),

            // Bottom section: mode tabs + shutter controls
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  /// Live camera preview replacing the old placeholder viewfinder
  Widget _buildCameraPreview() {
    return Obx(() {
      if (!_camController.isInitialized.value) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Colors.amber,
                  strokeWidth: 2.5,
                ),
                SizedBox(height: 16),
                Text(
                  'Initializing Camera...',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onScaleUpdate: (details) {
              _camController.setZoom(details.scale);
            },
            onTapUp: (details) => _camController.focus(details, context),
            child: CameraPreview(_camController.cameraController),
          ),
        ),
      );
    });
  }

  /// Top action bar with flash, chevron, and settings
  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          right: 8,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
          ),
        ),
        child: Obx(() {
          final isFlashOn = _camController.flashMode.value != FlashMode.off;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flash button — actually toggles camera flash
              _TopBarButton(
                icon: isFlashOn
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                iconColor: isFlashOn ? Colors.amber : Colors.white,
                onTap: _onFlashToggle,
              ),

              // Center chevron (expand controls)
              _TopBarButton(
                icon: Icons.keyboard_arrow_up_rounded,
                iconSize: 28,
                onTap: () => _showToast("More controls"),
              ),

              // Settings
              _TopBarButton(
                icon: Icons.settings_outlined,
                onTap: () => _showToast("Settings"),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// Grid overlay lines for composition
  Widget _buildGridOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: CustomPaint(painter: _GridPainter()),
        ),
      ),
    );
  }

  /// Zoom level selector pills
  Widget _buildZoomSelector() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_zoomLevels.length, (index) {
            final isSelected = index == _selectedZoomIndex;
            return GestureDetector(
              onTap: () => _onZoomSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: isSelected ? 40 : 36,
                height: isSelected ? 40 : 36,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.black.withValues(alpha: 0.7)
                      : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: Text(
                  _zoomLevels[index] == '1' ? '1x' : _zoomLevels[index],
                  style: TextStyle(
                    color: isSelected ? Colors.amber : Colors.white70,
                    fontSize: isSelected ? 13 : 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Bottom section containing mode tabs and shutter controls
  Widget _buildBottomSection() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode tabs row
          _buildModeTabs(),

          const SizedBox(height: 24),

          // Shutter row: gallery | shutter | flip
          _buildShutterRow(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Horizontally scrollable mode selector
  Widget _buildModeTabs() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _modes.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedModeIndex;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedModeIndex = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isSelected
                    ? Colors.amber.withValues(alpha: 0.15)
                    : Colors.transparent,
              ),
              child: Text(
                _modes[index],
                style: TextStyle(
                  color: isSelected ? Colors.amber : Colors.white54,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Main shutter row with gallery, shutter, and flip buttons
  Widget _buildShutterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gallery thumbnail
          GestureDetector(
            onTap: () => _showToast("Open gallery"),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 1.5),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4A6741), Color(0xFF8B7355)],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.5),
                child: const Icon(
                  Icons.photo_rounded,
                  color: Colors.white70,
                  size: 24,
                ),
              ),
            ),
          ),

          // Shutter button — changes style for video recording
          Obx(() {
            final isRecording = _camController.isRecording.value;
            final isVideo = _selectedModeIndex == 1;
            return GestureDetector(
              onTap: _onShutterTap,
              child: ScaleTransition(
                scale: _shutterScaleAnim,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isVideo && isRecording)
                          ? Colors.red
                          : Colors.white,
                      width: 4,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      shape: (isVideo && isRecording)
                          ? BoxShape.rectangle
                          : BoxShape.circle,
                      borderRadius: (isVideo && isRecording)
                          ? BorderRadius.circular(8)
                          : null,
                      color: (isVideo && isRecording)
                          ? Colors.red
                          : isVideo
                          ? Colors.red
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }),

          // Camera flip — actually switches camera
          GestureDetector(
            onTap: _onFlipCamera,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.flip_camera_ios_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple top bar icon button with a translucent background
class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final VoidCallback onTap;

  const _TopBarButton({
    required this.icon,
    this.iconColor = Colors.white,
    this.iconSize = 24,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.25),
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}

/// Custom painter for composition grid lines
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 0.5;

    // Vertical lines (thirds)
    final thirdW = size.width / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(thirdW * i, 0),
        Offset(thirdW * i, size.height),
        paint,
      );
    }

    // Horizontal lines (thirds)
    final thirdH = size.height / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(0, thirdH * i),
        Offset(size.width, thirdH * i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
