import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../controller/scan_controller.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  void _showInstructions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scanning Instructions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            instructionItem(
              index: 1,
              text:
                  'Live Detection is always enabled for automatic pothole scanning while driving',
            ),
            instructionItem(
              index: 2,
              text:
                  'Use the gallery button to upload and analyze existing images',
            ),
            instructionItem(
              index: 3,
              text:
                  'Live coordinates and journey tracking are always active during scanning',
            ),
            instructionItem(
              index: 4,
              text: 'Audio alerts notify you when potholes are detected',
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ScanController());
    return Scaffold(
      backgroundColor: const Color(0xFF07142B),
      appBar: AppBar(
        title: const Text('Scan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showInstructions(context),
            tooltip: 'Instructions',
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2040), Color(0xFF00040A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Obx(
                      () => toggleButton(
                        active: c.audioEnabled.value,
                        label: 'Audio',
                        icon: Icons.volume_up_rounded,
                        onTap: c.toggleAudio,
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Obx(
                          () => Text(
                            '${c.journeyDistance.value.toStringAsFixed(2)} km',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${c.journeyTime.value}min journey',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth - 20) / 3;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          child: Obx(
                            () => miniStat(
                              'Detected',
                              c.detectedCount.value.toString(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: Obx(
                            () => miniStat(
                              'Live Location',
                              '${c.latitude.value.toStringAsFixed(4)}, ${c.longitude.value.toStringAsFixed(4)}',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: Obx(
                            () => miniStat(
                              'Speed',
                              '${c.currentSpeed.value.toStringAsFixed(1)} km/h',
                              valueColor: c.currentSpeed.value > 30
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Obx(() {
                    final initializing = c.isInitializingCamera.value;
                    final error = c.cameraError.value;
                    final controller = c.cameraController;
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF050B16),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.blueAccent.withOpacity(.4),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (error != null)
                            Center(
                              child: Text(
                                error,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            )
                          else if (initializing ||
                              controller == null ||
                              !controller.value.isInitialized)
                            const Center(child: CircularProgressIndicator())
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CameraPreview(controller),
                            ),
                          Positioned(
                            top: 8,
                            left: 8,
                            right: 8,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [corner(), corner()],
                            ),
                          ),
                          Positioned(
                            bottom: 110,
                            left: 8,
                            right: 8,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [corner(), corner()],
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 16,
                            child: Obx(
                              () => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(.45),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  c.isScanning.value
                                      ? (c.isPaused.value
                                          ? 'Paused'
                                          : 'Scanning')
                                      : 'Ready',
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 120,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFF050B16),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Obx(
                                () => Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    squareButton(
                                      icon: c.flashOn.value
                                          ? Icons.flash_on
                                          : Icons.flash_off,
                                      onTap: c.toggleFlash,
                                    ),
                                    const SizedBox(width: 34),
                                    GestureDetector(
                                      onTap: () {
                                        if (!c.isScanning.value) {
                                          c.startScanning();
                                        } else {
                                          c.stopScanning();
                                        }
                                      },
                                      child: Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: c.isScanning.value
                                                ? [
                                                    Colors.red.shade600,
                                                    Colors.redAccent,
                                                  ]
                                                : const [
                                                    Color(0xFF0084FF),
                                                    Color(0xFF00D2FF),
                                                  ],
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black54,
                                              blurRadius: 16,
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          c.isScanning.value
                                              ? Icons.stop
                                              : Icons.play_arrow,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 34),
                                    // Obx(() => squareButton(
                                    //       icon: c.isScanning.value
                                    //           ? (c.isPaused.value
                                    //               ? Icons.play_arrow
                                    //               : Icons.pause)
                                    //           : Icons.more_horiz,
                                    //       onTap: () {
                                    //         if (!c.isScanning.value) return;
                                    //         if (c.isPaused.value) {
                                    //           c.resumeScanning();
                                    //         } else {
                                    //           c.pauseScanning();
                                    //         }
                                    //       },
                                    //     )),
                                    // const SizedBox(width: 16),
                                    Obx(() => squareButton(
                                          icon: c.isUploading.value
                                              ? Icons.hourglass_empty
                                              : Icons.photo_library,
                                          onTap: c.isUploading.value
                                              ? null
                                              : c.pickAndAnalyzeImage,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper widget builder functions
Widget instructionItem({required int index, required String text}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(right: 12),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF0F2040),
          ),
          child: Text(
            index.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, height: 1.35)),
        ),
      ],
    ),
  );
}

Widget toggleButton({
  required bool active,
  required String label,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF0F2040) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0F2040)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: active ? Colors.white : const Color(0xFF0F2040),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.white : const Color(0xFF0F2040),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget corner() {
  return Container(
    width: 40,
    height: 2,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.cyanAccent.withOpacity(.8), Colors.transparent],
      ),
    ),
  );
}

Widget miniStat(String label, String value, {Color? valueColor}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    ),
  );
}

Widget squareButton({required IconData icon, VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: onTap == null ? Colors.grey : Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 22, color: const Color(0xFF0F2040)),
    ),
  );
}
