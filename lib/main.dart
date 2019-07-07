import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:majora/browser.dart';
import 'package:majora/emotes.dart';
import 'package:majora/messages.dart';
import 'package:majora/user.dart';
import 'package:majora/wsclient.dart';

User kUser = new User();

final String kAppTitle = "Strims";
final String kLogoPath = "assets/favicon.ico";
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

Browser inAppBrowser = new Browser();
void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.grey[900],
        accentColor: Colors.orange[500],
      ),
      home: new ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController controller;
  List<Message> list = [];
  WSClient ws = new WSClient(kAddress, token: kUser.jwt);
  List<InlineSpan> output = [];
  List<Chatter> chatters = [];
  Future<Map<String, Emote>> emotes;

  void infoMsg(String msg) {
    Message m = new Message(
        type: "MSG",
        nick: "",
        data: <MessageSegment>[MessageSegment("text", msg)],
        timestamp: 0);
    setState(() => list.add(m));
  }

  void listen() {
    infoMsg("Connecting to chat.strims.gg ...");
    var channel = ws.dial();
    infoMsg("Connection established");
    ws.channel = channel;
    ws.channel.stream.listen((onData) {
      if (onData is String) {
        handleReceive(onData);
      }
    }, onError: (error) {
      print(error.toString());
    });
  }

  void updateToken() {
    ws.updateToken(kUser.jwt);
  }

  void resetChannel() {
    ws.channel.sink.close();

    kUser = inAppBrowser.getNewUser();

    updateToken();

    infoMsg("reconnecting...");
    listen();
  }

  Future<void> getAllEmotes() async {
    kEmotes = await getEmotes();
  }

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    getAllEmotes();
    listen();
  }

  Future _showDialog() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Whoops!"),
            content: new Text("You must first sign in to chat"),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Sign in"),
                onPressed: () async {
                  await inAppBrowser
                      .open(url: "https://strims.gg/login", options: {
                    "useShouldOverrideUrlLoading": true,
                  });
                },
              ),
              new FlatButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.pop(context);
                  this.resetChannel();
                },
              )
            ],
          );
        });
  }

  void sendData() {
    if (kUser.jwt == null) {
      _showDialog();
    }

    if (controller.text.isNotEmpty) {
      ws.channel.sink.add('MSG {"data":"' + controller.text + '"}');
      controller.text = "";
    }
  }

  void sendDataKeyboard(String data) {
    sendData();
  }

  void handleReceive(String msg) {
    String type = msg.split(new RegExp(r"{[^}]*}"))[0].trim();
    String data = msg.split(new RegExp(r"^[^ ]*"))[1];
    switch (type) {
      case "NAMES":
        chatters = buildChatterList(data);
        var count = getConnectionCount(data);
        chatters.forEach((f) {
          print(f.nick);
        });
        infoMsg(
            'Currently serving $count connections and ${chatters.length} users');
        break;
      case "MSG":
        Message m = new Message.fromJson(type, json.decode(data));
        setState(() => list.add(m));
        break;
      case "JOIN":
        //Chatter c = new Chatter.fromJson(json.decode(data));
        print("JOIN : " + data);
        break;
      case "QUIT":
        print("QUIT : " + data);
        break;
      default:
        print(type);
    }
    // if (msg == 'ERR "needlogin"') {
    //   infoMsg("ERROR: you must log in to chat");
    //   print(msg);
    //   return;
    // } else {
    //   String rec = msg.split(new RegExp(r"{[^}]*}"))[0];
    //   String content = msg.split(new RegExp(r"^[^ ]*"))[1];
    //   if (rec.trim() == "MSG" || rec.trim() == "PRIVMSG") {
    //     Message m = new Message.fromJson(rec.trim(), json.decode(content));

    //     setState(() => list.add(m));
    //   }
    // }
  }

  @override
  void dispose() {
    ws.channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String label;
    if (kUser.nick == null || kUser.nick.isEmpty) {
      label = "You need to be signed in to chat";
    } else {
      label = 'Write something ${kUser.nick} ...';
    }

    return Scaffold(
        appBar: kAppBar,
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
              ListTile(
                title: Text('Settings'),
                trailing: Icon(Icons.settings),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsRoute(),
                      ));
                },
              ),
              ListTile(
                title: Text('User list'),
                trailing: Icon(Icons.people),
                onTap: () {
                  Navigator.of(context).pop();
                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => ChatterListRoute(chatters),
                  //     ));
                },
              ),
              ListTile(
                title: Text('PMs'),
                trailing: Icon(Icons.mail),
              ),
              RaisedButton(
                onPressed: () {},
                child: Text('Logout'),
              )
            ],
          ),
        ),
        body: Column(children: <Widget>[
          Container(
            child: Form(
              child: new TextFormField(
                decoration: new InputDecoration(
                  labelText: label,
                  fillColor: Colors.grey[900],
                  filled: true,
                ),
                controller: controller,
                onFieldSubmitted: sendDataKeyboard,
              ),
            ),
          ),
          Expanded(
            child: ListView(children: <Widget>[MessageList(list)]),
          )
        ]));
  }
}

class SettingsRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Settings"),
        ),
        body: Column(children: <Widget>[]));
  }
}

class ChatterListRoute extends StatelessWidget {
  List<Chatter> _chatterList;

  ChatterListRoute(this._chatterList);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Chatters"),
        ),
        body: ListView(
          children: <Widget>[ChatterList(_chatterList)],
        ));
  }
}

class ChatterList extends StatelessWidget {
  final ScrollController _controller = ScrollController();
  final List<Chatter> _chatters;

  ChatterList(this._chatters);
  @override
  Widget build(BuildContext context) {

    return ListView.builder(
        shrinkWrap: true,
        controller: _controller,
        itemCount: _chatters.length,
        itemBuilder: (BuildContext ctx, int index) {
          print(_chatters[index].nick);
          return Card(
            color: Colors.grey[900],
            child: _ChatterListItem(_chatters[index]),
          );
        });
  }
}

class _ChatterListItem extends ListTile {
  _ChatterListItem(Chatter chtr)
      : super(dense: true, title: Text(chtr.nick), onTap: () {});
}
