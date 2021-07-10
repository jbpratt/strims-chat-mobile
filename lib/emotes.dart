import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';

import 'emote_manifest.dart';

final Uri kEmoteManifest =
    Uri.parse('https://chat.strims.gg/emote-manifest.json');

Map<String, Emote> kEmotes = <String, Emote>{};

class Emote {
  Emote(
      {required this.name,
      required this.img,
      required this.img2X,
      required this.img3X});
  String name;
  Image img;
  Image img2X;
  Image img3X;
}

Future<Map<String, Emote>> getEmotes() async {
  final out = <String, Emote>{};
  final headers = <String, String>{'user-agent': 'mobile.chat.strims.gg'};
  final response = await get(kEmoteManifest, headers: headers);
  if (response.statusCode == 200) {
    final manifest = Manifest.fromJson(response.body);
    for (final emote in manifest.emotes) {
      // TODO: download and cache images
      AssetImage img;
      try {
        img = AssetImage('assets/${emote.name}');
      } catch (e) {
        img = const AssetImage('assets/default');
      }

      out[emote.name] = Emote(
          name: emote.name,
          img: Image(
            image: img,
            height: 16,
          ),
          img2X: Image(
            image: img,
            height: 32,
          ),
          img3X: Image(
            image: img,
            height: 48,
          ));
    }
  } else {
    print('Request failed with status: ${response.statusCode}.');
  }
  return out;
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
