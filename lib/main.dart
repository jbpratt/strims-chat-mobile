import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:majora/browser.dart';
import 'package:majora/emotes.dart';
import 'package:majora/messages.dart';
import 'package:majora/user.dart';
import 'package:majora/wsclient.dart';

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
    print("channel dialed");
    infoMsg("Connection established");
    infoMsg("Currently serving 141 connections and 68 users");
    ws.channel = channel;
    print("listening...");
    ws.channel.stream.listen((onData) {
      if (onData is String) {
        handleReceive(onData);
      }
    }, onError: (error) {
      print(error.toString());
    });
    print("leaving listen()");
  }

  void updateToken() {
    ws.updateToken(kUser.jwt);
  }

  void resetChannel() {
    print("closing channel");
    ws.channel.sink.close();
    print("channel closed");

    kUser = inAppBrowser.getNewUser();

    print("updating token");
    updateToken();
    print("updated token");

    infoMsg("reconnecting...");
    listen();
  }
  // void _loadEmotes(http.Response resp) async {
  //   var emoteResp = await http.get("https://strims.gg/api/profile");
  //   if (emoteResp.statusCode == 200) {
  //     var jsonResponse = convert.jsonDecode(emoteResp.body);
  //     var emoteList = jsonResponse['default'];
  //     for (var emote in emoteList) {
  //       kEmotes[emote] =
  //           new Emote(name: emote, path: "/assets/" + emote + ".png");
  //     }
  //   } else {
  //     print("Emote request failed with status: ${emoteResp.statusCode}.");
  //   }
  // }

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    emotes = getEmotes().then((onValue) {
      print(emotes);
    });
    print("emotes requested");
    listen();
    print("leaving initState()");
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
    if (msg == 'ERR "needlogin"') {
      infoMsg("ERROR: you must log in to chat");
      print(msg);
      return;
    } else {
      String rec = msg.split(new RegExp(r"{[^}]*}"))[0];
      String content = msg.split(new RegExp(r"^[^ ]*"))[1];
      if (rec.trim() == "MSG" || rec.trim() == "PRIVMSG") {
        Message m =
            new Message.fromJson(rec.trim(), convert.json.decode(content));

        setState(() => list.add(m));
      }
    }
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