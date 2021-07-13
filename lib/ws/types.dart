import 'dart:convert';

import 'package:tuple/tuple.dart';

import '../utilities.dart';

// First index is type, then data
Tuple2<MsgType, String> _parseMsgType(String msg) {
  final split = msg.split(' ');
  final t = split[0].trim();
  final m = split.sublist(1).join(' ');
  // this is safe because _parseMsg is only called after a MsgType switch
  return Tuple2<MsgType, String>(msgTypeValues.map[t]!, m);
}

class Message {
  Message({
    this.user,
    this.timestamp,
    this.entities,
    required this.data,
    required this.type,
  });

  factory Message.fromJson(MsgType type, String str) =>
      Message.fromMap(type, json.decode(str));

  factory Message.fromMap(MsgType type, Map<String, dynamic> json) => Message(
        user: User(nick: json['nick'], features: [...json['features']]),
        timestamp: json['timestamp'],
        entities: Entities.fromMap(json['entities']),
        data: json['data'],
        type: type,
      );

  factory Message.fromWire(String msg) {
    final raw = _parseMsgType(msg);
    print('raw: $msg');
    return Message.fromJson(raw.item1, raw.item2);
  }

  final String data;
  final MsgType type;
  final User? user;
  final int? timestamp;
  final Entities? entities;

  String toJson() => json.encode(toMap()..removeWhere((_, v) => v == null));

  Map<String, dynamic> toMap() => {
        'user': user?.toMap(),
        'timestamp': timestamp,
        'data': data,
        'type': msgTypeValues.reverse[type],
        'entities': entities?.toMap(),
      };

  String toWireString() {
    final output = json
        .encode(toMap()
          ..remove('features')
          ..remove('timestamp')
          ..remove('entities')
          ..remove('type')
          ..putIfAbsent('nick', () => user?.nick)
          ..removeWhere((_, v) => v == null))
        .toString();
    return '${msgTypeValues.reverse[type]} $output';
  }
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
    // required this.greentext
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

class Chatters {
  Chatters({
    required this.users,
    required this.connectioncount,
  });

  factory Chatters.fromJson(String str) => Chatters.fromMap(json.decode(str));

  factory Chatters.fromMap(Map<String, dynamic> json) => Chatters(
        users:
            List<User>.from(json['users'].map((dynamic x) => User.fromMap(x))),
        connectioncount: json['connectioncount'],
      );

  factory Chatters.fromWire(String msg) {
    final raw = _parseMsgType(msg);
    print('raw: $msg');
    return Chatters.fromJson(raw.item2);
  }

  final List<User> users;
  final int connectioncount;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
        'users': List<dynamic>.from(users.map((x) => x.toMap())),
        'connectioncount': connectioncount,
      };
}

class User {
  User({
    required this.nick,
    required this.features,
  });

  factory User.fromJson(String str) => User.fromMap(json.decode(str));

  factory User.fromMap(Map<String, dynamic> json) => User(
        nick: json['nick'],
        features: List<String>.from(json['features'].map((dynamic x) => x)),
      );

  final String nick;
  final List<String> features;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
        'nick': nick,
        'features': List<dynamic>.from(features.map((x) => x)),
      };
}
