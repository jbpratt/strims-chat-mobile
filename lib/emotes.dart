import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';

final String kEmoteAddress =
    "https://raw.githubusercontent.com/memelabs/chat-gui/master/assets/emotes.json";

Map<String, Emote> kEmotes = new Map<String, Emote>();

class Emote {
  String name;
  Image img;
  //AssetImage img;

  Emote({this.name, this.img});
}

Future<Map<String, Emote>> getEmotes() async {
  var response = await get(kEmoteAddress);
  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);
    List<dynamic> y = jsonResponse['default'];
    Map<String, Emote> out = new Map<String, Emote>();
    for (int i = 0; i < y.length; i++) {
      var x = AssetImage('assets/${y[i]}');
      out[y[i]] = Emote(
          name: y[i],
          img: Image(
            image: x,
            height: 16,
          ));
    }
    return out;
  } else {
    print("Request failed with status: ${response.statusCode}.");
  }
  return null;
}

List<String> kEmoteModifiers = [
  "spin",
  "flip",
  "mirror",
  "rustle",
  "love",
  "worth",
  "rain",
  "snow",
];
