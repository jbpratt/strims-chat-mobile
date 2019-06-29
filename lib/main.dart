import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: new ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class SecondScreen extends StatelessWidget {
  @override
  Widget build(BuildContext ctxt) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Auth"),
      ),
      body: new Text("TODO: second page"),
    );
  }
}

class _ChatPageState extends State<ChatPage> {
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
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: new BoxDecoration(color: Colors.black),
        padding: EdgeInsets.all(5.0),
        child: ListView(
          children: <Widget>[
            Form(
              child: new TextFormField(
                decoration: new InputDecoration(
                  labelText: "Write something {user} ...",
                  fillColor: Colors.grey[900],
                  filled: true,
                ),
                controller: controller,
              ),
            ),
            MessageList(list),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.perm_identity),
        onPressed: () {
          //sendData();
          Navigator.push(
            context,
            new MaterialPageRoute(builder: (ctxt) => new SecondScreen()),
          );
        },
      ),
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
      controller: _controller,
      itemCount: _messages.length,
      itemBuilder: (BuildContext ctx, int index) {
        return Card(
          color: Colors.grey[900],
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
            title: Text(msg.data,
                style: TextStyle(
                  color: Colors.grey[400],
                )),
            subtitle: Text(msg.nick,
                style: TextStyle(
                  color: Colors.grey[600],
                )),
            onTap: () {});
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
