import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants.dart';
import 'types.dart';

class WSClient {
  WSClient(
      {this.address = CHAT_WS_URL, this.token = '', this.user = 'Anonymous'});

  String address;
  String token;
  String user;

  late WebSocketChannel _channel;
  late void Function(Message msg) onMsgFunc;
  late void Function(Message msg) onPrivMsgFunc;
  late void Function(Chatters msg) onNamesMsgFunc;
  final headers = <String, String>{'user-agent': 'mobile.chat.strims.gg'};

  bool get isAuthenticated => token.isNotEmpty && user != 'Anonymous';

  void logout() {
    token = '';
    user = 'Anonymous';
    reset();
  }

  void reset() {
    close();
    dial();
  }

  void send(Message msg) {
    if (isAuthenticated) _channel.sink.add(msg.toWireString());
  }

  void listen() {
    _channel.stream.listen((data) {
      if (data is String) {
        final type = msgTypeValues.map[data.split(' ')[0].trim()];
        switch (type) {
          case MsgType.NAMES:
            final msg = Chatters.fromWire(data);
            onNamesMsgFunc(msg);
            break;
          case MsgType.MSG:
            final msg = Message.fromWire(data);
            onMsgFunc(msg);
            break;
          case MsgType.PRIVMSG:
            final msg = Message.fromWire(data);
            onPrivMsgFunc(msg);
            break;
          case MsgType.JOIN:
          case MsgType.QUIT:
            // TODO: handle jsoin/quit
            break;
          default:
          // throw error
        }
      }
    });
  }

  void close() {
    _channel.sink.close();
  }

  void dial() => _channel = IOWebSocketChannel.connect(address,
      headers: token.isNotEmpty ? {'Cookie': 'jwt=$token'} : {});

  Future<List<Message>?> history() async {
    final Response response = await get(
        Uri.parse('$CHAT_HTTPS_URL/api/chat/history'),
        headers: headers);
    if (response.statusCode == 200) {
      final out = jsonDecode(response.body) as List;
      return out.map((m) => Message.fromWire(m.toString())).toList();
    } else {
      debugPrint('Request failed with status: ${response.statusCode}.');
    }
  }

  Future<void> login(String token) async {
    this.token = token;
    headers['Cookie'] = 'jwt=$token';
    final Response response =
        await get(Uri.parse('$CHAT_HTTPS_URL/api/profile'), headers: headers);
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      user = jsonResponse['username'].toString();
    } else {
      debugPrint('Request failed with status: ${response.statusCode}.');
    }
  }
}
