import 'dart:convert';

import 'package:tuple/tuple.dart';

import '../utilities.dart';

// final message = messageFromMap(jsonString);
class Message {
  Message({
    required this.nick,
    required this.features,
    required this.timestamp,
    required this.data,
    required this.entities,
    required this.type,
  });

  factory Message.fromJson(String str) => Message.fromMap(json.decode(str));

  // TODO: pass type in?
  factory Message.fromMap(Map<String, dynamic> json) => Message(
        nick: json['nick'],
        features: List<String>.from(json['features'].map((dynamic x) => x)),
        timestamp: json['timestamp'],
        data: json['data'],
        entities: Entities.fromMap(json['entities']),
        type: null,
      );

  factory Message.fromWire(String msg) {
    final raw = _parseMsg(msg);
    print('raw: $msg');
    return Message.fromJson(raw.item2)..type = raw.item1;
  }

  // First index is type, then data
  static Tuple2<MsgType, String> _parseMsg(String msg) {
    final split = msg.split(' ');
    final t = split[0].trim();
    final m = split.sublist(1).join(' ');
    // this is safe because _parseMsg is only called after a MsgType switch
    return Tuple2<MsgType, String>(msgTypeValues.map[t]!, m);
  }

  final String nick;
  final List<String> features;
  final int timestamp;
  final String data;
  final Entities? entities;
  MsgType? type;

  String toJson() => json.encode(toMap()..removeWhere((_, v) => v == null));

  Map<String, dynamic> toMap() => {
        'nick': nick,
        'features': List<dynamic>.from(features.map((x) => x)),
        'timestamp': timestamp,
        'data': data,
        'entities': entities?.toMap(),
      };
}

final msgTypeValues = EnumValues({
  'MSG': MsgType.MSG,
  'PRIVMSG': MsgType.PRIVMSG,
  'NAMES': MsgType.NAMES,
  'JOIN': MsgType.JOIN,
  'QUIT': MsgType.QUIT
});

enum MsgType { MSG, PRIVMSG, NAMES, JOIN, QUIT }

class Entities {
  Entities({
    required this.emotes,
    required this.codes,
    required this.spoilers,
    // required this.greentext,
  });

  factory Entities.fromJson(String str) => Entities.fromMap(json.decode(str));

  factory Entities.fromMap(Map<String, dynamic> json) => Entities(
        emotes: List<EmoteInMessage>.from(
            json['emotes']?.map((dynamic x) => EmoteInMessage.fromMap(x)) ??
                []),
        codes: List<Greentext>.from(
            json['codes']?.map((dynamic x) => Greentext.fromMap(x)) ?? []),
        spoilers: List<Greentext>.from(
            json['spoilers']?.map((dynamic x) => Greentext.fromMap(x)) ?? []),
        //      greentext: Greentext.fromMap(json['greentext']),
      );

  final List<EmoteInMessage> emotes;
  final List<Greentext> codes;
  final List<Greentext> spoilers;
  // Greentext? greentext;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
        'emotes': List<dynamic>.from(emotes.map((x) => x.toMap())),
        'codes': List<dynamic>.from(codes.map((x) => x.toMap())),
        'spoilers': List<dynamic>.from(spoilers.map((x) => x.toMap())),
//        'greentext': greentext.toMap(),
      };
}

class Greentext {
  Greentext({
    required this.bounds,
  });

  factory Greentext.fromJson(String str) => Greentext.fromMap(json.decode(str));
  factory Greentext.fromMap(Map<String, dynamic> json) => Greentext(
        bounds: List<int>.from(json['bounds'].map((dynamic x) => x)),
      );

  final List<int> bounds;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
        'bounds': List<dynamic>.from(bounds.map((x) => x)),
      };
}

class EmoteInMessage {
  EmoteInMessage({
    required this.name,
    required this.bounds,
    required this.modifiers,
  });

  factory EmoteInMessage.fromJson(String str) =>
      EmoteInMessage.fromMap(json.decode(str));

  factory EmoteInMessage.fromMap(Map<String, dynamic> json) => EmoteInMessage(
        name: json['name'],
        bounds: List<int>.from(json['bounds']?.map((dynamic x) => x) ?? []),
        modifiers:
            List<String>.from(json['modifiers']?.map((dynamic x) => x) ?? []),
      );

  final String name;
  final List<int> bounds;
  final List<String> modifiers;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
        'name': name,
        'bounds': List<dynamic>.from(bounds.map((x) => x)),
        'modifiers': List<dynamic>.from(modifiers.map((x) => x)),
      };
}
