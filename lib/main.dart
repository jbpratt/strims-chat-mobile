import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(App());

User kUser = new User();
final String kAppTitle = "Strims";
final String kLogoPath = "assets/ComfyApe.png";
final String kAddress = "wss://chat.strims.gg/ws";
final AppBar kAppBar = new AppBar(
  title: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(
        kLogoPath,
        fit: BoxFit.contain,
        height: 24,
      ),
      Container(padding: const EdgeInsets.all(8.0), child: Text('Strims'))
    ],
  ),
);

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: new HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: kAppBar,
        body: Container(
          child: new Column(
            children: <Widget>[
              Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RaisedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (ctxt) => new ChatPage()),
                      );
                    },
                    child: const Text('chat', style: TextStyle(fontSize: 10)),
                  )),
              Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RaisedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (ctxt) => new ProfilePage()),
                      );
                    },
                    child:
                        const Text('profile', style: TextStyle(fontSize: 10)),
                  )),
            ],
          ),
        ));
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController nickController = TextEditingController();
  TextEditingController jwtController = TextEditingController();

  saveData() {
    if (nickController.text.isNotEmpty && jwtController.text.isNotEmpty) {
      kUser.nick = nickController.text;
      nickController.text = "";
      kUser.jwt = jwtController.text;
      jwtController.text = "";
      Navigator.of(context).pop(ProfilePage);
    }
  }

  resetData() {
    if (kUser.nick.isNotEmpty) {
      kUser.nick = "";
    }
    if (kUser.jwt.isNotEmpty) {
      kUser.jwt = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kAppBar,
      body: Container(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: nickController,
                decoration: InputDecoration(
                  labelText: 'Enter your username',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: jwtController,
                decoration: InputDecoration(
                  labelText: 'Enter your jwt',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Builder(
                builder: (context) {
                  return RaisedButton(
                    onPressed: () => saveData(),
                    color: Colors.indigoAccent,
                    child: Text('save'),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Builder(
                builder: (context) {
                  return RaisedButton(
                    onPressed: () => resetData(),
                    color: Colors.indigoAccent,
                    child: Text('reset'),
                  );
                },
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.all(16.0),
            //   child: Text(
            //     kUser.nick,
            //     textAlign: TextAlign.center,
            //   ),
            // ),
            // Padding(
            //   padding: const EdgeInsets.all(16.0),
            //   child: Text(
            //     kUser.jwt,
            //     overflow: TextOverflow.ellipsis,
            //     textAlign: TextAlign.center,
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  WebSocketChannel channel;
  TextEditingController controller;
  List<Message> list = [];
  //List<Widget> output;

  @override
  void initState() {
    super.initState();
    String jwt = kUser.jwt;
    channel = IOWebSocketChannel.connect(kAddress,
        headers: jwt?.isNotEmpty == true ? {'Cookie': 'jwt=$jwt'} : {});
    controller = TextEditingController();
    channel.stream.listen((onData) {
      handleReceive(onData);
    }, onError: (error) {
      print(error.toString());
    });
  }

  void sendData() {
    if (controller.text.isNotEmpty) {
      channel.sink.add('MSG {"data":"' + controller.text + '"}');
      controller.text = "";
    }
  }

  void handleReceive(String msg) {
    String rec = msg.split(new RegExp(r"{[^}]*}"))[0];
    String content = msg.split(new RegExp(r"^[^ ]*"))[1];
    Message m = new Message.fromJson(rec.trim(), json.decode(content));
    if (m.type == "MSG") {
      var x = m.data.split(" ");
      for (int i = 0; i < x.length; i++) {
        print(x[i]);
        // use TextSpan maybe
        //output.add(Text(x[i]));
      }
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
    String label;
    if (kUser.nick == null || kUser.nick.isEmpty) {
      label = "You need to be signed in to chat";
    } else {
      label = 'Write something ${kUser.nick}';
    }

    return Scaffold(
      appBar: kAppBar,
      body: Container(
        decoration: new BoxDecoration(color: Colors.black),
        padding: EdgeInsets.all(5.0),
        child: ListView(
          children: <Widget>[
            Form(
              child: new TextFormField(
                decoration: new InputDecoration(
                  labelText: label,
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
        child: Icon(Icons.send),
        onPressed: () {
          sendData();
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
          child: _MessageListItem(_messages[index]), // WidgetSpan()
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
            subtitle: Text(msg.readTimestamp() + " " + msg.nick,
                style: TextStyle(
                  color: Colors.grey[600],
                )),
            onTap: () {});
}

class Message {
  String type;
  String nick;
  int timestamp;
  String data;

  Message({this.type, this.nick, this.timestamp, this.data});

  String readTimestamp() {
    DateTime d =
        new DateTime.fromMillisecondsSinceEpoch(this.timestamp, isUtc: true);
    return d.hour.toString() + ":" + d.minute.toString();
  }

  factory Message.fromJson(String type, Map parsedJson) {
    return Message(
        type: type,
        nick: parsedJson['nick'],
        timestamp: parsedJson['timestamp'],
        data: parsedJson['data']);
  }
}

class User {
  String nick;
  String jwt;

  User({this.nick, this.jwt});
}

class Emote {
  String name;
  String path;

  Emote({this.name, this.path});
}
