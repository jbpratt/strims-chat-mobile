import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide Storage;

import 'browser.dart';
import 'chatter.dart';
//import 'constants.dart';
import 'emote_manifest.dart';
import 'messages.dart';
import 'settings.dart';
import 'storage.dart';
import 'utilities.dart';
import 'ws/client.dart';
import 'ws/types.dart';

const String kAppTitle = 'Strims';
const String kLogoPath = 'assets/favicon.ico';

Browser inAppBrowser = Browser();

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Message> messages = [];
  List<InlineSpan> output = [];
  List<Chatter> chatters = [];
  List<String> autoCompleteSuggestions = [];

  late WSClient ws;
  late Storage storage;
  late String label;
  late Settings settings;
  late SettingsNotifier settingsNotifier;
  late TextEditingControllerWorkaroud controller;
  late ScrollController autoCompleteScrollController;
  late Manifest manifest;

  // add message , check if message & last in list is same emote
  // if combo, adds combo message // else just adds message
  void addMessage(Message msg) {
//    if (isNotCombo(message)) {
//      if (messages.isNotEmpty) {
//        if (messages.length > settings.maxMessages) {
//          messages.removeRange(
//              0,
//              (messages.length - settings.batchDeleteAmount < 0)
//                  ? 0
//                  : settings.batchDeleteAmount);
//        }
//      }
//      if (messages.isNotEmpty) {
//        messages.last.comboActive = false;
//      }
    setState(() => messages.add(msg));
//    }
//    if (messages.last.messageData == message.messageData) {
//      messages.last.comboCount = messages.last.comboCount + 1;
//      if (messages.last.comboUsers.isEmpty) {
//        messages.last.comboUsers = <String>[];
//        messages.last.comboUsers.add(messages.last.nick);
//        messages.last.nick = 'comboMessage';
//      }
//      messages.last.comboUsers.add(message.nick);
//      messages.last.comboActive = true;
//    }
  }

  void infoMsg(String msg) {
    debugPrint('info msg: ${msg.toString()}');
    addMessage(Message(
        nick: 'info',
        features: [],
        data: msg,
        type: MsgType.MSG,
        entities: null,
        timestamp: DateTime.now().millisecondsSinceEpoch));
  }
