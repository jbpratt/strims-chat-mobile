import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
//import 'package:url_launcher/url_launcher.dart';
import 'settings.dart';
import 'utilities.dart';
import 'ws/types.dart';

class MessageList extends StatefulWidget {
  const MessageList(this._messages, this._userNickname, {Key? key})
      : super(key: key);

  final List<Message> _messages;
  final String _userNickname;

  @override
  _MessageListState createState() => _MessageListState(_messages);
}

class _MessageListState extends State<MessageList> {
  _MessageListState(this.messages);

  final ScrollController _controller = ScrollController();
  // QUESTION: should this be private?
  final List<Message> messages;
  late Settings _settings;

  @override
  Widget build(BuildContext context) {
    _settings = Provider.of<SettingsNotifier>(context).settings;
    // remove all hidden ignored messages
//    messages.retainWhere((message) =>
//        message.shouldShow(_settings));
    return Container(
        color: _settings.bgColor,
        child: ListView.builder(
          shrinkWrap: true,
          reverse: true,
          controller: _controller,
          itemCount: widget._messages.length,
          itemBuilder: (BuildContext ctx, int index) {
            final Message msg = widget._messages[index];
            return Card(
                color: _settings.cardColor,
                // TODO: do this properly
//                child: Container(
//                    decoration: BoxDecoration(
//                      borderRadius: const BorderRadius.all(Radius.circular(4)),
//                      gradient: LinearGradient(stops: const [
//                        0.02,
//                        0.02
//                      ], colors: [
//                        //msg.getTagColor(_settings, msg.nick),
//                        //if (msg.mentioned || msg.hasKeyword)
////                          const Color.fromARGB(255, 0, 37, 71)
//                        //else
//                        _settings.cardColor
//                      ]),
//                    ),
                child: _MessageListItem(msg, _settings, widget._userNickname));
          },
        ));
  }
}

class _MessageListItem extends ListTile {
  const _MessageListItem(this._msg, this._settings, this._userNickname)
      : super();

  final Settings _settings;
  final String _userNickname;
  final Message _msg;

  @override
  Widget build(BuildContext context) {
    Color tileColor = _settings.cardColor;
    if (_msg.nick == 'info') {
      tileColor = colorFromName('sky');
    }

    if (_msg.nick == _userNickname) {
      tileColor = Utilities.lightenColor(_settings.cardColor, 10);
    }

    return ListTile(
        tileColor: tileColor,
        dense: true,
        title: Padding(
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 8,
            ),
            child: Text.rich(
              TextSpan(children: <InlineSpan>[TextSpan(text: _msg.data)]),
            )),
        subtitle: Padding(
            padding: const EdgeInsets.only(
              bottom: 8,
            ),
            child: Text.rich(TextSpan(
                text: _msg.type == MsgType.PRIVMSG
                    ? '${_msg.nick} whispered'
                    : _msg.nick,
                style: TextStyle(
                  backgroundColor: _msg.type == MsgType.PRIVMSG
                      ? Utilities.flipColor(_settings.cardColor, 50)
                      : null,
                  fontStyle:
                      _msg.type == MsgType.PRIVMSG ? FontStyle.italic : null,
                  color: _msg.type == MsgType.PRIVMSG
                      ? Utilities.flipColor(
                          Utilities.flipColor(_settings.cardColor, 50), 100)
                      : Utilities.flipColor(_settings.cardColor, 100),
                )))),
        onTap: () {});
  }

//  static Future<void> _launchURL(String url) async {
//    if (await canLaunch(url)) {
//      await launch(url);
//    } else {
//      throw 'Could not launch $url';
//    }
//  }
//
//  // TODO: comboActive is never getting set to true
//  static List<InlineSpan> comboWidget(int comboAmount,
//      {bool comboActive = false}) {
//    final output = <InlineSpan>[];
//    if (!comboActive) {
//      return output;
//    }
//
//    double fontSize = 15;
//    FontWeight fontWeight = FontWeight.normal;
//    //TODO: change these sizes
//    if (comboAmount >= 50) {
//      fontWeight = FontWeight.w900;
//      fontSize *= 5;
//    } else if (comboAmount >= 30) {
//      fontWeight = FontWeight.w700;
//      fontSize *= 4;
//    } else if (comboAmount >= 20) {
//      fontWeight = FontWeight.w700;
//      fontSize *= 3;
//    } else if (comboAmount >= 10) {
//      fontWeight = FontWeight.w700;
//      fontSize *= 2;
//    } else if (comboAmount >= 5) {
//      fontSize *= 1.5;
//    }
//    // HACKER 7 X C-C-C-COMBO
//    // combo amount
//    output
//      ..add(TextSpan(
//          text: ' ${comboAmount.toString()}',
//          style: TextStyle(fontSize: fontSize, fontWeight: fontWeight)))
//      ..add(TextSpan(
//          text: ' X ',
//          style: TextStyle(fontSize: fontSize * .7, fontWeight: fontWeight)))
//      ..add(TextSpan(
//          text: comboActive ? 'HITS' : 'C-C-C-COMBO',
//          style: TextStyle(fontSize: fontSize * .7, fontWeight: fontWeight)));
//    return output;
//    //(comboActive ? "Hits" : "C-C-C-COMBO")
//  }
}
