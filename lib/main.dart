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
  actions: <Widget>[
    IconButton(
        icon: Icon(Icons.person),
        onPressed: () async {
          await inAppBrowser.open(url: "https://strims.gg/login", options: {
            "useShouldOverrideUrlLoading": true,
          });
        }),
  ],
);

Browser inAppBrowser = new Browser();
void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.grey[999],
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

  Future _showLoginDialog() async {
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
    if (kUser.jwt == null || kUser.jwt == "") {
      _showLoginDialog();
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
        setState(() {
          chatters.addAll(buildChatterList(data));
        });
        var count = getConnectionCount(data);
        infoMsg(
            'Currently serving $count connections and ${chatters.length} users');
        break;
      case "MSG":
        Message m = new Message.fromJson(type, json.decode(data));
        setState(() => list.add(m));
        break;
      case "PRIVMSG":
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
    }
  }

  @override
  void dispose() {
    ws.channel.sink.close();
    super.dispose();
  }

  String determineLabel() {
    if (kUser.nick == null || kUser.nick.isEmpty) {
      return "You need to be signed in to chat";
    } else {
      return 'Write something ${kUser.nick} ...';
    }
  }

  @override
  Widget build(BuildContext context) {
    String label = determineLabel();

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
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatterListRoute(chatters),
                      ));
                },
              ),
              ListTile(
                title: Text('PMs'),
                trailing: Icon(Icons.mail),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WhispersRoute(),
                      ));
                },
              ),
              RaisedButton(
                onPressed: () {
                  kUser.nick = "";
                  kUser.jwt = "";
                  kUser = null;

                  resetChannel();
                  // reset conn
                  Navigator.of(context).pop();
                  setState(() {
                    label = determineLabel();
                  });
                },
                child: Text('Logout'),
              )
            ],
          ),
        ),
        backgroundColor: Colors.black,
        body: Column(children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(
              vertical: 5.0,
              horizontal: 5.0,
            ),
            color: Colors.grey[900],
            child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Form(
                      child: new Flexible(
                    child: new TextFormField(
                      decoration: new InputDecoration(
                        labelText: label,
                        fillColor: Colors.black,
                        filled: true,
                      ),
                      controller: controller,
                      onFieldSubmitted: sendDataKeyboard,
                    ),
                  )),
                  ButtonTheme(
                    minWidth: 20.0,
                    buttonColor: Colors.transparent,
                    child: RaisedButton(
                      onPressed: () {},
                      child: Icon(Icons.mood),
                    ),
                  ),
                ]),
          ),
          Expanded(
            child: ListView(children: <Widget>[MessageList(list)]),
          )
        ]));
  }
}

class WhispersRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Whispers"),
        ),
        body: Column(children: <Widget>[]));
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
  final List<Chatter> _chatterList;

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
