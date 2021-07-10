import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'emotes.dart';
import 'settings.dart';
import 'utilities.dart';

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
    messages.retainWhere((message) =>
        message.shouldShow(_settings)); // remove all hidden ignored messages
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
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      gradient: LinearGradient(stops: const [
                        0.02,
                        0.02
                      ], colors: [
                        msg.getTagColor(_settings, msg.nick),
                        if (msg.mentioned || msg.hasKeyword)
                          const Color.fromARGB(255, 0, 37, 71)
                        else
                          _settings.cardColor
                      ]),
                    ),
                    child: _MessageListItem(
                        msg, _settings, widget._userNickname)));
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
    return ListTile(
        dense: true,
        title: Padding(
          padding: const EdgeInsets.only(
            top: 8,
            bottom: 8,
          ),
          child: Text.rich(
            TextSpan(
              children: messageToWidget(_msg.data, _settings, _userNickname,
                  _msg.nick, _msg.type, _msg.comboCount,
                  comboActive: _msg.comboActive),
            ), // colour here somehow
          ),
        ),
        subtitle: _msg.comboCount == 1
            ? Padding(
                padding: const EdgeInsets.only(
                  bottom: 8,
                ),
                child: Text.rich(TextSpan(
                    text: _msg.type == 'PRIVMSG'
                        ? '${_msg.nick} whispered'
                        : _msg.nick,
                    style: TextStyle(
                      backgroundColor: _msg.type == 'PRIVMSG'
                          ? Utilities.flipColor(_settings.cardColor, 50)
                          : null,
                      fontStyle:
                          _msg.type == 'PRIVMSG' ? FontStyle.italic : null,
                      color: _msg.type == 'PRIVMSG'
                          ? Utilities.flipColor(
                              Utilities.flipColor(_settings.cardColor, 50), 100)
                          : Utilities.flipColor(_settings.cardColor, 100),
                    ))))
            : null,
        onTap: () {});
  }

  static Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // TODO: comboActive is never getting set to true
  static List<InlineSpan> comboWidget(int comboAmount,
      {bool comboActive = false}) {
    final output = <InlineSpan>[];
    if (!comboActive) {
      return output;
    }

    double fontSize = 15;
    FontWeight fontWeight = FontWeight.normal;
    //TODO: change these sizes
    if (comboAmount >= 50) {
      fontWeight = FontWeight.w900;
      fontSize *= 5;
    } else if (comboAmount >= 30) {
      fontWeight = FontWeight.w700;
      fontSize *= 4;
    } else if (comboAmount >= 20) {
      fontWeight = FontWeight.w700;
      fontSize *= 3;
    } else if (comboAmount >= 10) {
      fontWeight = FontWeight.w700;
      fontSize *= 2;
    } else if (comboAmount >= 5) {
      fontSize *= 1.5;
    }
    // HACKER 7 X C-C-C-COMBO
    // combo amount
    output
      ..add(TextSpan(
          text: ' ${comboAmount.toString()}',
          style: TextStyle(fontSize: fontSize, fontWeight: fontWeight)))
      ..add(TextSpan(
          text: ' X ',
          style: TextStyle(fontSize: fontSize * .7, fontWeight: fontWeight)))
      ..add(TextSpan(
          text: comboActive ? 'HITS' : 'C-C-C-COMBO',
          style: TextStyle(fontSize: fontSize * .7, fontWeight: fontWeight)));
    return output;
    //(comboActive ? "Hits" : "C-C-C-COMBO")
  }

  static List<InlineSpan> messageToWidget(
      MessageSegment segment,
      Settings settings,
      String userNick,
      String senderNick,
      String msgType,
      int comboCount,
      {bool comboActive = false}) {
    final output = <InlineSpan>[];
    if (segment.subSegments.isNotEmpty) {
      for (final val in segment.subSegments) {
        // TODO: get this from the settings class
        var bgColor = Colors.blueGrey; // default colour
        if (userNick == senderNick) {
          bgColor = Colors.amber;
        } else {
          if (userNick.isEmpty) {
            // messsage contains anonymous
          }
        }
        switch (val.type) {
          case 'text':
            output.add(TextSpan(
                text: val.data
                    .toString()
                    .trimLeft(), // TODO: fix whitespace to left when emote in message
                children: messageToWidget(
                    val, settings, userNick, senderNick, msgType, comboCount,
                    comboActive: comboActive),
                style: TextStyle(
                    color: Utilities.flipColor(settings.cardColor,
                        150), // TODO: implement a function for this
                    background: Paint()..color = Colors.transparent)));
            break;
          case 'emote':
            output.add(WidgetSpan(
              child: comboCount >= 10
                  ? kEmotes[val.data]!.img3X
                  : comboCount >= 2
                      ? kEmotes[val.data]!.img2X
                      : kEmotes[val.data]!.img2X,
            ));
            break;
          case 'url':
            //URL styling // there has to be a better way to do this
            var styleURL = TextStyle(
                color: Colors.blue[400],
                decoration: TextDecoration.underline,
                background: Paint()..color = Colors.transparent);

            if (val.getLinkModifier.isNotEmpty) {
              switch (val.getLinkModifier) {
                case 'nsfl':
                  styleURL = TextStyle(
                      color: Colors.blue[400],
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.yellow[400],
                      decorationStyle: TextDecorationStyle.dashed,
                      background: Paint()..color = Colors.transparent);
                  break;
                case 'nsfw':
                  styleURL = TextStyle(
                      color: Colors.blue[400],
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.red[400],
                      decorationStyle: TextDecorationStyle.dashed,
                      background: Paint()..color = Colors.transparent);
                  break;
                case 'loud':
                  styleURL = TextStyle(
                      color: Colors.blue[400],
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blue[400],
                      decorationStyle: TextDecorationStyle.dashed,
                      background: Paint()..color = Colors.transparent);
                  break;
                case 'weeb':
                  styleURL = TextStyle(
                      color: Colors.blue[400],
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.purple[400],
                      decorationStyle: TextDecorationStyle.dashed,
                      background: Paint()..color = Colors.transparent);
                  break;
              }
            }
            //URL styling
            output.add(TextSpan(
              text: val.data.toString(),
              style: styleURL,
              recognizer: TapGestureRecognizer()
                ..onTap = () => {_launchURL(val.data.toString())},
            ));
            break;
          case 'code':
            final TextSpan x = TextSpan(
                text: val.data.toString(),
                style: TextStyle(
                    color: Colors.grey[400],
                    background: Paint()..color = bgColor));
            output.add(x);
            break;
          default:
            output.add(TextSpan(
                children: messageToWidget(
                    val, settings, userNick, senderNick, msgType, comboCount,
                    comboActive: comboActive)));
            break;
        }
      }
      if (comboCount != 1) {
        output.addAll(comboWidget(comboCount));
      }
    }
    return output;
  }
}

