import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'settings.dart';
import 'storage.dart';
import 'wsclient.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'browser.dart';
import 'chatter.dart';
import 'emotes.dart';
import 'messages.dart';
import 'utilities.dart';

final String kAppTitle = "Strims";
final String kLogoPath = "assets/favicon.ico";
final String kAddress = "wss://chat.strims.gg/ws";

Browser inAppBrowser = new Browser();
String jwt = "";
String nick = "Anonymous";

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingControllerWorkaroud controller = TextEditingControllerWorkaroud();
  List<Message> messages = [];
  WSClient ws = new WSClient(kAddress, token: jwt);
  List<InlineSpan> output = [];
  List<Chatter> chatters = [];
  List<String> autoCompleteSuggestions = [];
  ScrollController autoCompleteScrollController;
  Future<Map<String, Emote>> emotes;
  Storage storage = new Storage();
  String label;
  Settings settings;
  SettingsNotifier settingsNotifier;

  // add message , check if message & last in list is same emote
  // if combo, adds combo message // else just adds message
  void addMessage(Message message) {
    if (isNotCombo(message)) {
      if (messages.isNotEmpty) {
        if (messages.length > settings.maxMessages) {
          messages.removeRange(
              (messages.length - settings.batchDeleteAmount < 0)
                  ? 0
                  : messages.length - settings.batchDeleteAmount,
              messages.length);
        }
      }
      if (messages.isNotEmpty) {
        messages.last.comboActive = false;
      }
      messages.add(message);

      return;
    }
    if (messages.last.messageData == message.messageData) {
      messages.last.comboCount = messages.last.comboCount + 1;
      if (messages.last.comboUsers == null) {
        messages.last.comboUsers = new List<String>();
        messages.last.comboUsers.add(messages.last.nick);
        messages.last.nick = "comboMessage";
      }
      messages.last.comboUsers.add(message.nick);
      messages.last.comboActive = true;
    }
  }

  void infoMsg(String msg) {
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    Message m = Message.fromJson(
        "MSG",
        json.decode(
            '{"nick":"info","features":[],"timestamp":$timestamp,"data":"$msg"}'),
        this.settings,
        nick);

    setState(() => addMessage(m));
  }

  bool isNotCombo(Message message) {
    if (messages.isEmpty ||
        !message.isOnlyEmote() ||
        messages.last.messageData != message.messageData) {
      return true;
    }
    return false;
  }

  Message comboMessage(String emote, int combo) {
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    Message m = Message.fromJson(
        "MSG",
        json.decode(
            '{"nick":"$combo X C-C-C-COMBO","features":[],"timestamp":$timestamp,"data":"$emote"}'),
        this.settings,
        nick);
    m.comboCount = combo;
    return m;
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
      return null;
    }
  }

  Future<void> _requestChatHistory() async {
    // TODO: add useragent
    //var header = new Map<String, String>();
    Response response = await get("https://chat.strims.gg/api/chat/history");
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body) as List;
      jsonResponse.forEach((i) => handleReceive(i.toString()));
    } else {
      print("Request failed with status: ${response.statusCode}.");
      return null;
    }
  }

  void listen() {
    _requestChatHistory().then((onValue) {
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
    });
  }

  void login() async {
    // if already logged in then open profile
    await inAppBrowser.open(url: "https://strims.gg/login", options: {
      "useShouldOverrideUrlLoading": true,
    }).then((val) {
      inAppBrowser.onLoadStop("https://strims.gg/").then((onValue) {
        inAppBrowser.getCookie("jwt").then((map) {
          String tmp = map['value'];
          if (tmp != null && tmp.length > 0) {
            jwt = tmp;
            updateToken();
            storage.addSetting('jwt', jwt);
            _getAndSaveUsername();
          }
        });
      });
    }).then((onValue) {
      resetChannel();
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

  void resetOnPopupClose() {
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
        setState(() {
          jwt = this.storage.getSetting('jwt');
          nick = this.storage.getSetting('nick');
          label = determineLabel();
        });
      }
    }).then((val) {
      updateToken();
      listen();
    });

    controller.addListener(_updateAutocompleteSuggestions);
    getAllEmotes();
    autoCompleteScrollController = new ScrollController();
  }

  Future _showLoginDialog() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          if (nick != "Anonymous" && jwt.isNotEmpty) {
            // TODO: remove the popup somehow
          }
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
                  this.resetOnPopupClose();
                },
              )
            ],
          );
        });
  }

  void handleTagHighlightIgnore(String input) {
    List colors = [
      "green",
      "yellow",
      "orange",
      "red",
      "purple",
      "blue",
      "sky",
      "lime",
      "pink",
      "black"
    ];
    //TODO: regex this
    // prepare yourself for spaghetti
    String inputNoWhitespace = input;
    bool test = true;
    while (test) {
      if (inputNoWhitespace.contains("  ")) {
        inputNoWhitespace = inputNoWhitespace.replaceAll("  ", " ");
      } else {
        test = false;
      }
    }
    List output = inputNoWhitespace.split(" ");
    switch (output[0].toString().replaceAll("/", "")) {
      case "highlight":
        if (output.length == 1 || output[1].isEmpty) {
          infoMsg(settings.wordsHighlighted.length < 1
              ? "No highlighted words, syntax : \/highlight {word}"
              : "Highlighted words : " +
                  settings.wordsHighlighted
                      .toString()
                      .replaceAll("{", "")
                      .replaceAll("}", ""));
        } else if (output.length >= 2) {
          infoMsg("Highlighting " + output[1]);
          this.settingsNotifier.addWordsHighlighted(output[1]);
        }
        break;
      case "unhighlight":
        if (output.length == 1 || output[1].isEmpty) {
          infoMsg(settings.wordsHighlighted.length < 1
              ? "No highlighted words, syntax : \/unhighlight {word}"
              : "Highlighted words : " +
                  settings.wordsHighlighted
                      .toString()
                      .replaceAll("{", "")
                      .replaceAll("}", ""));
        } else if (output.length >= 2) {
          infoMsg("No longer highlighting " + output[1]);
          this.settingsNotifier.removeWordsHighlighted(output[1]);
        }
        break;
      case "tag":
        if (output.length == 1 || output[1].isEmpty) {
          infoMsg(settings.userTags.length < 1
              ? "No tagged users, syntax : \/tag {user} {color}" +
                  ". Available colors: " +
                  colors.toString().replaceAll("[", "").replaceAll("]", "")
              : "Highlighted users : " +
                  settings.userTags
                      .toString()
                      .replaceAll("{", "")
                      .replaceAll("}", "") +
                  ". Available colors: " +
                  colors.toString().replaceAll("[", "").replaceAll("]", ""));
        } else if (output.length == 2 || output[2].isEmpty) {
          var color = colors[Random().nextInt(colors.length - 1)];
          infoMsg("Tagged " + output[1] + " as " + color);
          this.settingsNotifier.addUserTags(output[1], color);
        } else if (output.length >= 3) {
          String color = "";
          if (!colors.contains(output[2].toLowerCase())) {
            color = colors[Random().nextInt(colors.length - 1)];
          } else {
            color = output[2].toLowerCase();
          }
          infoMsg("Tagged " + output[1] + " as " + color);
          this.settingsNotifier.addUserTags(output[1], color);
        }
        break;
      case "untag":
        if (output.length == 1 || output[1].isEmpty) {
          infoMsg(settings.userTags.length < 1
              ? "No tagged users, syntax : \/untag {user} {color}" +
                  ". Available colors: " +
                  colors.toString().replaceAll("[", "").replaceAll("]", "")
              : "Highlighted users : " +
                  settings.userTags
                      .toString()
                      .replaceAll("{", "")
                      .replaceAll("}", "") +
                  ". Available colors: " +
                  colors.toString().replaceAll("[", "").replaceAll("]", ""));
        } else if (output.length >= 2) {
          infoMsg("Un-tagged " + output[1]);
          this.settingsNotifier.removeUserTags(output[1]);
        }
        break;
      case "ignore":
        if (output.length == 1 || output[1].isEmpty) {
          infoMsg(settings.usersIgnored.length < 1
              ? "Your ignore list is empty, syntax : \/ignore {user}"
              : "Ignored Users : " +
                  settings.usersIgnored
                      .toString()
                      .replaceAll("{", "")
                      .replaceAll("}", ""));
        } else if (output.length >= 2) {
          infoMsg("Ignoring " + output[1]);
          this.settingsNotifier.addUsersIgnored(output[1]);
        }
        break;
      case "unignore":
        if (output.length == 1 || output[1].isEmpty) {
          infoMsg(settings.usersIgnored.length < 1
              ? "Your ignore list is empty, syntax : \/unignore {user}"
              : "Ignored Users : " +
                  settings.usersIgnored
                      .toString()
                      .replaceAll("{", "")
                      .replaceAll("}", ""));
        } else if (output.length >= 2) {
          infoMsg(output[1] + " has been removed from your ignore list");
          this.settingsNotifier.removeUsersIgnored(output[1]);
        }
        break;
      case "hide":
        if (output.length == 1 || output[1].isEmpty) {
          infoMsg(settings.wordsHidden.length < 1
              ? "You have no hidden words : \/hide {word}"
              : "Hidden words : " +
                  settings.wordsHidden
                      .toString()
                      .replaceAll("{", "")
                      .replaceAll("}", ""));
        } else if (output.length >= 2) {
          infoMsg("Hiding messages including " + output[1]);
          this.settingsNotifier.addWordsHidden(output[1]);
        }
        break;
      case "unhide":
        if (output.length == 1 || output[1].isEmpty) {
          infoMsg(settings.wordsHidden.length < 1
              ? "You have no hidden words : \/unhide {word}"
              : "Hidden words : " +
                  settings.wordsHidden
                      .toString()
                      .replaceAll("{", "")
                      .replaceAll("}", ""));
        } else if (output.length >= 2) {
          infoMsg("No longer hiding messages including " + output[1]);
          this.settingsNotifier.removeWordsHidden(output[1]);
        }
        break;
      default:
        infoMsg("please try re-typing your command");
        break;
    }
  }

  void sendData() {
    if (jwt == null || jwt == "") {
      _showLoginDialog();
    }

    if (controller.text.isNotEmpty) {
      var text = controller.text;
      // if first two chars are '/w' or '/msg' or '/message' or '/tell' or '/notify' or '/t'  or '/whisper' // <- all pms
      // if user is auth as moderator // '/ban' or '/mute'

      if (text[0] == '/') {
        // TODO: trim left for function check ?
        //TODO: lowercase functions ?

        // TODO: handle all "/" functions
        if (text.contains(new RegExp(
            r"^\/((highlight)|(unhighlight)|(tag)|(untag)|(ignore)|(unignore)|(hide)|(unhide))"))) {
          handleTagHighlightIgnore(text);
        } else if (text.contains(new RegExp(
            r"^\/(w|(whisper)|(message)|(msg)|t|(tell)|(notify))"))) {
          // is private message

          List<String> splitText = text.split(new RegExp(r"\s"));
          String username = splitText[1];

          bool found = false;
          for (Chatter val in chatters) {
            if (val.nick.toLowerCase() == username.toLowerCase()) {
              username = val.nick;
              found = true;
              break;
            }
          }

          if (!found) {
            infoMsg(
                "the user you are trying to talk to is currently not in chat UwU");
            print(
                "the user you are trying to talk to is currently not in chat UwU");
            return;
          }

          String body = splitText.sublist(2).join(" ");

          ws.channel.sink.add(
              'PRIVMSG {"nick":"' + username + '", "data":"' + body + '"}');
        }
      } else {
        ws.channel.sink.add('MSG {"data":"' + text + '"}');
      }
    }

    controller.text = "";
  }

  void sendDataKeyboard(String data) {
    sendData();
  }

  // First index is type, then data
  List parseMsg(String msg) {
    return [
      msg.split(new RegExp(r"{[^}]*}"))[0].trim(),
      msg.split(new RegExp(r"^[^ ]*"))[1]
    ];
  }

  void handleReceive(String msg) {
    var wsResponse = parseMsg(msg);
    switch (wsResponse[0]) {
      case "NAMES":
        setState(() {
          chatters.addAll(buildChatterList(wsResponse[1]));
        });
        var count = getConnectionCount(wsResponse[1]);
        infoMsg(
            'Currently serving $count connections and ${chatters.length} users');
        break;
      case "MSG":
        Message m = new Message.fromJson(
            wsResponse[0], json.decode(wsResponse[1]), this.settings, nick);
        setState(() => addMessage(m));
        break;
      case "PRIVMSG":
        Message m = new Message.fromJson(
            wsResponse[0], json.decode(wsResponse[1]), this.settings, nick);
        setState(() => addMessage(m));
        break;
      case "JOIN":
        // TODO: implement join/leave for user list (visual)
        //Chatter c = new Chatter.fromJson(json.decode(wsResponse[1]));
        // print("JOIN : " + wsResponse[1]);
        break;
      case "QUIT":
        // print("QUIT : " + wsResponse[1]);
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
    if (nick == null || nick.isEmpty || nick == "Anonymous") {
      return "You need to be signed in to chat";
    } else {
      return 'Write something $nick ...';
    }
  }

  _sendComboEmote() {
    if (jwt == null || jwt == "") {
      _showLoginDialog();
      return;
    }
    if (this.messages.last.isOnlyEmote()) {
      ws.channel.sink
          .add('MSG {"data":"' + this.messages.last.messageData + '"}');
    }
  }

  bool _isComboButtonShown() {
    if (messages.isNotEmpty && messages.last.isOnlyEmote()) {
      if (messages.last.comboUsers == null) {
        if (messages.last.nick != nick) {
          return true;
        } else {
          return false;
        }
      } else {
        if (messages.last.comboUsers.contains(nick)) {
          return false;
        } else {
          return true;
        }
      }
    } else {
      return false;
    }
  }

  // TODO: base autocomplete on cursor position and not end of string
  void _updateAutocompleteSuggestions() {
    List<String> results = new List();

    // gets the last word with any trailing spaces
    RegExp exp = new RegExp(r":?[a-zA-Z]*\s*$");
    String lastWord = exp.stringMatch(controller.text).trim();

    if (lastWord.startsWith(":")) {
      lastWord = lastWord.substring(1);
      for (String mod in kEmoteModifiers) {
        if (mod.toLowerCase().startsWith(lastWord.toLowerCase()) &&
            mod != lastWord) {
          results.add(":" + mod);
        }
      }
    } else {
      // check emotes
      Iterable<String> emotes = kEmotes.keys;
      for (String emoteName in emotes) {
        if (emoteName.toLowerCase() == lastWord.toLowerCase()) {
          results.add(":");
        } else if (emoteName.toLowerCase().startsWith(lastWord.toLowerCase())) {
          results.add(emoteName);
        }
      }

      // check chatters
      for (Chatter chatter in chatters) {
        if (chatter.nick.toLowerCase().startsWith(lastWord.toLowerCase()) &&
            chatter.nick != lastWord) {
          results.add(chatter.nick);
        }
      }
    }

    autoCompleteScrollController.jumpTo(0);
    setState(() {
      autoCompleteSuggestions = results;
    });
  }

  void _insertAutocomplete(String input) {
    String oldText = controller.text;
    String newText;
    oldText = oldText.trimRight();
    if (input == ":") {
      newText = oldText + ": ";
    } else if (input.startsWith(":")) {
      int index = oldText.lastIndexOf(new RegExp(r":[a-zA-Z]*$"));
      if (index < 0) index = 0;
      oldText = oldText.substring(0, index);
      newText = oldText + input + " ";
    } else {
      int index = oldText.lastIndexOf(new RegExp(r"\s[a-zA-Z]*$"));
      if (index < 0) index = 0;
      oldText = oldText.substring(0, index);
      newText = oldText + " " + input + " ";
    }
    controller.setTextAndPosition(newText);
  }

  @override
  Widget build(BuildContext context) {
    label = determineLabel();
    this.settingsNotifier = Provider.of<SettingsNotifier>(context);
    this.settings = Provider.of<SettingsNotifier>(context).settings;

    Color headerColor = Utilities.flipColor(settings.bgColor, 100);
    return Scaffold(
        floatingActionButton: _isComboButtonShown()
            ? FloatingActionButton(
                onPressed: _sendComboEmote,
                child: ConstrainedBox(
                  constraints: BoxConstraints.expand(),
                  child: kEmotes[messages.last.messageData.split(":")[0]]
                      .img, // TODO : remove when emote modifiers are added
                ),
                backgroundColor: Colors.transparent)
            : Container(),
        appBar: new AppBar(
          iconTheme: new IconThemeData(
            color: Utilities.flipColor(headerColor, 100),
          ),
          backgroundColor: headerColor,
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
          elevation: 0.0,
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.person,
                color: Utilities.flipColor(headerColor, 100),
              ),
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
                trailing: Icon(
                  Icons.settings,
                  color: Utilities.flipColor(headerColor, 100),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsRoute(
                            settings), // TODO: fix settings widget position in tree
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
                  setState(() {
                    nick = "Anonymous";
                    jwt = "";
                    updateToken();
                  });

                  storage.deleteSetting('jwt');
                  storage.deleteSetting('nick');

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
        backgroundColor: settings.bgColor,
        body: Column(children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(
              vertical: 5.0,
              horizontal: 5.0,
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Form(
                      child: new Flexible(
                    child: new TextFormField(
                      decoration: new InputDecoration(
                        labelText: label,
                        filled: true,
                      ),
                      controller: controller,
                      onFieldSubmitted: sendDataKeyboard,
                    ),
                  )),
                  ButtonTheme(
                    minWidth: 20.0,
                    child: FlatButton(
                      onPressed: () {
                        sendData();
                      },
                      child: Icon(Icons.send),
                    ),
                  ),
                ]),
          ),
          Expanded(
            child: ListView(children: <Widget>[MessageList(messages, nick)]),
          ),
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: autoCompleteSuggestions.length,
              controller: autoCompleteScrollController,
              itemBuilder: (BuildContext ctx, int index) {
                //
                return FlatButton(
                    child: kEmotes.containsKey(autoCompleteSuggestions[index])
                        ? kEmotes["${autoCompleteSuggestions[index]}"].img
                        : Text(autoCompleteSuggestions[index]),
                    onPressed: () =>
                        {_insertAutocomplete(autoCompleteSuggestions[index])});
              },
            ),
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
