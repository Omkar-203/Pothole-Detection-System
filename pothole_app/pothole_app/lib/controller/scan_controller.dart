import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import '../api/api_manager.dart';
import '../widgets/custom_snackbar.dart';

class ScanController extends GetxController {
  final liveDetection = true.obs;
  final audioEnabled = false.obs;
  final isScanning = false.obs;
  final detectedCount = 0.obs;
  final latitude = 37.775.obs; // placeholder
  final longitude = (-122.420).obs; // placeholder
  final status = 'Idle'.obs; // Idle | Scanning | Completed
  final isInitializingCamera = true.obs;
  final isUploading = false.obs;
  CameraController? cameraController;
  List<CameraDescription> cameraDescriptions = [];
  final cameraError = RxnString();
  final flashOn = false.obs;
  final isPaused = false.obs;
  final userId = ''.obs; // Assume set from login

  // Journey tracking
  final journeyDistance = 0.0.obs; // in kilometers
  final journeyTime = 0.obs; // in minutes
  final startLatitude = 0.0.obs;
  final startLongitude = 0.0.obs;
  final currentSpeed = 0.0.obs; // in km/h

  Timer? _locationTimer;
  Timer? _captureTimer;
  Position? _lastPosition;
  DateTime? _startTime;
  bool _isCapturing = false;

  void toggleAudio() => audioEnabled.toggle();

  void startScanning() async {
    print('Starting scanning... Live detection: ${liveDetection.value}');
    isScanning.value = true;
    isPaused.value = false;
    status.value = 'Scanning';

    // Initialize journey tracking
    _startTime = DateTime.now();
    journeyDistance.value = 0.0;
    journeyTime.value = 0;

    try {
      // Get initial position
      final initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      startLatitude.value = initialPosition.latitude;
      startLongitude.value = initialPosition.longitude;
      latitude.value = initialPosition.latitude;
      longitude.value = initialPosition.longitude;
      _lastPosition = initialPosition;

      // Start location tracking
      _startLocationTracking();

      // Start automatic capture if live detection is enabled
      if (liveDetection.value) {
        print('Live detection enabled, starting automatic capture');
        _startAutomaticCapture();
      } else {
        print('Live detection disabled, skipping automatic capture');
      }
    } catch (e) {
      CustomSnackbar.error(
        title: 'Location Error',
        message: 'Failed to get location: $e',
      );
    }
  }

  void captureManual() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await cameraController!.takePicture();
      final bytes = await image.readAsBytes();

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      latitude.value = position.latitude;
      longitude.value = position.longitude;