class Message {
  Message(
      {required this.type,
      required this.nick,
      required this.timestamp,
      required this.data,
      required this.settings,
      required this.hasKeyword,
      required this.mentioned,
      required this.userNickname,
      required this.messageData,
      this.comboCount = 0});

  factory Message.fromJson(String type, Map<String, dynamic> parsedJson,
      Settings settings, String userNickname,
      {int comboCount = 0}) {
    // ignore escaped backticks
    int _findNextTick(String str) {
      int base = 0;
      while (str.isNotEmpty) {
        final index = str.indexOf('`');
        if (index == -1) {
          return -1;
        } else if (index - 1 >= 0 && str[(index - 1)] == r'\') {
          base += index + 1;
          str = str.substring(index + 1);
        } else {
          return index + base;
        }
      }
      return -1;
    }

    List<MessageSegment> _tokenizeCode(String str) {
      final List<MessageSegment> returnList = <MessageSegment>[];
      final int indexOne = _findNextTick(str);
      if (indexOne != -1) {
        final String beforeFirstTick = str.substring(0, indexOne);
        final String afterFirstTick = str.substring(indexOne + 1);
        final int indexTwo = _findNextTick(afterFirstTick);
        if (indexTwo != -1) {
          final String betweenTicks = afterFirstTick.substring(0, indexTwo);
          final String afterSecondTick = afterFirstTick.substring(indexTwo + 1);
          if (beforeFirstTick.isNotEmpty) {
            returnList.add(MessageSegment('text', beforeFirstTick));
          }
          returnList.add(MessageSegment('code', betweenTicks));
          if (afterSecondTick.isNotEmpty) {
            returnList.addAll(_tokenizeCode(afterSecondTick));
          }
        }
      } else {
        returnList.add(MessageSegment('text', str));
      }
      return returnList;
    }

    void _recursiveCode(MessageSegment base) {
      if (base.type == 'text' && base.subSegments.isEmpty) {
        base
          ..subSegments = _tokenizeCode(base.data)
          ..data = '';
      } else if (base.subSegments.isNotEmpty) {
        base.subSegments.forEach(_recursiveCode);
      }
    }

    void _tokenizeGreentext(MessageSegment base) {
      if (base.type == 'text' && base.subSegments.isEmpty) {
        final RegExp greenReg = RegExp(r'^\s*>.*$');
        if (greenReg.hasMatch(base.data)) {
          base.modifier = 'green';
        }
      } else if (base.subSegments.isNotEmpty) {
        base.subSegments.forEach(_tokenizeGreentext);
      }
    }

    MessageSegment _tokenizeSelf(String str) {
      if (str.length >= 3 && str.substring(0, 3) == '/me') {
        return MessageSegment('self', str.substring(3));
      }
      return MessageSegment('regular', str);
    }

    List<MessageSegment> _tokenizeSpoiler(String str) {
      final List<MessageSegment> returnList = <MessageSegment>[];
      final indexOne = str.indexOf('||');
      if (indexOne != -1) {
        final afterTag = str.substring(indexOne + 2);
        final indexTwo = afterTag.indexOf('||');
        if (indexTwo != -1) {
          final betweenTags = afterTag.substring(0, indexTwo);
          if (RegExp(r'^\s*$').hasMatch(betweenTags)) {
            // checks for only whitespace in string
            returnList.add(
                MessageSegment('text', str.substring(0, indexOne) + '||||'));
          } else {
            returnList
              ..add(MessageSegment('text',
                  str.substring(0, indexOne) + str.substring(0, indexOne)))
              ..add(MessageSegment('spoiler', betweenTags))
              ..addAll(_tokenizeSpoiler(afterTag.substring(indexTwo + 2)));
          }
        }
      } else {
        returnList.add(MessageSegment('text', str));
      }
      return returnList;
    }

    void _tokenizeEmotes(MessageSegment base) {
      final List<MessageSegment> returnList = <MessageSegment>[];
      String tmpBuffer = '';
      bool foundEmote = false;
      if ((base.type == 'text' || base.type == 'spoiler') &&
          base.subSegments.isEmpty) {
        for (final String segment in base.data.split(' ')) {
          final List<String> colonSplit = segment.split(':');
          if (colonSplit.length == 1 && kEmotes.containsKey(segment)) {
            foundEmote = true;
            if (tmpBuffer.isNotEmpty) {
              returnList.add(MessageSegment('text', '$tmpBuffer '));
            }
            tmpBuffer = '';
            returnList.add(MessageSegment('emote', segment));
          } else if (colonSplit.length == 2 &&
              kEmotes.containsKey(colonSplit[0]) &&
              kEmoteModifiers.contains(colonSplit[1])) {
            foundEmote = true;
            if (tmpBuffer.isNotEmpty) {
              returnList.add(MessageSegment('text', '$tmpBuffer '));
            }
            tmpBuffer = '';
            returnList.add(MessageSegment('emote', colonSplit[0],
                modifier: colonSplit[1]));
          } else {
            tmpBuffer += ' $segment';
          }
        }
        if (tmpBuffer.isNotEmpty) {
          returnList.add(MessageSegment('text', '$tmpBuffer '));
        }
        if (foundEmote) {
          base
            ..data = ''
            ..subSegments = returnList;
        }
      } else if (base.subSegments.isNotEmpty) {
        base.subSegments.forEach(_tokenizeEmotes);
      }
    }

    void _tokenizeLinks(MessageSegment base) {
      if ((base.type == 'text' || base.type == 'spoiler') &&
          base.subSegments.isEmpty) {
        // TODO: improve regex
        final RegExp reg = RegExp(
            r'(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,20}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)');
        final List<MessageSegment> newSegments = <MessageSegment>[];
        final Iterable<RegExpMatch> matches = reg.allMatches(base.data);
        if (matches.isNotEmpty) {
          final List<String> withoutUrls = base.data.split(reg);
          for (var i = 0; i < withoutUrls.length; i++) {
            if (withoutUrls[i].isNotEmpty) {
              newSegments.add(MessageSegment('text', withoutUrls[i]));
            }
            if (matches.length > i) {
              newSegments
                  // TODO: no !
                  .add(MessageSegment('url', matches.elementAt(i).group(0)!));
            }
          }
          base
            ..subSegments = newSegments
            ..data = '';
        }
      } else if (base.subSegments.isNotEmpty) {
        base.subSegments.forEach(_tokenizeLinks);
      }
    }

    void _flattenTree(MessageSegment base) {
      if (base.subSegments.isNotEmpty) {
        final List<MessageSegment> newList = [];
        for (final MessageSegment s1 in base.subSegments) {
          _flattenTree(s1);
          if (s1.type == 'text' && s1.subSegments.isNotEmpty) {
            final List<MessageSegment> tmpList = [];
            s1.subSegments.forEach(tmpList.add);
            newList.addAll(tmpList);
          } else {
            newList.add(s1);
          }
        }
        base.subSegments = newList;
      }
    }

    MessageSegment _tokenizeMessage(String message) {
      // get /me
      final MessageSegment base = _tokenizeSelf(message);
      // get spoiler blocks
      final List<MessageSegment> tmp = _tokenizeSpoiler(base.data);
      base
        ..data = ''
        ..subSegments = tmp;
      _recursiveCode(base);
      _tokenizeGreentext(base);
      _tokenizeLinks(base);
      _tokenizeEmotes(base);
      _flattenTree(base);

      return base;
    }

    Set<String> recDetermineLinkModfier(
        MessageSegment message, Set<String> modifierSet) {
      if (message.subSegments.isNotEmpty) {
        for (final subSegment in message.subSegments) {
          if (subSegment.subSegments.isNotEmpty) {
            modifierSet.addAll(
                recDetermineLinkModfier(subSegment, modifierSet)); // rec down

          } else {
            if (subSegment.data.trim().length >= 4) {
              for (final linkMod in linkModifiers) {
                if (subSegment.data.contains(linkMod)) {
                  modifierSet.add(linkMod);
                  break; // we don't need to search any longer as the importance is front loaded
                }
              }
            }
          }
        }
      }
      return modifierSet;
    }

    void _recAttatchLinkModifiers(MessageSegment message, String linkModifier) {
      if (message.subSegments.isNotEmpty) {
        for (final subSegment in message.subSegments) {
          if (subSegment.subSegments.isNotEmpty) {
            _recAttatchLinkModifiers(subSegment, linkModifier); // rec down

          } else {
            if (subSegment.type == 'url') {
              subSegment.linkModifier = linkModifier;
            }
          }
        }
      }
    }

    void _attatchLinkModifiers(MessageSegment message) {
      Set<String> linkModSet = {};
      linkModSet = recDetermineLinkModfier(message, linkModSet);
      for (final mod in linkModifiers) {
        if (linkModSet.contains(mod)) {
          _recAttatchLinkModifiers(message, mod);
          break; // attach only most important modifier
        }
      }
    }

    final String msgString = parsedJson['data'];
    final MessageSegment message = _tokenizeMessage(msgString);
    _attatchLinkModifiers(message);
    bool hasKwrd = false;
    for (final String word in settings.wordsHighlighted) {
      if (msgString.contains(word)) {
        hasKwrd = true;
        break;
      }
    }
    if (hasKwrd) {}

    return Message(
        type: type,
        nick: parsedJson['nick'],
        timestamp: parsedJson['timestamp'] as int,
        data: message,
        messageData: msgString,
        settings: settings,
        hasKeyword: hasKwrd,
        userNickname: userNickname,
        mentioned: msgString.contains(userNickname),
        comboCount: comboCount);
  }

