import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:majora/storage.dart';
import 'package:majora/wsclient.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'browser.dart';
import 'chatter.dart';
import 'emotes.dart';
import 'messages.dart';

final String kAppTitle = "Strims";
final String kLogoPath = "assets/favicon.ico";
final String kAddress = "wss://chat.strims.gg/ws";

Browser inAppBrowser = new Browser();
String jwt, nick = "";

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController controller;
  List<Message> list = [];
  WSClient ws = new WSClient(kAddress, token: jwt);
  List<InlineSpan> output = [];
  List<Chatter> chatters = [];
  Future<Map<String, Emote>> emotes;
  Storage storage = new Storage();

  void infoMsg(String msg) {
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    Message m = Message.fromJson(
        "MSG",
        json.decode(
            '{"nick":"info","features":[],"timestamp":$timestamp,"data":"$msg"}'));

    setState(() => list.add(m));
  }

  Future<String> _getUsername(String jwt) async {
    var header = new Map<String, String>();
    header['Cookie'] = 'jwt=$jwt';
    Response response =
        await get("https://strims.gg/api/profile", headers: header);
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return jsonResponse['username'].toString();
    } else {
      print("Request failed with status: ${response.statusCode}.");
    }
  }

  void listen() {
    infoMsg("Connecting to chat.strims.gg ...");
    WebSocketChannel channel = ws.dial();
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

  void login() async {
    await inAppBrowser.open(url: "https://strims.gg/login", options: {
      "useShouldOverrideUrlLoading": true,
    }).then((val) {
      inAppBrowser.onLoadStop("https://strims.gg/").then((onValue) {
        inAppBrowser.getCookie("jwt").then((map) {
          String tmp = map['value'];
          if (tmp != null && tmp.length > 0) {
            jwt = tmp;
            storage.addSetting('jwt', jwt);
            _getAndSaveUsername();
          }
        });
      });
    });
  }

  void updateToken() {
    ws.updateToken(jwt);
  }

  void resetChannel() {
    ws.channel.sink.close();
    infoMsg("reconnecting...");
    listen();
  }

  void resetOnBrowserClose() {
    //kUser = inAppBrowser.getNewUser();

    updateToken();
    resetChannel();
  }

  Future<void> getAllEmotes() async {
    kEmotes = await getEmotes();
  }

  void _getAndSaveUsername() async {
    nick = await _getUsername(jwt);
    storage.addSetting('nick', nick);
  }

  @override
  void initState() {
    super.initState();
    this.storage.initS().then((val) {
      infoMsg("checking storage for user");
      if (this.storage.hasSetting('jwt')) {
        infoMsg("found user in storage");
        jwt = this.storage.getSetting('jwt');
        nick = this.storage.getSetting('nick');
      }
    }).then((val) {
      updateToken();
      listen();
    });

    controller = TextEditingController();
    getAllEmotes();
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
                  login();
                },
              ),
              new FlatButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.pop(context);
                  this.resetOnBrowserClose();
                },
              )
            ],
          );
        });
  }

  void sendData() {
    if (jwt == null || jwt == "") {
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
    print(data);
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
    if (nick == null || nick.isEmpty) {
      return "You need to be signed in to chat";
    } else {
      return 'Write something $nick ...';
    }
  }

  @override
  Widget build(BuildContext context) {
    String label = determineLabel();

    return Scaffold(
        appBar: new AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                kLogoPath,
                fit: BoxFit.contain,
                height: 24,
              ),
              Container(
                  padding: const EdgeInsets.all(8.0), child: Text('Strims'))
            ],
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                login();
              },
            ),
          ],
        ),
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
                  nick = "";
                  jwt = "";

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