      // Upload and analyze
      final result = await ApiManager.instance.uploadPothole(
        latitude.value,
        longitude.value,
        bytes,
        'manual_pothole_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (result['message'] == 'no pothole detected') {
        CustomSnackbar.warning(
          title: 'No Pothole Detected',
          message: 'No pothole was found in the captured image.',
        );
      } else {
        detectedCount.value += 1;
        CustomSnackbar.success(
          title: 'Pothole Reported!',
          message: 'Pothole successfully detected and reported.',
        );
      }
    } catch (e) {
      CustomSnackbar.error(
        title: 'Capture Failed',
        message: 'Failed to capture and analyze image: $e',
      );
    }
  }

  Future<void> pickAndAnalyzeImage() async {
    try {
      isUploading.value = true;

      // Request appropriate permissions based on platform
      PermissionStatus permissionStatus;
      if (Platform.isAndroid) {
        permissionStatus = await Permission.storage.request();
      } else if (Platform.isIOS) {
        permissionStatus = await Permission.photos.request();
      } else {
        permissionStatus = await Permission.photos.request();
      }

      if (!permissionStatus.isGranted) {
        CustomSnackbar.error(
          title: 'Permission Denied',
          message: 'Gallery access permission is required to upload images.',
        );
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final bytes = await image.readAsBytes();

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      latitude.value = position.latitude;
      longitude.value = position.longitude;

      // Upload and analyze
      final result = await ApiManager.instance.uploadPothole(
        latitude.value,
        longitude.value,
        bytes,
        'uploaded_pothole_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (result['message'] == 'no pothole detected') {
        CustomSnackbar.warning(
          title: 'No Pothole Detected',
          message: 'No pothole was found in the uploaded image.',
        );
      } else {
        detectedCount.value += 1;
        CustomSnackbar.success(
          title: 'Pothole Reported!',
          message:
              'Pothole successfully detected and reported from uploaded image.',
        );
      }
    } catch (e) {
      CustomSnackbar.error(
        title: 'Upload Failed',
        message: 'Failed to upload and analyze image: $e',
      );
    } finally {
      isUploading.value = false;
    }
  }

  void stopScanning() {
    isScanning.value = false;
    isPaused.value = false;
    status.value = 'Completed';

    // Stop timers
    _locationTimer?.cancel();
    _captureTimer?.cancel();

    // Calculate final journey time
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!);
      journeyTime.value = duration.inMinutes;
    }
  }

  void pauseScanning() {
    if (!isScanning.value) return;
    isPaused.value = true;
    status.value = 'Paused';

    // Stop automatic capture when paused
    _captureTimer?.cancel();
  }

  void resumeScanning() {
    if (!isScanning.value) return;
    isPaused.value = false;
    status.value = 'Scanning';

    // Resume automatic capture if live detection is enabled
    if (liveDetection.value) {
      _startAutomaticCapture();
    }
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!isScanning.value || isPaused.value) return;

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        latitude.value = position.latitude;
        longitude.value = position.longitude;
        currentSpeed.value = position.speed * 3.6; // Convert m/s to km/h

        // Calculate distance traveled
        if (_lastPosition != null) {
          final distance = Geolocator.distanceBetween(
                _lastPosition!.latitude,
                _lastPosition!.longitude,
                position.latitude,
                position.longitude,
              ) /
              1000; // Convert to kilometers

          journeyDistance.value += distance;
        }

        _lastPosition = position;

        // Update journey time
        if (_startTime != null) {
          final duration = DateTime.now().difference(_startTime!);
          journeyTime.value = duration.inMinutes;
        }
      } catch (e) {
        // Silently handle location errors during scanning
        print('Location tracking error: $e');
      }
    });
  }

  void _startAutomaticCapture() {
    _captureTimer?.cancel(); // Cancel any existing timer

    print('Starting automatic capture timer...');

    _captureTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      print(
          'Automatic capture timer fired. Scanning: ${isScanning.value}, Paused: ${isPaused.value}, Live: ${liveDetection.value}');

      if (!isScanning.value || isPaused.value || !liveDetection.value) {
        print('Cancelling automatic capture timer');
        timer.cancel();
        return;
      }

      print('Calling _captureAndAnalyze...');
      await _captureAndAnalyze();
    });
  }

  Future<void> _captureAndAnalyze() async {
    if (_isCapturing) {
      print('Capture already in progress, skipping...');
      return;
    }

    if (cameraController == null || !cameraController!.value.isInitialized) {
      print('Camera not ready for capture');
      return;
    }

    _isCapturing = true;
    try {
      print('Taking picture...');
      final image = await cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      print('Picture taken, size: ${bytes.length} bytes');

      // Get current location
      print('Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('Position: ${position.latitude}, ${position.longitude}');

      // Upload and analyze
      print('Uploading pothole to API...');
      final result = await ApiManager.instance.uploadPothole(
        position.latitude,
        position.longitude,
        bytes,
        'pothole_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      print('API response: $result');

      if (result['message'] == 'no pothole detected') {
        // No pothole detected, continue silently
        print(
            'No pothole detected at ${position.latitude}, ${position.longitude}');
      } else {
        // Pothole detected!
        detectedCount.value += 1;

        if (audioEnabled.value) {
          // Could add audio feedback here
        }

        CustomSnackbar.success(
          title: 'Pothole Detected!',
          message: 'Pothole reported at current location.',
        );
      }
    } catch (e) {
      // Silently handle capture errors during scanning
      print('Auto-capture error: $e');
    } finally {
      _isCapturing = false;
    }
  }

  Future<void> toggleFlash() async {
    final ctrl = cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    try {
      flashOn.toggle();
      await ctrl.setFlashMode(flashOn.value ? FlashMode.torch : FlashMode.off);
    } catch (e) {
      flashOn.value = false;
      cameraError.value = 'Flash error: $e';
    }
  }

  Future<void> initCamera() async {
    try {
      isInitializingCamera.value = true;
      // Request permissions
      final camStatus = await Permission.camera.request();
      final locStatus = await Permission.location.request();
      if (!camStatus.isGranted) {
        cameraError.value = 'Camera permission denied';
        isInitializingCamera.value = false;
        return;
      }
      if (!locStatus.isGranted) {
        cameraError.value = 'Location permission denied';
        isInitializingCamera.value = false;
        return;
      }
      cameraDescriptions = await fetchAvailableCameras();
      final preferred = cameraDescriptions.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameraDescriptions.first,
      );
      cameraController = CameraController(
        preferred,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await cameraController!.initialize();
    } catch (e) {
      cameraError.value = e.toString();
    } finally {
      isInitializingCamera.value = false;
      update();
    }
  }

  // Extracted for testability
  Future<List<CameraDescription>> fetchAvailableCameras() => availableCameras();

  @override
  void onInit() {
    super.onInit();
    initCamera();
  }

  @override
  void onClose() {
    cameraController?.dispose();
    _locationTimer?.cancel();
    _captureTimer?.cancel();
    super.onClose();
  }
}