  String messageData;
  String type;
  String nick;
  int timestamp;
  late MessageSegment data;
  late bool hasKeyword;
  late bool mentioned;
  late Settings settings;
  late String userNickname;
  int comboCount;
  List<String> comboUsers = [];
  bool comboActive = false;
  static const List<String> linkModifiers = ['nsfl', 'nsfw', 'loud', 'weeb'];

  @override
  String toString() {
    return messageData;
  }

  bool isOnlyEmote() {
    if (data.type == 'regular' && data.subSegments.length == 1) {
      if (data.subSegments[0].type == 'emote') {
        return true;
      }
    }
    return false;
  }

  bool shouldShow(Settings settings) {
    for (final String each in settings.wordsHidden) {
      if (messageData.toLowerCase().contains(each.toLowerCase())) {
        return false;
      }
    }
    for (final String each in settings.usersIgnored) {
      if (nick.toLowerCase().contains(each.toLowerCase())) {
        return false;
      }
    }
    return true;
  }

  Color getTagColor(Settings settings, String messageNick) {
    int i = 0;
    for (final tag in settings.userTags.keys) {
      if (tag == messageNick) {
        return stringToColor(settings.userTags.values.elementAt(i));
      }
      i++;
    }
    return Colors.transparent;
  }

  Color stringToColor(String colorString) {
    switch (colorString) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'blue':
        return Colors.blue;
      case 'sky':
        return Colors.cyan;
      case 'lime':
        return Colors.lime;
      case 'pink':
        return Colors.pink;
      case 'black':
        return Colors.grey;
      default:
        return Colors.transparent;
    }
  }

  String readTimestamp() {
    if (timestamp != 0) {
      final DateTime d =
          DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
      String hour = d.hour.toString();
      String minute = d.minute.toString();
      if (hour.length == 1) {
        hour = '0$hour';
      }
      if (minute.length == 1) {
        minute = '0$minute';
      }
      return '$hour:$minute';
    }
    return '';
  }
}

class MessageSegment {
  MessageSegment(this.type, this.data,
      {this.modifier = '', this.subSegments = const []});

  String type;
  String data;
  String modifier;
  String linkModifier = '';
  String get getLinkModifier => linkModifier;
  List<MessageSegment> subSegments;

  @override
  String toString() {
    return toStringIndent(1);
  }

  String toStringIndent(int depth) {
    String segs = '';
    if (subSegments.isNotEmpty) {
      for (final MessageSegment segment in subSegments) {
        segs += '    ' * depth + segment.toStringIndent(depth + 1) + '\n';
      }
    }
    final String dataS = data.isNotEmpty ? ', data: "$data" ' : '';
    final String mod = modifier.isNotEmpty ? ', mod: $modifier' : '';
    final String newline =
        segs.isNotEmpty ? '\n' + segs + '    ' * (depth - 1) + ']}' : ']}';
    return '{type: ' + type + mod + dataS + ', children: [' + newline;
  }

  String getData() {
    return data;
  }
}
