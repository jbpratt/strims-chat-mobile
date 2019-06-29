import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Majora',
      theme: ThemeData(primarySwatch: Colors.blueGrey),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WebSocketChannel channel;
  TextEditingController controller;
  List<Message> list = [];

  @override
  void initState() {
    super.initState();
    channel = IOWebSocketChannel.connect('wss://chat.strims.gg/ws');
    controller = TextEditingController();
    channel.stream.listen((onData) {
      handleReceive(onData);
    }, onError: (error) {
      print(error.toString());
    });
  }

  void sendData() {
    if (controller.text.isNotEmpty) {
      channel.sink.add(controller.text);
      controller.text = "";
    }
  }

  void handleReceive(String msg) {
    String rec = msg.split(new RegExp(r"{[^}]*}"))[0];
    String content = msg.split(new RegExp(r"^[^ ]*"))[1];
    if (rec.trim() == "MSG") {
      var m = new Message.fromJson(json.decode(content));
      setState(() => list.add(m));
    }
    return null;
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Timer(Duration(milliseconds: 1000), () => _controller.jumpTo(_controller.position.maxScrollExtent));
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(20.0),
        child: ListView(
          children: <Widget>[
            MessageList(
                list), //list.map((data) => Text(data.nick+" : "+data.data)).toList(),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: Icon(Icons.send),
      //   onPressed: () {
      //     sendData();
      //   },
      // ),
    );
  }
}

class MessageList extends StatelessWidget {
  final ScrollController _controller = ScrollController();
  final List<Message> _messages;

  MessageList(this._messages);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      reverse: true,
      padding: EdgeInsets.symmetric(vertical: 8.0),
      controller: _controller,
      itemCount: _messages.length,
      itemBuilder: (BuildContext ctx, int index) {
        return Card(
          child: _MessageListItem(_messages[index]),
        );
      },
    );
  }
}

class _MessageListItem extends ListTile {
  _MessageListItem(Message msg)
      : super(
          dense: true,
          title: Text(msg.data),
          subtitle: Text(msg.nick),
        );
}

class Message {
  String nick;
  int timestamp;
  String data;

  Message({this.nick, this.timestamp, this.data});

  factory Message.fromJson(Map parsedJson) {
    return Message(
        nick: parsedJson['nick'],
        timestamp: parsedJson['timestamp'],
        data: parsedJson['data']);
  }
}