//
//  Message comboMessage(String emote, int combo) {
//    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
//    return Message.fromJson(
//        'MSG',
//        json.decode(
//            '{"nick":"$combo X C-C-C-COMBO","features":[],"timestamp":$timestamp,"data":"$emote"}'),
//        settings,
//        ws.user,
//        comboCount: combo);
//  }

  void listen() {
    ws.history().then((List<Message>? history) {
      if (history != null) {
        history.forEach(addMessage);
      }
      infoMsg('Connecting to chat.strims.gg ...');
      ws
        ..onMsgFunc = onMsg
        ..onPrivMsgFunc = onPrivMsg
        ..dial()
        ..listen();
      infoMsg('Connection established');
    });
  }

  Future<void> login() async {
    // if already logged in then open profile
    infoMsg('login is currently disabled');
//    await inAppBrowser
//        .openUrlRequest(
//            urlRequest: URLRequest(url: Uri.parse('$kURL/login')))
//        .then((val) {
//      inAppBrowser.onLoadStop(Uri.parse('$kURL/')).then((onValue) {
//        inAppBrowser.getCookie('jwt').then((cookie) {
//          final String tmp = cookie.value;
//          if (tmp.isNotEmpty) {
//            jwt = tmp;
//            updateToken();
//            storage.addSetting('jwt', jwt);
//            _getAndSaveUsername();
//          }
//        });
//      });
//    }).then((onValue) {
//      resetChannel();
//    });
  }

  void resetOnPopupClose() => ws.reset();

  Future<void> fetchManifest() async =>
      manifest = await Manifest.fromURL(kEmoteManifest);

  @override
  void initState() {
    super.initState();
    ws = WSClient();
    storage = Storage();
    storage.initS().then((_) {
      infoMsg('checking storage for user');
      if (storage.hasSetting('jwt')) {
        infoMsg('found user in storage');
        setState(() {
          ws.login(storage.getSetting('jwt'));
          label = determineLabel();
        });
      }
    }).then((_) {
      fetchManifest();
      listen();
    });
    controller = TextEditingControllerWorkaroud();
    autoCompleteScrollController = ScrollController();
//    controller.addListener(_updateAutocompleteSuggestions);
  }

  Future<void> _showLoginDialog() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          if (ws.user != 'Anonymous' && ws.token.isNotEmpty) {
            // TODO: remove the popup somehow
          }
          return AlertDialog(
            title: const Text('Whoops!'),
            content: const Text('You must first sign in to chat'),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  await login();
                },
                child: const Text('Sign in'),
              ),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    resetOnPopupClose();
                  },
                  child: const Text('Close'))
            ],
          );
        });
  }

  void handleTagHighlightIgnore(String input) {
    const colors = [
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
    final output = inputNoWhitespace.split(' ');
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
              ? 'No tagged users, syntax : \/tag {user} {color}. Available colors: ' +
                  colors.toString().replaceAll('[', '').replaceAll(']', '')
              : 'Highlighted users : ' +
                  settings.userTags
                      .toString()
                      .replaceAll('{', '')
                      .replaceAll('}', '') +
                  '. Available colors: ' +
                  colors.toString().replaceAll('[', '').replaceAll(']', ''));
        } else if (output.length == 2 || output[2].isEmpty) {
          final color = colors[Random().nextInt(colors.length - 1)];
          infoMsg('Tagged ' + output[1] + ' as ' + color);
          settingsNotifier.addUserTags(output[1], color);
        } else if (output.length >= 3) {
          String color = '';
          if (!colors.contains(output[2].toLowerCase())) {
            color = colors[Random().nextInt(colors.length - 1)];
          } else {
            color = output[2].toLowerCase();
          }
          infoMsg('Tagged ${output[1]} as $color');
          settingsNotifier.addUserTags(output[1], color);
        }
        break;
      case 'untag':
        if (output.length == 1 || output[1].isEmpty) {
          infoMsg(settings.userTags.isEmpty
              ? 'No tagged users, syntax : \/untag {user} {color}. Available colors: ' +
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
          infoMsg('${output[1]} has been removed from your ignore list');
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
          infoMsg('Hiding messages including ${output[1]}');
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
    if (!ws.isAuthenticated) {
      _showLoginDialog();
      return;
    }

    if (controller.text.isNotEmpty) {
      final String text = controller.text;
      // if first two chars are '/w' or '/msg' or '/message' or '/tell' or
      // '/notify' or '/t'  or '/whisper' // <- all pms if user is auth as
      // moderator: '/ban' or '/mute'

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

          final List<String> splitText = text.split(RegExp(r'\s'));
          String username = splitText[1];

          bool found = false;
          for (final Chatter val in chatters) {
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

          final String body = splitText.sublist(2).join(' ');

          ws.send('PRIVMSG {"nick":"$username", "data":"$body"}');
        }
      } else {
        ws.send('MSG {"data":"$text"}');
      }
    }

    controller.text = '';
  }

  void sendDataKeyboard(String data) => sendData();

  void onMsg(Message msg) => addMessage(msg);

  void onPrivMsg(Message msg) => addMessage(msg);

  @override
  void dispose() {
    ws.close();
    super.dispose();
  }

  String determineLabel() {
    if (!ws.isAuthenticated) {
      return 'You need to be signed in to chat';
    } else {
      return 'Write something ${ws.user}...';
    }
  }

//  void _sendComboEmote() {
//    if (!ws.isAuthenticated) {
//      _showLoginDialog();
//      return;
//    }
//    if (messages.last.isOnlyEmote()) {
//      ws.send('MSG {"data":"${messages.last.messageData}"}');
//    }
//  }
//
//  bool _isComboButtonShown() {
//    if (messages.isNotEmpty && messages.last.isOnlyEmote()) {
//      if (messages.last.comboUsers.isEmpty) {
//        return messages.last.nick != ws.user;
//      } else {
//        return !messages.last.comboUsers.contains(ws.user);
//      }
//    } else {
//      return false;
//    }
//  }

  // TODO: base autocomplete on cursor position and not end of string
