import 'dart:convert' as convert;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';

class MyInAppBrowser extends InAppBrowser {
  List<Cookie> cookies;
  @override
  void onBrowserCreated() async {
    print("\n\nBrowser Ready!\n\n");
  }

  @override
  onLoadStart(String url) async {}

  @override
  Future onLoadStop(String url) async {
    var x = (await CookieManager.getCookie("https://chat.strims.gg", "jwt"));
    kUser.jwt = x['value'];
    print(kUser.jwt);
  }

  @override
  void onLoadError(String url, int code, String message) {
    print("\n\nCan't load $url.. Error: $message\n\n");
  }

  @override
  Future onExit() async {
    var header = new Map<String, String>();
    header['Cookie'] = 'jwt=${kUser.jwt}';
    var response =
        await http.get("https://strims.gg/api/profile", headers: header);
    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body);
      kUser.nick = jsonResponse['username'];
    } else {
      print("Request failed with status: ${response.statusCode}.");
    }
    print("\n\nBrowser closed!\n\n");
  }

  @override
  void shouldOverrideUrlLoading(String url) {
    this.webViewController.loadUrl(url);
  }

  @override
  void onLoadResource(
      WebResourceResponse response, WebResourceRequest request) {}

  @override
  void onConsoleMessage(ConsoleMessage consoleMessage) {}
}

MyInAppBrowser inAppBrowser = new MyInAppBrowser();
void main() => runApp(App());

User kUser = new User();
Map<String, Emote> kEmotes = {
  "4Head": new Emote(path: "/assets/4Head.png", name: "4Head"),
  "ComfyApe": new Emote(path: "/assets/ComfyApe.png", name: "ComfyApe")
};
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
      home: new ChatPage(),
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
  List<InlineSpan> output = [];

  //List<Widget> output;

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
    String jwt = kUser.jwt;
    channel = IOWebSocketChannel.connect(kAddress,
        headers: jwt?.isNotEmpty == true ? {'Cookie': 'jwt=$jwt'} : {});
    controller = TextEditingController();

    channel.stream.listen((onData) {
      if (onData is String) {
        handleReceive(onData);
      }
    }, onError: (error) {
      print(error.toString());
    });
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
                  setState(() {});
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
      channel.sink.add('MSG {"data":"' + controller.text + '"}');
      controller.text = "";
    }
  }

  void handleReceive(String msg) {
    if (msg == 'ERR "needlogin"') {
      print(msg);
      return;
    } else {
      String rec = msg.split(new RegExp(r"{[^}]*}"))[0];
      String content = msg.split(new RegExp(r"^[^ ]*"))[1];
      if (rec.trim() == "MSG" || rec.trim() == "PRIVMSG") {
        Message m =
            new Message.fromJson(rec.trim(), convert.json.decode(content));
        // var x = m.data.split(" ");
        // for (int i = 0; i < x.length; i++) {
        //   print(x[i]);
        //   // use TextSpan maybe
        //   //output.add(Text(x[i]));
        // }
        setState(() => list.add(m));
      }
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
            ),
          ),
        ),
        Expanded(
          child: ListView(children: <Widget>[MessageList(list)]),
        )
      ]),
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
            title: Text(msg.data.toString(),
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
  List<MessageSegment> data;

  Message({this.type, this.nick, this.timestamp, this.data});

  String readTimestamp() {
    DateTime d =
        new DateTime.fromMillisecondsSinceEpoch(this.timestamp, isUtc: true);
    return d.hour.toString() + ":" + d.minute.toString();
  }

  factory Message.fromJson(String type, Map parsedJson) {
    List<MessageSegment> _tokenizeMsg(String data) {
      List<MessageSegment> tmpData = [];
      String tmpBuffer = "";
      if (data == null) {
        return tmpData;
      }

      for (String segment in data.split(" ")) {
        if (kEmotes.containsKey(segment)) {
          tmpData.add(new MessageSegment("text", tmpBuffer + " "));
          tmpBuffer = "";
          tmpData.add(new MessageSegment("emote", segment));
        } else {
          tmpBuffer += " " + segment;
        }
      }

      if (tmpBuffer != "") {
        tmpData.add(new MessageSegment("text", tmpBuffer + " "));
      }

      return tmpData;
    }

    List<MessageSegment> message = _tokenizeMsg(parsedJson['data']);
    print(parsedJson['data']);
    return Message(
        type: type,
        nick: parsedJson['nick'],
        timestamp: parsedJson['timestamp'],
        data: message);
  }
}

class MessageSegment {
  String type;
  String data;

  @override
  String toString() {
    return "{ type: \"" + type + "\", data: \"" + data + "\" }";
  }

  MessageSegment(this.type, this.data);
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
