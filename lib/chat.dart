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
  List<String> autoCompleteSuggestions = [];

  late Chatters chatters;
  late WSClient ws;
  late Storage storage;
  late String label;
  late Settings settings;
  late SettingsNotifier settingsNotifier;
  late TextEditingControllerWorkaroud controller;
  late ScrollController autoCompleteScrollController;
  late Manifest manifest;

  void addMessage(Message msg) => setState(() => messages.add(msg));

  void infoMsg(String msg) {
    debugPrint('info msg: ${msg.toString()}');
    addMessage(Message(
        user: User(nick: 'info', features: []),
        data: msg,
        type: MsgType.MSG,
        timestamp: DateTime.now().millisecondsSinceEpoch));
  }

  void listen() {
    ws.history().then((List<Message>? history) {
      if (history != null) {
        history.forEach(addMessage);
      }
      infoMsg('Connecting to chat.strims.gg ...');
      ws
        ..onMsgFunc = onMsg
        ..onPrivMsgFunc = onPrivMsg
        ..onNamesMsgFunc = onNamesMsg
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
          //handleTagHighlightIgnore(text);
        } else if (text.contains(
            RegExp(r'^\/(w|(whisper)|(message)|(msg)|t|(tell)|(notify))'))) {
          // is private message

          final List<String> splitText = text.split(RegExp(r'\s'));
          String username = splitText[1];

          bool found = false;
          for (final User val in chatters.users) {
            if (val.nick.toLowerCase() == username.toLowerCase()) {
              username = val.nick;
              found = true;
              break;
            }
          }

          if (!found) {
            infoMsg(
                'the user you are trying to talk to is currently not in chat');
            return;
          }

          final String body = splitText.sublist(2).join(' ');
          ws.send(Message(
              type: MsgType.PRIVMSG,
              user: User(nick: username, features: []),
              data: body));
        }
      } else {
        ws.send(Message(type: MsgType.MSG, data: text));
      }
    }

    controller.text = '';
  }

  void sendDataKeyboard(String data) => sendData();

  void onMsg(Message msg) => addMessage(msg);

  void onPrivMsg(Message msg) => addMessage(msg);

  void onNamesMsg(Chatters chatters) =>
      setState(() => this.chatters = chatters);

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

  @override
  Widget build(BuildContext context) {
    label = determineLabel();
    settingsNotifier = Provider.of<SettingsNotifier>(context);
    settings = Provider.of<SettingsNotifier>(context).settings;

    final Color headerColor = Utilities.flipColor(settings.bgColor, 100);

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
                      MaterialPageRoute<SettingsRoute>(
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
                      MaterialPageRoute<SettingsRoute>(
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
                      MaterialPageRoute<WhispersRoute>(
                        builder: (context) => const WhispersRoute(),
                      ));
                },
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    ws.logout();
                    label = determineLabel();
                  });
                  storage..deleteSetting('jwt')..deleteSetting('nick');
                  Navigator.of(context).pop();
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
