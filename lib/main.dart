import 'dart:convert' as convert;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';

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

class Browser extends InAppBrowser {
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

Browser inAppBrowser = new Browser();
void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: new ChatPage(),
    );
  }
}

class WSClient {
  String address;
  String token;
  WebSocketChannel channel;

  WSClient(this.address, {this.token});

  WebSocketChannel dial() {
    print("opening channel");
    channel = IOWebSocketChannel.connect(this.address,
        headers:
            token?.isNotEmpty == true ? {'Cookie': 'jwt=${this.token}'} : {});
    return channel;
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
  WSClient ws = new WSClient(kAddress, token: kUser.jwt);
  List<InlineSpan> output = [];

  void listen() {
    var channel = ws.dial();
    ws.channel = channel;
    ws.channel.stream.listen((onData) {
      if (onData is String) {
        handleReceive(onData);
      }
    }, onError: (error) {
      print(error.toString());
    });
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

  void sendDataKeyboard(String data) {
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
              onFieldSubmitted: sendDataKeyboard,
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
          this.sendData();
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

Map<String, Emote> kEmotes = {
  "ComfyApe": new Emote(path: "/assets/ComfyApe.png", name: "ComfyApe"),
  "INFESTOR": new Emote(path: "/assets/INFESTOR.png", name: "INFESTOR"),
  "FIDGETLOL": new Emote(path: "/assets/FIDGETLOL.png", name: "FIDGETLOL"),
  "Hhhehhehe": new Emote(path: "/assets/Hhhehhehe.png", name: "Hhhehhehe"),
  "GameOfThrows": new Emote(path: "/assets/GameOfThrows.png", name: "GameOfThrows"),
  "Abathur": new Emote(path: "/assets/Abathur.png", name: "Abathur"),
  "LUL": new Emote(path: "/assets/LUL.png", name: "LUL"),
  "SURPRISE": new Emote(path: "/assets/SURPRISE.png", name: "SURPRISE"),
  "NoTears": new Emote(path: "/assets/NoTears.png", name: "NoTears"),
  "OverRustle": new Emote(path: "/assets/OverRustle.png", name: "OverRustle"),
  "DuckerZ": new Emote(path: "/assets/DuckerZ.png", name: "DuckerZ"),
  "Kappa": new Emote(path: "/assets/Kappa.png", name: "Kappa"),
  "Klappa": new Emote(path: "/assets/Klappa.png", name: "Klappa"),
  "DappaKappa": new Emote(path: "/assets/DappaKappa.png", name: "DappaKappa"),
  "BibleThump": new Emote(path: "/assets/BibleThump.png", name: "BibleThump"),
  "AngelThump": new Emote(path: "/assets/AngelThump.png", name: "AngelThump"),
  "BasedGod": new Emote(path: "/assets/BasedGod.png", name: "BasedGod"),
  "OhKrappa": new Emote(path: "/assets/OhKrappa.png", name: "OhKrappa"),
  "SoDoge": new Emote(path: "/assets/SoDoge.png", name: "SoDoge"),
  "WhoahDude": new Emote(path: "/assets/WhoahDude.png", name: "WhoahDude"),
  "MotherFuckinGame": new Emote(path: "/assets/MotherFuckinGame.png", name: "MotherFuckinGame"),
  "DaFeels": new Emote(path: "/assets/DaFeels.png", name: "DaFeels"),
  "UWOTM8": new Emote(path: "/assets/UWOTM8.png", name: "UWOTM8"),
  "DatGeoff": new Emote(path: "/assets/DatGeoff.png", name: "DatGeoff"),
  "FerretLOL": new Emote(path: "/assets/FerretLOL.png", name: "FerretLOL"),
  "Sippy": new Emote(path: "/assets/Sippy.png", name: "Sippy"),
  "Nappa": new Emote(path: "/assets/Nappa.png", name: "Nappa"),
  "DAFUK": new Emote(path: "/assets/DAFUK.png", name: "DAFUK"),
  "HEADSHOT": new Emote(path: "/assets/HEADSHOT.png", name: "HEADSHOT"),
  "DANKMEMES": new Emote(path: "/assets/DANKMEMES.png", name: "DANKMEMES"),
  "MLADY": new Emote(path: "/assets/MLADY.png", name: "MLADY"),
  "MASTERB8": new Emote(path: "/assets/MASTERB8.png", name: "MASTERB8"),
  "NOTMYTEMPO": new Emote(path: "/assets/NOTMYTEMPO.png", name: "NOTMYTEMPO"),
  "LeRuse": new Emote(path: "/assets/LeRuse.png", name: "LeRuse"),
  "YEE": new Emote(path: "/assets/YEE.png", name: "YEE"),
  "SWEATY": new Emote(path: "/assets/SWEATY.png", name: "SWEATY"),
  "PEPE": new Emote(path: "/assets/PEPE.png", name: "PEPE"),
  "SpookerZ": new Emote(path: "/assets/SpookerZ.png", name: "SpookerZ"),
  "WEEWOO": new Emote(path: "/assets/WEEWOO.png", name: "WEEWOO"),
  "ASLAN": new Emote(path: "/assets/ASLAN.png", name: "ASLAN"),
  "TRUMPED": new Emote(path: "/assets/TRUMPED.png", name: "TRUMPED"),
  "BASEDWATM8": new Emote(path: "/assets/BASEDWATM8.png", name: "BASEDWATM8"),
  "BERN": new Emote(path: "/assets/BERN.png", name: "BERN"),
  "Hmmm": new Emote(path: "/assets/Hmmm.png", name: "Hmmm"),
  "PepoThink": new Emote(path: "/assets/PepoThink.png", name: "PepoThink"),
  "FeelsAmazingMan": new Emote(path: "/assets/FeelsAmazingMan.png", name: "FeelsAmazingMan"),
  "FeelsBadMan": new Emote(path: "/assets/FeelsBadMan.png", name: "FeelsBadMan"),
  "FeelsGoodMan": new Emote(path: "/assets/FeelsGoodMan.png", name: "FeelsGoodMan"),
  "OhMyDog": new Emote(path: "/assets/OhMyDog.png", name: "OhMyDog"),
  "Wowee": new Emote(path: "/assets/Wowee.png", name: "Wowee"),
  "haHAA": new Emote(path: "/assets/haHAA.png", name: "haHAA"),
  "POTATO": new Emote(path: "/assets/POTATO.png", name: "POTATO"),
  "NOBULLY": new Emote(path: "/assets/NOBULLY.png", name: "NOBULLY"),
  "gachiGASM": new Emote(path: "/assets/gachiGASM.png", name: "gachiGASM"),
  "REE": new Emote(path: "/assets/REE.png", name: "REE"),
  "monkaS": new Emote(path: "/assets/monkaS.png", name: "monkaS"),
  "RaveDoge": new Emote(path: "/assets/RaveDoge.png", name: "RaveDoge"),
  "CuckCrab": new Emote(path: "/assets/CuckCrab.png", name: "CuckCrab"),
  "MiyanoHype": new Emote(path: "/assets/MiyanoHype.png", name: "MiyanoHype"),
  "ECH": new Emote(path: "/assets/ECH.png", name: "ECH"),
  "NiceMeMe": new Emote(path: "/assets/NiceMeMe.png", name: "NiceMeMe"),
  "ITSRAWWW": new Emote(path: "/assets/ITSRAWWW.png", name: "ITSRAWWW"),
  "Riperino": new Emote(path: "/assets/Riperino.png", name: "Riperino"),
  "4Head": new Emote(path: "/assets/4Head.png", name: "4Head"),
  "BabyRage": new Emote(path: "/assets/BabyRage.png", name: "BabyRage"),
  "EleGiggle": new Emote(path: "/assets/EleGiggle.png", name: "EleGiggle"),
  "Kreygasm": new Emote(path: "/assets/Kreygasm.png", name: "Kreygasm"),
  "PogChamp": new Emote(path: "/assets/PogChamp.png", name: "PogChamp"),
  "SMOrc": new Emote(path: "/assets/SMOrc.png", name: "SMOrc"),
  "NotLikeThis": new Emote(path: "/assets/NotLikeThis.png", name: "NotLikeThis"),
  "POGGERS": new Emote(path: "/assets/POGGERS.png", name: "POGGERS"),
  "AYAYA": new Emote(path: "/assets/AYAYA.png", name: "AYAYA"),
  "PepOk": new Emote(path: "/assets/PepOk.png", name: "PepOk"),
  "PepoComfy": new Emote(path: "/assets/PepoComfy.png", name: "PepoComfy"),
  "PepoWant": new Emote(path: "/assets/PepoWant.png", name: "PepoWant"),
  "PepeHands": new Emote(path: "/assets/PepeHands.png", name: "PepeHands"),
  "BOGGED": new Emote(path: "/assets/BOGGED.png", name: "BOGGED"),
  "ComfyApe": new Emote(path: "/assets/ComfyApe.png", name: "ComfyApe"),
  "ApeHands": new Emote(path: "/assets/ApeHands.png", name: "ApeHands"),
  "OMEGALUL": new Emote(path: "/assets/OMEGALUL.png", name: "OMEGALUL"),
  "COGGERS": new Emote(path: "/assets/COGGERS.png", name: "COGGERS"),
  "PepoWant": new Emote(path: "/assets/PepoWant.png", name: "PepoWant"),
  "Clap": new Emote(path: "/assets/Clap.png", name: "Clap"),
  "FeelsWeirdMan": new Emote(path: "/assets/FeelsWeirdMan.png", name: "FeelsWeirdMan"),
  "monkaMEGA": new Emote(path: "/assets/monkaMEGA.png", name: "monkaMEGA"),
  "ComfyDog": new Emote(path: "/assets/ComfyDog.png", name: "ComfyDog"),
  "GIMI": new Emote(path: "/assets/GIMI.png", name: "GIMI"),
  "MOOBERS": new Emote(path: "/assets/MOOBERS.png", name: "MOOBERS"),
  "PepoBan": new Emote(path: "/assets/PepoBan.png", name: "PepoBan"),
  "ComfyAYA": new Emote(path: "/assets/ComfyAYA.png", name: "ComfyAYA"),
  "ComfyFerret": new Emote(path: "/assets/ComfyFerret.png", name: "ComfyFerret"),
  "BOOMER": new Emote(path: "/assets/BOOMER.png", name: "BOOMER"),
  "ZOOMER": new Emote(path: "/assets/ZOOMER.png", name: "ZOOMER"),
  "SOY": new Emote(path: "/assets/SOY.png", name: "SOY"),
  "FeelsPepoMan": new Emote(path: "/assets/FeelsPepoMan.png", name: "FeelsPepoMan"),
  "ComfyCat": new Emote(path: "/assets/ComfyCat.png", name: "ComfyCat"),
  "ComfyPOTATO": new Emote(path: "/assets/ComfyPOTATO.png", name: "ComfyPOTATO"),
  "SUGOI": new Emote(path: "/assets/SUGOI.png", name: "SUGOI"),
  "DJPepo": new Emote(path: "/assets/DJPepo.png", name: "DJPepo"),
  "CampFire": new Emote(path: "/assets/CampFire.png", name: "CampFire"),
  "ComfyYEE": new Emote(path: "/assets/ComfyYEE.png", name: "ComfyYEE"),
  "weSmart": new Emote(path: "/assets/weSmart.png", name: "weSmart"),
  "PepoG": new Emote(path: "/assets/PepoG.png", name: "PepoG"),
  "OBJECTION": new Emote(path: "/assets/OBJECTION.png", name: "OBJECTION"),
  "ComfyWeird": new Emote(path: "/assets/ComfyWeird.png", name: "ComfyWeird"),
  "umaruCry": new Emote(path: "/assets/umaruCry.png", name: "umaruCry"),
  "OsKrappa": new Emote(path: "/assets/OsKrappa.png", name: "OsKrappa"),
  "monkaHmm": new Emote(path: "/assets/monkaHmm.png", name: "monkaHmm"),
  "PepoHmm": new Emote(path: "/assets/PepoHmm.png", name: "PepoHmm"),
  "PepeComfy": new Emote(path: "/assets/PepeComfy.png", name: "PepeComfy"),
  "SUGOwO": new Emote(path: "/assets/SUGOwO.png", name: "SUGOwO"),
  "EZ": new Emote(path: "/assets/EZ.png", name: "EZ"),
  "Pepega": new Emote(path: "/assets/Pepega.png", name: "Pepega"),
  "shyLurk": new Emote(path: "/assets/shyLurk.png", name: "shyLurk"),
  "FeelsOkayMan": new Emote(path: "/assets/FeelsOkayMan.png", name: "FeelsOkayMan"),
  "POKE": new Emote(path: "/assets/POKE.png", name: "POKE"),
  "PepoDance": new Emote(path: "/assets/PepoDance.png", name: "PepoDance"),
  "ORDAH": new Emote(path: "/assets/ORDAH.png", name: "ORDAH"),
  "SPY": new Emote(path: "/assets/SPY.png", name: "SPY"),
  "PepoGood": new Emote(path: "/assets/PepoGood.png", name: "PepoGood"),
  "PepeJam": new Emote(path: "/assets/PepeJam.png", name: "PepeJam"),
  "LAG": new Emote(path: "/assets/LAG.png", name: "LAG"),
  "SOTRIGGERED": new Emote(path: "/assets/SOTRIGGERED.png", name: "SOTRIGGERED"),
  "OnlyPretending": new Emote(path: "/assets/OnlyPretending.png", name: "OnlyPretending"),
  "cmonBruh": new Emote(path: "/assets/cmonBruh.png", name: "cmonBruh"),
  "VroomVroom": new Emote(path: "/assets/VroomVroom.png", name: "VroomVroom"),
  "loliDance": new Emote(path: "/assets/loliDance.png", name: "loliDance"),
  "WAG": new Emote(path: "/assets/WAG.png", name: "WAG"),
  "PepoFight": new Emote(path: "/assets/PepoFight.png", name: "PepoFight"),
  "NeneLaugh": new Emote(path: "/assets/NeneLaugh.png", name: "NeneLaugh"),
  "PepeLaugh": new Emote(path: "/assets/PepeLaugh.png", name: "PepeLaugh"),
  "PeepoS": new Emote(path: "/assets/PeepoS.png", name: "PeepoS"),
  "SLEEPY": new Emote(path: "/assets/SLEEPY.png", name: "SLEEPY"),
  "GODMAN": new Emote(path: "/assets/GODMAN.png", name: "GODMAN"),
  "NOM": new Emote(path: "/assets/NOM.png", name: "NOM"),
  "FeelsDumbMan": new Emote(path: "/assets/FeelsDumbMan.png", name: "FeelsDumbMan"),
  "HONK": new Emote(path: "/assets/HONK.png", name: "HONK"),
  "SEMPAI": new Emote(path: "/assets/SEMPAI.png", name: "SEMPAI"),
  "OSTRIGGERED": new Emote(path: "/assets/OSTRIGGERED.png", name: "OSTRIGGERED"),
  "MiyanoBird": new Emote(path: "/assets/MiyanoBird.png", name: "MiyanoBird"),
  "KING": new Emote(path: "/assets/KING.png", name: "KING"),
  "PIKOHH": new Emote(path: "/assets/PIKOHH.png", name: "PIKOHH"),
  "PepoPirate": new Emote(path: "/assets/PepoPirate.png", name: "PepoPirate"),
  "PepeMods": new Emote(path: "/assets/PepeMods.png", name: "PepeMods"),
  "OhISee": new Emote(path: "/assets/OhISee.png", name: "OhISee"),
  "WeirdChamp": new Emote(path: "/assets/WeirdChamp.png", name: "WeirdChamp"),
  "RedCard": new Emote(path: "/assets/RedCard.png", name: "RedCard"),
  "illyaTriggered": new Emote(path: "/assets/illyaTriggered.png", name: "illyaTriggered"),
  "SadBenis": new Emote(path: "/assets/SadBenis.png", name: "SadBenis"),
  "PeepoHappy": new Emote(path: "/assets/PeepoHappy.png", name: "PeepoHappy"),
  "ComfyWAG": new Emote(path: "/assets/ComfyWAG.png", name: "ComfyWAG"),
  "MiyanoComfy": new Emote(path: "/assets/MiyanoComfy.png", name: "MiyanoComfy"),
  "sataniaLUL": new Emote(path: "/assets/sataniaLUL.png", name: "sataniaLUL"),
  "DELUSIONAL": new Emote(path: "/assets/DELUSIONAL.png", name: "DELUSIONAL"),
};