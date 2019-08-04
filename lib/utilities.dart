import 'dart:math';

import 'package:flutter/material.dart';

class Utilities {
  static Color flipColor(Color color, int offset) {
    int r = color.red;
    int g = color.green;
    int b = color.blue;
    double lum = color.computeLuminance();
    if (lum > 0.3) {
      offset *= -1;
    }

    int newR = min(max(0, r + offset), 255);
    int newG = min(max(0, g + offset), 255);
    int newB = min(max(0, b + offset), 255);
    Color newColor = Color.fromARGB(255, newR, newG, newB);

    return newColor;
  }

  static Color lightenColor(Color color, int offset) {
    int r = color.red;
    int g = color.green;
    int b = color.blue;

    int newR = min(r + offset, 255);
    int newG = min(g + offset, 255);
    int newB = min(b + offset, 255);
    Color newColor = Color.fromARGB(255, newR, newG, newB);

    return newColor;
  }

  static Color darkenColor(Color color, int offset) {
    int r = color.red;
    int g = color.green;
    int b = color.blue;

    int newR = max(r + offset, 0);
    int newG = max(g + offset, 0);
    int newB = max(b + offset, 0);
    Color newColor = Color.fromARGB(255, newR, newG, newB);

    return newColor;
  }
}