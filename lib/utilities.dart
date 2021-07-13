import 'dart:math';
import 'package:flutter/material.dart';

class EnumValues<T> {
  EnumValues(this.map);

  Map<String, T> map;

  Map<T, String> get reverse {
    return map.map((k, v) => MapEntry(v, k));
  }
}

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
  static String humanizeTimestamp(int? timestamp) {
    if (timestamp != null) {
      final DateTime d =
          DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true).toLocal();
      String hour = d.hour.toString();
      String minute = d.minute.toString();
      if (hour.length == 1) {
        hour = '0$hour';
      }
      if (minute.length == 1) {
        minute = '0$minute';
      }
      return '$hour:$minute';
    }
    return '';
  }

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

  static Color colorFromName(String name) {
    switch (name) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'blue':
        return Colors.blue;
      case 'sky':
        return Colors.cyan;
      case 'lime':
        return Colors.lime;
      case 'pink':
        return Colors.pink;
      case 'black':
        return Colors.grey;
      default:
        return Colors.transparent;
    }
  }
}