//  void _updateAutocompleteSuggestions() {
//    final List<String> results = [];
//    // gets the last word with any trailing spaces
//    final RegExp exp = RegExp(r':?[a-zA-Z]*\s*$');
//    String lastWord = exp.stringMatch(controller.text)!.trim();
//
//    if (lastWord.startsWith(':')) {
//      lastWord = lastWord.substring(1);
//      for (final String mod in manifest.modifiers) {
//        if (mod.toLowerCase().startsWith(lastWord.toLowerCase()) &&
//            mod != lastWord) {
//          results.add(':$mod');
//        }
//      }
//    } else {
//      // check emotes
//      for (final Emote emote in manifest.emotes) {
//        if (emote.name.toLowerCase() == lastWord.toLowerCase()) {
//          if (emote.name == lastWord) {
//            results.add(':');
//          } else {
//            results.add(emote.name);
//          }
//        } else if (emote.name
//                .toLowerCase()
//                .startsWith(lastWord.toLowerCase()) ||
//            controller.text.isEmpty) {
//          results.add(emote.name);
//        }
//      }
//
//      // check chatters
//      for (final Chatter chatter in chatters) {
//        if ((chatter.nick.toLowerCase().startsWith(lastWord.toLowerCase()) ||
//                controller.text.isEmpty) &&
//            chatter.nick != lastWord) {
//          results.add(chatter.nick);
//        }
//      }
//    }
//    if (autoCompleteScrollController.hasClients) {
//      // stops us from accessing this when not attached to a list
//      autoCompleteScrollController.jumpTo(0);
//    }
//
//    setState(() {
//      if (controller.text.isEmpty) {
//        results.shuffle();
//      }
//      autoCompleteSuggestions = results;
//    });
//  }
//
//  void _insertAutocomplete(String input) {
//    String oldText = controller.text;
//    String newText;
//    oldText = oldText.trimRight();
//    if (input == ':') {
//      newText = oldText + ': ';
//    } else if (input.startsWith(':')) {
//      int index = oldText.lastIndexOf(RegExp(r':[a-zA-Z]*$'));
//      if (index < 0) index = 0;
//      oldText = oldText.substring(0, index);
//      newText = oldText + input + ' ';
//    } else {
//      int index = oldText.lastIndexOf(RegExp(r'\s[a-zA-Z]*$'));
//      if (index < 0) index = 0;
//      oldText = oldText.substring(0, index);
//      newText = oldText + ' ' + input + ' ';
//    }
//    controller.setTextAndPosition(newText);
//  }

  @override
  Widget build(BuildContext context) {
    label = determineLabel();
    settingsNotifier = Provider.of<SettingsNotifier>(context);
    settings = Provider.of<SettingsNotifier>(context).settings;

    final Color headerColor = Utilities.flipColor(settings.bgColor, 100);

    // TODO: move this to map lookup
//    late Emote emote;
//    for (final e in manifest.emotes) {
//      if (e.name == messages.last.messageData.split(':')[0]) {
//        emote = e;
//        break;
//      }
//    }

    return Scaffold(
        // TODO: floating combo button disabled
//        floatingActionButton: _isComboButtonShown()
//            ? FloatingActionButton(
//                onPressed: _sendComboEmote,
//                backgroundColor: Colors.transparent,
//                child: ConstrainedBox(
//                  constraints: const BoxConstraints.expand(),
//                  child: emote.images[Size
//                      .THE_2_X], // TODO : remove when emote modifiers are added
//                ))
//            : Container(),
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
                  padding: const EdgeInsets.all(8),
                  child: const Text(kAppTitle))
            ],
          ),
          elevation: 0,
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.person,
                color: Utilities.flipColor(headerColor, 100),
              ),
              onPressed: login,
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
              ListTile(
                title: const Text('Settings'),
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
                title: const Text('User list'),
                trailing: const Icon(Icons.people),
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
                title: const Text('PMs'),
                trailing: const Icon(Icons.mail),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WhispersRoute(),
                      ));
                },
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    ws.logout();
                  });
                  storage..deleteSetting('jwt')..deleteSetting('nick');
                  ws.reset();
                  // reset conn
                  Navigator.of(context).pop();
                  setState(() {
                    label = determineLabel();
                  });
                },
                child: const Text('Logout'),
              )
            ],
          ),
        ),
        backgroundColor: settings.bgColor,
        body: Column(children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 5,
              horizontal: 5,
            ),
            child: Row(children: <Widget>[
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
                minWidth: 20,
                child: TextButton(
                  onPressed: sendData,
                  child: const Icon(Icons.send),
                ),
              ),
            ]),
          ),
          Expanded(
            child: ListView(children: <Widget>[MessageList(messages, ws.user)]),
          ),
//          Container(
//            height: 50,
//            child: ListView.builder(
//              scrollDirection: Axis.horizontal,
//              itemCount: autoCompleteSuggestions.length,
//              controller: autoCompleteScrollController,
//              itemBuilder: (BuildContext ctx, int index) {
////                final e = manifest.emote(autoCompleteSuggestions[index]);
//                return TextButton(
//                    onPressed: () =>
//                        {_insertAutocomplete(autoCompleteSuggestions[index])},
//                    child: // e != null
//                        //? e.images[Size.THE_2_X]!
//                        //:
//                        Text(autoCompleteSuggestions[index]));
//              },
//            ),
//          )
        ]));
  }
}

class WhispersRoute extends StatelessWidget {
  const WhispersRoute({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Whispers'),
        ),
        body: Column());
  }
}
