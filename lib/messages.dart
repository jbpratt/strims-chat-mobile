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
        color: _settings.cardColor,
        child: ListView.builder(
          shrinkWrap: true,
          reverse: true,
          controller: _controller,
          itemCount: messages.length,
          itemBuilder: (BuildContext ctx, int index) {
            final Message msg = messages[index];
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
    if (_msg.user!.nick == 'info') {
      tileColor = Utilities.colorFromName('sky');
    }

    if (_msg.user!.nick == _userNickname) {
      tileColor = Utilities.lightenColor(_settings.cardColor, 10);
    }

    return ListTile(
        tileColor: tileColor,
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
            child: Text.rich(TextSpan(children: <InlineSpan>[
              // TODO: if timestamp enabled/disabled
              TextSpan(
                  text: '${Utilities.humanizeTimestamp(_msg.timestamp)} ',
                  style: TextStyle(
                      color: Utilities.flipColor(_settings.cardColor, 100))),
              TextSpan(
                  text: _msg.type == MsgType.PRIVMSG
                      ? '${_msg.user!.nick} whispered'
                      : _msg.user!.nick,
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
                  ))
            ]))),
        onTap: () {});
  }
}
