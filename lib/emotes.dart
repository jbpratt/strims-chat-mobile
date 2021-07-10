import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';

final Uri kEmoteAddress = Uri.dataFromString(
    'https://raw.githubusercontent.com/memelabs/chat-gui/master/assets/emotes.json');

Map<String, Emote> kEmotes = <String, Emote>{};

class Emote {
  String name;
  Image img;
  Image img2X;
  Image img3X;

  Emote({this.name, this.img, this.img2X, this.img3X});
}

Future<Map<String, Emote>> getEmotes() async {
  var headers = <String, String>{};
  headers['user-agent'] = 'mobile.chat.strims.gg';
  var response = await get(kEmoteAddress, headers: headers);
  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);
    List<dynamic> y = jsonResponse['default'];
    Map<String, Emote> out = <String, Emote>{};
    for (int i = 0; i < y.length; i++) {
      AssetImage x = AssetImage('assets/${y[i]}');
      out[y[i]] = Emote(
          name: y[i],
          img: Image(
            image: x,
            height: 16,
          ),
          img2X: Image(
            image: x,
            height: 32,
          ),
          img3X: Image(
            image: x,
            height: 48,
          ));
    }
    return out;
  } else {
    print('Request failed with status: ${response.statusCode}.');
  }
  return null;
}

List<String> kEmoteModifiers = [
  'spin',
  'flip',
  'mirror',
  'rustle',
  'love',
  'worth',
  'rain',
  'snow',
  'wide',
];
