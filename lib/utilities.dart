import 'dart:math';

import 'package:flutter/material.dart';

class TextEditingControllerWorkaroud extends TextEditingController {
  TextEditingControllerWorkaroud({String text = ''}) : super(text: text);

  void setTextAndPosition(String newText, {int caretPosition = 0}) {
    final int offset = caretPosition != 0 ? caretPosition : newText.length;
    value = value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: offset),
        composing: TextRange.empty);
  }
}

class Utilities {
  static Color flipColor(Color color, int offset) {
    final int r = color.red;
    final int g = color.green;
    final int b = color.blue;
    final double lum = color.computeLuminance();
    // if the input color is brighter then 5% brightness, we  make the output darker
    if (lum > 0.05) {
      offset *= -1;
    }

    final int newR = min(max(0, r + offset), 255);
    final int newG = min(max(0, g + offset), 255);
    final int newB = min(max(0, b + offset), 255);
    return Color.fromARGB(255, newR, newG, newB);
  }

  static Color lightenColor(Color color, int offset) {
    final int r = color.red;
    final int g = color.green;
    final int b = color.blue;

    final int newR = min(r + offset, 255);
    final int newG = min(g + offset, 255);
    final int newB = min(b + offset, 255);
    return Color.fromARGB(255, newR, newG, newB);
  }

  static Color darkenColor(Color color, int offset) {
    final int r = color.red;
    final int g = color.green;
    final int b = color.blue;

    final int newR = max(r + offset, 0);
    final int newG = max(g + offset, 0);
    final int newB = max(b + offset, 0);
    return Color.fromARGB(255, newR, newG, newB);
  }
}
