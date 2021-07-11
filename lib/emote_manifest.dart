// To parse this JSON data, do
//
//     final manifest = manifestFromMap(jsonString);

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import 'constants.dart';
import 'utilities.dart';

final Uri kEmoteManifest = Uri.parse('$CHAT_HTTPS_URL/emote-manifest.json');

class Manifest {
  Manifest({
    required this.emotes,
    required this.css,
    required this.modifiers,
    required this.tags,
  });

  factory Manifest.fromJson(String str) => Manifest.fromMap(json.decode(str));

  factory Manifest.fromMap(Map<String, dynamic> json) => Manifest(
        emotes: List<Emote>.from(
            json['emotes'].map((dynamic x) => Emote.fromMap(x))),
        css: json['css'],
        modifiers: List<String>.from(json['modifiers'].map((dynamic x) => x)),
        tags: List<String>.from(json['tags'].map((dynamic x) => x)),
      );

  // TODO: can this be a map for lookup?
  final List<Emote> emotes;
  final String css;
  final List<String> modifiers;
  final List<String> tags;

  Emote? emote(String name) {
    for (final e in emotes) {
      if (e.name == name) {
        return e;
      }
    }
  }

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
        'emotes': List<dynamic>.from(emotes.map((x) => x.toMap())),
        'css': css,
        'modifiers': List<dynamic>.from(modifiers.map((x) => x)),
        'tags': List<dynamic>.from(tags.map((x) => x)),
      };

  static Future<Manifest> fromURL(Uri url) async {
    final headers = <String, String>{'user-agent': 'mobile.chat.strims.gg'};
    final response = await get(kEmoteManifest, headers: headers);
    if (response.statusCode != 200) {
      // throw error
    }

    final manifest = Manifest.fromJson(response.body);
    for (final emote in manifest.emotes) {
      for (final version in emote.versions) {
        debugPrint('adding ${emote.name} into cache');
        emote.images[version.size] = CachedNetworkImage(
          placeholder: (context, url) => const CircularProgressIndicator(),
          imageUrl: '$CHAT_HTTPS_URL/${version.path}',
        );
      }
    }
    return manifest;
  }
}

class Emote {
  Emote({
    required this.name,
    required this.versions,
  });

  factory Emote.fromJson(String str) => Emote.fromMap(json.decode(str));

  factory Emote.fromMap(Map<String, dynamic> json) => Emote(
        name: json['name'],
        versions: List<Version>.from(
            json['versions'].map((dynamic x) => Version.fromMap(x))),
      );

  final String name;
  final List<Version> versions;

  Images images = {};

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
        'name': name,
        'versions': List<dynamic>.from(versions.map((x) => x.toMap())),
      };
}

typedef Images = Map<Size, CachedNetworkImage>;

class Version {
  Version({
    required this.path,
    required this.animated,
    required this.dimensions,
    required this.size,
  });

  factory Version.fromJson(String str) => Version.fromMap(json.decode(str));

  factory Version.fromMap(Map<String, dynamic> json) => Version(
        path: json['path'],
        animated: json['animated'],
        dimensions: Dimensions.fromMap(json['dimensions']),
        size: sizeValues.map[json['size']]!,
      );

  final String path;
  final bool animated;
  final Dimensions dimensions;
  final Size size;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
        'path': path,
        'animated': animated,
        'dimensions': dimensions.toMap(),
        'size': sizeValues.reverse[size],
      };
}

class Dimensions {
  Dimensions({
    required this.height,
    required this.width,
  });

  factory Dimensions.fromJson(String str) =>
      Dimensions.fromMap(json.decode(str));

  factory Dimensions.fromMap(Map<String, dynamic> json) => Dimensions(
        height: json['height'],
        width: json['width'],
      );

  final int height;
  final int width;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
        'height': height,
        'width': width,
      };
}

enum Size { THE_1_X, THE_2_X, THE_4_X }

final sizeValues =
    EnumValues({'1x': Size.THE_1_X, '2x': Size.THE_2_X, '4x': Size.THE_4_X});
