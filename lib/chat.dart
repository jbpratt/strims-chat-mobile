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

final String kAppTitle = 'Strims';
final String kLogoPath = 'assets/favicon.ico';
final String kAddress = 'wss://chat.strims.gg/ws';

Browser inAppBrowser = Browser();
String jwt = '';
String nick = 'Anonymous';
const String URL = 'https://strims.gg';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingControllerWorkaroud controller;
  List<Message> messages = [];
  WSClient ws = WSClient(kAddress, token: jwt);
  List<InlineSpan> output = [];
  List<Chatter> chatters = [];
  List<String> autoCompleteSuggestions = [];
  ScrollController autoCompleteScrollController;
  Future<Map<String, Emote>> emotes;
  Storage storage = Storage();
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
              0,
              (messages.length - settings.batchDeleteAmount < 0)
                  ? 0
                  : settings.batchDeleteAmount);
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
        messages.last.comboUsers = <String>[];
        messages.last.comboUsers.add(messages.last.nick);
        messages.last.nick = 'comboMessage';
      }
      messages.last.comboUsers.add(message.nick);
      messages.last.comboActive = true;
    }
  }

  void infoMsg(String msg) {
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    Message m = Message.fromJson(
        'MSG',
        json.decode(
            '{"nick":"info","features":[],"timestamp":$timestamp,"data":"$msg"}'),
        settings,
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
        'MSG',
        json.decode(
            '{"nick":"$combo X C-C-C-COMBO","features":[],"timestamp":$timestamp,"data":"$emote"}'),
        settings,
        nick);
    m.comboCount = combo;
    return m;
  }

  Future<String> _getUsername(String jwt) async {
    var headers = <String, String>{};
    headers['Cookie'] = 'jwt=$jwt';
    headers['user-agent'] = 'mobile.chat.strims.gg';
    Response response =
        await get(Uri.dataFromString('$URL/api/profile'), headers: headers);
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return jsonResponse['username'].toString();
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return null;
    }
  }

  Future<void> _requestChatHistory() async {
    var headers = <String, String>{};
    headers['user-agent'] = 'mobile.chat.strims.gg';
    Response response = await get(Uri.dataFromString('$URL/api/chat/history'),
        headers: headers);
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body) as List;
      jsonResponse.forEach((i) => handleReceive(i.toString()));
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return null;
    }
  }

  void listen() {
    _requestChatHistory().then((onValue) {
      infoMsg('Connecting to chat.strims.gg ...');
      WebSocketChannel channel = ws.dial();
      infoMsg('Connection established');
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

  Future<void> login() async {
    // if already logged in then open profile
    await inAppBrowser.open(url: '$URL/login').then((val) {
      inAppBrowser.onLoadStop('$URL/').then((onValue) {
        inAppBrowser.getCookie('jwt').then((cookie) {
          String tmp = cookie.value;
          if (tmp != null && tmp.isNotEmpty) {
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
    infoMsg('reconnecting...');
    listen();
  }

  void resetOnPopupClose() {
    updateToken();
    resetChannel();
  }

  Future<void> getAllEmotes() async {
    kEmotes = await getEmotes();
  }

  Future<void> _getAndSaveUsername() async {
    nick = await _getUsername(jwt);
    await storage.addSetting('nick', nick);
  }

  @override
  void initState() {
    super.initState();
    storage.initS().then((val) {
      infoMsg('checking storage for user');
      if (storage.hasSetting('jwt')) {
        infoMsg('found user in storage');
        setState(() {
          jwt = storage.getSetting('jwt');
          nick = storage.getSetting('nick');
          label = determineLabel();
        });
      }
    }).then((val) {
      updateToken();
      listen();
    });
    controller = TextEditingControllerWorkaroud();
    autoCompleteScrollController = ScrollController();

    controller.addListener(_updateAutocompleteSuggestions);
    getAllEmotes();
  }

  Future _showLoginDialog() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          if (nick != 'Anonymous' && jwt.isNotEmpty) {
            // TODO: remove the popup somehow
          }
          return AlertDialog(
            title: Text('Whoops!'),
            content: Text('You must first sign in to chat'),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  await login();
                },
                child: Text('Sign in'),
              ),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    resetOnPopupClose();
                  },
                  child: Text('Close'))
            ],
          );
        });
  }

  void handleTagHighlightIgnore(String input) {
    List colors = [
      'green',
      'yellow',
      'orange',
      'red',
      'purple',
      'blue',
      'sky',
      'lime',
      'pink',
      'black'
    ];
    //TODO: regex this
    // prepare yourself for spaghetti
    String inputNoWhitespace = input;
    bool test = true;
    while (test) {
      if (inputNoWhitespace.contains('  ')) {
        inputNoWhitespace = inputNoWhitespace.replaceAll('  ', ' ');
      } else {
        test = false;
      }
    }
    List output = inputNoWhitespace.split(' ');
    switch (output[0].toString().replaceAll('/', '')) {
      case 'highlight':
        if (output.length == 1 || output[1].isEmpty) {
          infoMsg(settings.wordsHighlighted.isEmpty
              ? 'No highlighted words, syntax : \/highlight {word}'
              : 'Highlighted words : ' +
                  settings.wordsHighlighted
                      .toString()
                      .replaceAll('{', '')
                      .replaceAll('}', ''));
        } else if (output.length >= 2) {
          infoMsg('Highlighting ' + output[1]);
          settingsNotifier.addWordsHighlighted(output[1]);
        }
        break;
      case 'unhighlight':
        if (output.length == 1 || output[1].isEmpty) {
          infoMsg(settings.wordsHighlighted.isEmpty
              ? 'No highlighted words, syntax : \/unhighlight {word}'
              : 'Highlighted words : ' +
                  settings.wordsHighlighted
                      .toString()
                      .replaceAll('{', '')
                      .replaceAll('}', ''));
        } else if (output.length >= 2) {
          infoMsg('No longer highlighting ' + output[1]);
          settingsNotifier.removeWordsHighlighted(output[1]);
        }
        break;
      case 'tag':
        if (output.length == 1 || output[1].isEmpty) {
          infoMsg(settings.userTags.isEmpty
              ? 'No tagged users, syntax : \/tag {user} {color}'
                      '. Available colors: ' +
                  colors.toString().replaceAll('[', '').replaceAll(']', '')
              : 'Highlighted users : ' +
                  settings.userTags
                      .toString()
                      .replaceAll('{', '')
                      .replaceAll('}', '') +
                  '. Available colors: ' +
                  colors.toString().replaceAll('[', '').replaceAll(']', ''));
        } else if (output.length == 2 || output[2].isEmpty) {
          var color = colors[Random().nextInt(colors.length - 1)];
          infoMsg('Tagged ' + output[1] + ' as ' + color);
          settingsNotifier.addUserTags(output[1], color);
        } else if (output.length >= 3) {
          String color = '';
          if (!colors.contains(output[2].toLowerCase())) {
            color = colors[Random().nextInt(colors.length - 1)];
          } else {
            color = output[2].toLowerCase();
          }
          infoMsg('Tagged ' + output[1] + ' as ' + color);
          settingsNotifier.addUserTags(output[1], color);
        }
        break;
      case 'untag':
        if (output.length == 1 || output[1].isEmpty) {
          infoMsg(settings.userTags.isEmpty
              ? 'No tagged users, syntax : \/untag {user} {color}'
                      '. Available colors: ' +
                  colors.toString().replaceAll('[', '').replaceAll(']', '')
              : 'Highlighted users : ' +
                  settings.userTags
                      .toString()
                      .replaceAll('{', '')
                      .replaceAll('}', '') +
                  '. Available colors: ' +
                  colors.toString().replaceAll('[', '').replaceAll(']', ''));
        } else if (output.length >= 2) {
          infoMsg('Un-tagged ' + output[1]);
          settingsNotifier.removeUserTags(output[1]);
        }
        break;
      case 'ignore':
        if (output.length == 1 || output[1].isEmpty) {
          infoMsg(settings.usersIgnored.isEmpty
              ? 'Your ignore list is empty, syntax : \/ignore {user}'
              : 'Ignored Users : ' +
                  settings.usersIgnored
                      .toString()
                      .replaceAll('{', '')
                      .replaceAll('}', ''));
        } else if (output.length >= 2) {
          infoMsg('Ignoring ' + output[1]);
          settingsNotifier.addUsersIgnored(output[1]);
        }
        break;
      case 'unignore':
        if (output.length == 1 || output[1].isEmpty) {
          infoMsg(settings.usersIgnored.isEmpty
              ? 'Your ignore list is empty, syntax : \/unignore {user}'
              : 'Ignored Users : ' +
                  settings.usersIgnored
                      .toString()
                      .replaceAll('{', '')
                      .replaceAll('}', ''));
        } else if (output.length >= 2) {
          infoMsg(output[1] + ' has been removed from your ignore list');
          settingsNotifier.removeUsersIgnored(output[1]);
        }
        break;
      case 'hide':
        if (output.length == 1 || output[1].isEmpty) {
          infoMsg(settings.wordsHidden.isEmpty
              ? 'You have no hidden words : \/hide {word}'
              : 'Hidden words : ' +
                  settings.wordsHidden
                      .toString()
                      .replaceAll('{', '')
                      .replaceAll('}', ''));
        } else if (output.length >= 2) {
          infoMsg('Hiding messages including ' + output[1]);
          settingsNotifier.addWordsHidden(output[1]);
        }
        break;
      case 'unhide':
        if (output.length == 1 || output[1].isEmpty) {
          infoMsg(settings.wordsHidden.isEmpty
              ? 'You have no hidden words : \/unhide {word}'
              : 'Hidden words : ' +
                  settings.wordsHidden
                      .toString()
                      .replaceAll('{', '')
                      .replaceAll('}', ''));
        } else if (output.length >= 2) {
          infoMsg('No longer hiding messages including ' + output[1]);
          settingsNotifier.removeWordsHidden(output[1]);
        }
        break;
      default:
        infoMsg('please try re-typing your command');
        break;
    }
  }

  void sendData() {
    if (jwt == null || jwt == '') {
      _showLoginDialog();
    }

    if (controller.text.isNotEmpty) {
      String text = controller.text;
      // if first two chars are '/w' or '/msg' or '/message' or '/tell' or
      // '/notify' or '/t'  or '/whisper' // <- all pms if user is auth as
      // moderator // '/ban' or '/mute'

      if (text[0] == '/') {
        // TODO: trim left for function check ?
        // TODO: lowercase functions ?

        // TODO: handle all "/" functions
        if (text.contains(RegExp(
            r'^\/((highlight)|(unhighlight)|(tag)|(untag)|(ignore)|(unignore)|(hide)|(unhide))'))) {
          handleTagHighlightIgnore(text);
        } else if (text.contains(
            RegExp(r'^\/(w|(whisper)|(message)|(msg)|t|(tell)|(notify))'))) {
          // is private message

          List<String> splitText = text.split(RegExp(r'\s'));
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
                'the user you are trying to talk to is currently not in chat UwU');
            print(
                'the user you are trying to talk to is currently not in chat UwU');
            return;
          }

          String body = splitText.sublist(2).join(' ');

          ws.channel.sink.add(
              'PRIVMSG {"nick":"' + username + '", "data":"' + body + '"}');
        }
      } else {
        ws.channel.sink.add('MSG {"data":"' + text + '"}');
      }
    }

    controller.text = '';
  }

  void sendDataKeyboard(String data) {
    sendData();
  }

  // First index is type, then data
  List<String> parseMsg(String msg) {
    return [
      msg.split(RegExp(r'{[^}]*}'))[0].trim(),
      msg.split(RegExp(r'^[^ ]*'))[1]
    ];
  }

  void handleReceive(String msg) {
    var wsResponse = parseMsg(msg);
    switch (wsResponse[0]) {
      case 'NAMES':
        setState(() {
          chatters.addAll(buildChatterList(wsResponse[1]));
        });
        var count = getConnectionCount(wsResponse[1]);
        _updateAutocompleteSuggestions();
        infoMsg(
            'Currently serving $count connections and ${chatters.length} users');
        break;
      case 'MSG':
        Message m = Message.fromJson(
            wsResponse[0], json.decode(wsResponse[1]), settings, nick);
        setState(() => addMessage(m));
        break;
      case 'PRIVMSG':
        Message m = Message.fromJson(
            wsResponse[0], json.decode(wsResponse[1]), settings, nick);
        setState(() => addMessage(m));
        break;
      case 'JOIN':
        // TODO: implement join/leave for user list (visual)
        //Chatter c = new Chatter.fromJson(json.decode(wsResponse[1]));
        // print("JOIN : " + wsResponse[1]);
        break;
      case 'QUIT':
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
    if (nick == null || nick.isEmpty || nick == 'Anonymous') {
      return 'You need to be signed in to chat';
    } else {
      return 'Write something $nick ...';
    }
  }

  void _sendComboEmote() {
    if (jwt == null || jwt == '') {
      _showLoginDialog();
      return;
    }
    if (messages.last.isOnlyEmote()) {
      ws.channel.sink.add('MSG {"data":"' + messages.last.messageData + '"}');
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
    List<String> results = [];
    // gets the last word with any trailing spaces
    RegExp exp = RegExp(r':?[a-zA-Z]*\s*$');
    String lastWord = exp.stringMatch(controller.text).trim();

    if (lastWord.startsWith(':')) {
      lastWord = lastWord.substring(1);
      for (String mod in kEmoteModifiers) {
        if (mod.toLowerCase().startsWith(lastWord.toLowerCase()) &&
            mod != lastWord) {
          results.add(':' + mod);
        }
      }
    } else {
      // check emotes
      for (String emoteName in kEmotes.keys) {
        if (emoteName.toLowerCase() == lastWord.toLowerCase()) {
          if (emoteName == lastWord) {
            results.add(':');
          } else {
            results.add(emoteName);
          }
        } else if (emoteName.toLowerCase().startsWith(lastWord.toLowerCase()) ||
            controller.text.isEmpty) {
          results.add(emoteName);
        }
      }

      // check chatters
      for (Chatter chatter in chatters) {
        if ((chatter.nick.toLowerCase().startsWith(lastWord.toLowerCase()) ||
                controller.text.isEmpty) &&
            chatter.nick != lastWord) {
          results.add(chatter.nick);
        }
      }
    }
    if (autoCompleteScrollController.hasClients) {
      // stops us from accessing this when not attached to a list
      autoCompleteScrollController.jumpTo(0);
    }

    setState(() {
      if (controller.text.isEmpty) {
        results.shuffle();
      }
      autoCompleteSuggestions = results;
    });
  }

  void _insertAutocomplete(String input) {
    String oldText = controller.text;
    String newText;
    oldText = oldText.trimRight();
    if (input == ':') {
      newText = oldText + ': ';
    } else if (input.startsWith(':')) {
      int index = oldText.lastIndexOf(RegExp(r':[a-zA-Z]*$'));
      if (index < 0) index = 0;
      oldText = oldText.substring(0, index);
      newText = oldText + input + ' ';
    } else {
      int index = oldText.lastIndexOf(RegExp(r'\s[a-zA-Z]*$'));
      if (index < 0) index = 0;
      oldText = oldText.substring(0, index);
      newText = oldText + ' ' + input + ' ';
    }
    controller.setTextAndPosition(newText);
  }

  @override
  Widget build(BuildContext context) {
    label = determineLabel();
    settingsNotifier = Provider.of<SettingsNotifier>(context);
    settings = Provider.of<SettingsNotifier>(context).settings;

    Color headerColor = Utilities.flipColor(settings.bgColor, 100);
    return Scaffold(
        floatingActionButton: _isComboButtonShown()
            ? FloatingActionButton(
                onPressed: _sendComboEmote,
                backgroundColor: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints.expand(),
                  child: kEmotes[messages.last.messageData.split(':')[0]]
                      .img, // TODO : remove when emote modifiers are added
                ))
            : Container(),
        appBar: AppBar(
          iconTheme: IconThemeData(
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
                  padding: const EdgeInsets.all(8.0), child: Text(kAppTitle))
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
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    nick = 'Anonymous';
                    jwt = '';
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
                      child: Flexible(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: label,
                        filled: true,
                      ),
                      controller: controller,
                      onFieldSubmitted: sendDataKeyboard,
                    ),
                  )),
                  ButtonTheme(
                    minWidth: 20.0,
                    child: TextButton(
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
                return TextButton(
                    onPressed: () =>
                        {_insertAutocomplete(autoCompleteSuggestions[index])},
                    child: kEmotes.containsKey(autoCompleteSuggestions[index])
                        ? kEmotes['${autoCompleteSuggestions[index]}'].img
                        : Text(autoCompleteSuggestions[index]));
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
          title: Text('Whispers'),
        ),
        body: Column(children: <Widget>[]));
  }
}
