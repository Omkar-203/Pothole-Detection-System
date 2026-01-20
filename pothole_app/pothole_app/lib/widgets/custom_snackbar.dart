import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackbar {
  static void show({
    required String title,
    required String message,
    Color backgroundColor = Colors.blue,
    Color textColor = Colors.white,
    IconData icon = Icons.info,
    Duration duration = const Duration(seconds: 3),
    SnackPosition snackPosition = SnackPosition.TOP,
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: backgroundColor,
      colorText: textColor,
      icon: Icon(icon, color: textColor),
      snackPosition: snackPosition,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static void success({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackPosition snackPosition = SnackPosition.TOP,
  }) {
    show(
      title: title,
      message: message,
      backgroundColor: const Color(0xFF00C07F),
      icon: Icons.check_circle,
      duration: duration,
      snackPosition: snackPosition,
    );
  }

  static void error({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackPosition snackPosition = SnackPosition.TOP,
  }) {
    show(
      title: title,
      message: message,
      backgroundColor: const Color(0xFFFF4444),
      icon: Icons.error,
      duration: duration,
      snackPosition: snackPosition,
    );
  }

  static void warning({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackPosition snackPosition = SnackPosition.TOP,
  }) {
    show(
      title: title,
      message: message,
      backgroundColor: const Color(0xFFFFA500),
      icon: Icons.warning,
      duration: duration,
      snackPosition: snackPosition,
    );
  }

  static void info({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackPosition snackPosition = SnackPosition.TOP,
  }) {
    show(
      title: title,
      message: message,
      backgroundColor: const Color(0xFF0046FF),
      icon: Icons.info,
      duration: duration,
      snackPosition: snackPosition,
    );
  }
}
