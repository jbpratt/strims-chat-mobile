import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings.dart';
import 'emotes.dart';
import 'utilities.dart';

class MessageList extends StatefulWidget {
  final List<Message> _messages;
  final String _userNickname;

  MessageList(this._messages, this._userNickname);

  @override
  _MessageListState createState() => _MessageListState(_messages);
}

class _MessageListState extends State<MessageList> {
  final ScrollController _controller = ScrollController();
  // QUESTION: should this be private?
  List<Message> messages;
  Settings _settings;

  _MessageListState(this.messages);
  @override
  Widget build(BuildContext context) {
    this._settings = Provider.of<SettingsNotifier>(context).settings;
    this.messages.retainWhere((message) => message
        .shouldShow(this._settings)); // remove all hidden ignored messages
    return Container(
        color: _settings.bgColor,
        child: ListView.builder(
          shrinkWrap: true,
          reverse: true,
          controller: _controller,
          itemCount: widget._messages.length,
          itemBuilder: (BuildContext ctx, int index) {
            Message msg = widget._messages[index];
            return Card(
                color: _settings.cardColor,
                // TODO: do this properly
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: new BorderRadius.all(Radius.circular(4)),
                      gradient: new LinearGradient(stops: [
                        0.02,
                        0.02
                      ], colors: [
                        msg.getTagColor(this._settings, msg.nick),
                        (msg.mentioned || msg.hasKeyword)
                            ? Color.fromARGB(100, 1, 37, 70)
                            : _settings.cardColor
                      ]),
                    ),
                    child: _MessageListItem(
                        msg, this._settings, widget._userNickname)));
          },
        ));
  }
}

class _MessageListItem extends ListTile {
  final Settings _settings;
  final String _userNickname;
  final Message _msg;
  _MessageListItem(this._msg, this._settings, this._userNickname) : super();

  @override
  Widget build(BuildContext context) {
    return ListTile(
        dense: true,
        title: Padding(
          padding: EdgeInsets.only(
            top: 8,
            bottom: 8,
          ),
          child: Text.rich(
            TextSpan(
              children: messageToWidget(_msg.data, _settings, _userNickname,
                  _msg.nick, _msg.type, _msg.comboCount, _msg.comboActive),
            ), // colour here somehow
          ),
        ),
        subtitle: _msg.comboCount == 1
            ? Padding(
                padding: EdgeInsets.only(
                  bottom: 8,
                ),
                child: Text.rich(TextSpan(
                    text: _msg.type == "PRIVMSG"
                        ? _msg.nick + " whispered"
                        : _msg.nick,
                    style: TextStyle(
                      backgroundColor: _msg.type == "PRIVMSG"
                          ? Utilities.flipColor(_settings.cardColor, 50)
                          : null,
                      fontStyle:
                          _msg.type == "PRIVMSG" ? FontStyle.italic : null,
                      color: _msg.type == "PRIVMSG"
                          ? Utilities.flipColor(
                              Utilities.flipColor(_settings.cardColor, 50), 100)
                          : Utilities.flipColor(_settings.cardColor, 100),
                    ))))
            : null,
        onTap: () {});
  }

  static _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static comboWidget(int comboAmount, bool comboActive) {
    var output = <InlineSpan>[];
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
    TextSpan count = TextSpan(
        text: " " + comboAmount.toString(),
        style: TextStyle(fontSize: fontSize, fontWeight: fontWeight));
    output.add(count);
    TextSpan x = TextSpan(
        text: " X ",
        style: TextStyle(fontSize: fontSize * .7, fontWeight: fontWeight));
    output.add(x);
    TextSpan name = TextSpan(
        text: comboActive ? "HITS" : "C-C-C-COMBO",
        style: TextStyle(fontSize: fontSize * .7, fontWeight: fontWeight));
    output.add(name);
    return output;
    //(comboActive ? "Hits" : "C-C-C-COMBO")
  }

  static messageToWidget(
      MessageSegment segment,
      Settings settings,
      String userNick,
      String senderNick,
      String msgType,
      int comboCount,
      bool comboActive) {
    var output = <InlineSpan>[];
    if (segment.subSegements != null) {
      segment.subSegements.forEach((val) {
        // TODO: get this from the settings class
        var bgColor = Colors.blueGrey; // default colour

        if (userNick == senderNick) {
          bgColor = Colors.amber;
        } else {
          if (userNick == null || userNick.isEmpty) {
            // messsage contains anonymous
          }
        }
        switch (val.type) {
          case "text":
            TextSpan x = TextSpan(
                text: val.data
                    .toString()
                    .trimLeft(), // TODO: fix whitespace to left when emote in message
                children: messageToWidget(val, settings, userNick, senderNick,
                    msgType, comboCount, comboActive),
                style: TextStyle(
                    color: Utilities.flipColor(settings.cardColor,
                        150), // TODO: implement a function for this
                    background: Paint()..color = Colors.transparent));
            output.add(x);
            break;
          case "emote":
            output.add(WidgetSpan(
              child: comboCount >= 10
                  ? kEmotes["${val.data}"].img3X
                  : comboCount >= 2
                      ? kEmotes["${val.data}"].img2X
                      : kEmotes["${val.data}"].img,
            ));
            break;
          case "url":
            //URL styling // there has to be a better way to do this
            var styleURL = TextStyle(
                color: Colors.blue[400],
                decoration: TextDecoration.underline,
                background: Paint()..color = Colors.transparent);

            if (val.getLinkModifier != null) {
              switch (val.getLinkModifier) {
                case "nsfl":
                  styleURL = TextStyle(
                      color: Colors.blue[400],
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.yellow[400],
                      decorationStyle: TextDecorationStyle.dashed,
                      background: Paint()..color = Colors.transparent);
                  break;
                case "nsfw":
                  styleURL = TextStyle(
                      color: Colors.blue[400],
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.red[400],
                      decorationStyle: TextDecorationStyle.dashed,
                      background: Paint()..color = Colors.transparent);
                  break;
                case "loud":
                  styleURL = TextStyle(
                      color: Colors.blue[400],
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blue[400],
                      decorationStyle: TextDecorationStyle.dashed,
                      background: Paint()..color = Colors.transparent);
                  break;
                case "weeb":
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
            TextSpan x = TextSpan(
              text: val.data.toString(),
              style: styleURL,
              recognizer: new TapGestureRecognizer()
                ..onTap = () => {_launchURL(val.data.toString())},
            );
            output.add(x);
            break;
          case "code":
            TextSpan x = TextSpan(
                text: val.data.toString(),
                style: TextStyle(
                    color: Colors.grey[400],
                    background: Paint()..color = bgColor));
            output.add(x);
            break;
          default:
            TextSpan x = TextSpan(
                children: messageToWidget(val, settings, userNick, senderNick,
                    msgType, comboCount, comboActive));
            output.add(x);
            break;
        }
      });
      if (comboCount != 1) {
        output.addAll(comboWidget(comboCount, comboActive));
      }
      return output;
    }
  }
}

class Message {
  String messageData;
  String type;
  String nick;
  int timestamp;
  MessageSegment data;
  bool hasKeyword;
  bool mentioned;
  Settings settings;
  String userNickname;
  int comboCount = 1;
  List<String> comboUsers;
  bool comboActive;
  static const List linkModifiers = ['nsfl', 'nsfw', 'loud', 'weeb'];
  Message(
      {this.type,
      this.nick,
      this.timestamp,
      this.data,
      this.settings,
      this.hasKeyword,
      this.mentioned,
      this.userNickname,
      this.messageData});

  @override
  String toString() {
    return messageData;
  }

  bool isOnlyEmote() {
    if (this.data.type == "regular" && this.data.subSegemnts.length == 1) {
      if (this.data.subSegements[0].type == "emote") {
        return true;
      }
    }
    return false;
  }

  bool shouldShow(Settings settings) {
    for (String each in settings.wordsHidden) {
      if (this.messageData.toLowerCase().contains(each.toLowerCase())) {
        return false;
      }
    }
    for (String each in settings.usersIgnored) {
      if (this.nick.toLowerCase().contains(each.toLowerCase())) {
        return false;
      }
    }
    return true;
  }

  Color getTagColor(Settings settings, String messageNick) {
    int i = 0;
    for (var tag in settings.userTags.keys) {
      if (tag == messageNick) {
        return stringToColor(settings.userTags.values.elementAt(i));
      }
      i++;
    }
    return Colors.transparent;
  }

  Color stringToColor(String colorString) {
    switch (colorString) {
      case "green":
        return Colors.green;
        break;
      case "yellow":
        return Colors.yellow;
        break;
      case "orange":
        return Colors.orange;
        break;
      case "red":
        return Colors.red;
        break;
      case "purple":
        return Colors.purple;
        break;
      case "blue":
        return Colors.blue;
        break;
      case "sky":
        return Colors.cyan;
        break;
      case "lime":
        return Colors.lime;
        break;
      case "pink":
        return Colors.pink;
        break;
      case "black":
        return Colors.grey;
        break;
    }
    return Colors.transparent;
  }

  String readTimestamp() {
    if (this.timestamp != 0) {
      DateTime d =
          new DateTime.fromMillisecondsSinceEpoch(this.timestamp, isUtc: true);
      String hour = d.hour.toString();
      String minute = d.minute.toString();
      if (hour.length == 1) {
        hour = "0" + hour;
      }
      if (minute.length == 1) {
        minute = "0" + minute;
      }
      return "$hour:$minute";
    }
    return "";
  }

  factory Message.fromJson(
      String type, Map parsedJson, Settings settings, String userNickname) {
    // ignore escaped backticks
    int _findNextTick(String str) {
      int base = 0;
      while (str.length > 0) {
        var index = str.indexOf('`');
        if (index == -1) {
          return -1;
        } else if (index - 1 >= 0 && str[(index - 1)] == '\\') {
          base += index + 1;
          str = str.substring(index + 1);
        } else {
          return index + base;
        }
      }
      return -1;
    }

    List<MessageSegment> _tokenizeCode(String str) {
      List<MessageSegment> returnList = new List<MessageSegment>();
      int indexOne = _findNextTick(str);
      if (indexOne != -1) {
        String beforeFirstTick = str.substring(0, indexOne);
        String afterFirstTick = str.substring(indexOne + 1);
        int indexTwo = _findNextTick(afterFirstTick);
        if (indexTwo != -1) {
          String betweenTicks = afterFirstTick.substring(0, indexTwo);
          String afterSecondTick = afterFirstTick.substring(indexTwo + 1);
          if (beforeFirstTick.length > 0) {
            returnList.add(new MessageSegment('text', beforeFirstTick));
          }
          returnList.add(new MessageSegment('code', betweenTicks));
          if (afterSecondTick.length > 0) {
            returnList.addAll(_tokenizeCode(afterSecondTick));
          }
        }
      } else {
        returnList.add(new MessageSegment('text', str));
      }
      return returnList;
    }

    _recursiveCode(MessageSegment base) {
      if (base.type == 'text' && base.subSegemnts == null) {
        base.subSegemnts = _tokenizeCode(base.data);
        base.data = '';
      } else if (base.subSegemnts != null) {
        for (MessageSegment segment in base.subSegemnts) {
          _recursiveCode(segment);
        }
      }
    }

    _tokenizeGreentext(MessageSegment base) {
      if (base.type == "text" && base.subSegemnts == null) {
        RegExp greenReg = new RegExp(r'^\s*>.*$');
        if (greenReg.hasMatch(base.data)) {
          base.modifier = 'green';
        }
      } else if (base.subSegemnts != null) {
        for (MessageSegment segment in base.subSegemnts) {
          _tokenizeGreentext(segment);
        }
      }
    }

    MessageSegment _tokenizeSelf(String str) {
      if (str.length >= 3 && str.substring(0, 3) == '/me') {
        return new MessageSegment('self', str.substring(3));
      }
      return new MessageSegment('regular', str);
    }

    List<MessageSegment> _tokenizeSpoiler(String str) {
      List<MessageSegment> returnList = new List<MessageSegment>();
      var indexOne = str.indexOf('||');
      if (indexOne != -1) {
        var afterTag = str.substring(indexOne + 2);
        var indexTwo = afterTag.indexOf('||');
        if (indexTwo != -1) {
          var betweenTags = afterTag.substring(0, indexTwo);
          if (new RegExp(r'^\s*$').hasMatch(betweenTags)) {
            // checks for only whitespace in string
            returnList.add(new MessageSegment(
                'text', str.substring(0, indexOne) + '||||'));
          } else {
            returnList.add(new MessageSegment('text',
                str.substring(0, indexOne) + str.substring(0, indexOne)));
            returnList.add(new MessageSegment('spoiler', betweenTags));
            returnList
                .addAll(_tokenizeSpoiler(afterTag.substring(indexTwo + 2)));
          }
        }
      } else {
        returnList.add(new MessageSegment('text', str));
      }
      return returnList;
    }

    _tokenizeEmotes(MessageSegment base) {
      List<MessageSegment> returnList = new List<MessageSegment>();
      String tmpBuffer = "";
      bool foundEmote = false;
      if ((base.type == 'text' || base.type == 'spoiler') &&
          base.subSegemnts == null) {
        for (String segment in base.data.split(" ")) {
          List<String> colonSplit = segment.split(":");
          if (colonSplit.length == 1 && kEmotes.containsKey(segment)) {
            foundEmote = true;
            if (tmpBuffer.length > 0) {
              returnList.add(new MessageSegment("text", tmpBuffer + " "));
            }
            tmpBuffer = "";
            returnList.add(new MessageSegment("emote", segment));
          } else if (colonSplit.length == 2 &&
              kEmotes.containsKey(colonSplit[0]) &&
              kEmoteModifiers.contains(colonSplit[1])) {
            foundEmote = true;
            if (tmpBuffer.length > 0) {
              returnList.add(new MessageSegment("text", tmpBuffer + " "));
            }
            tmpBuffer = "";
            returnList.add(new MessageSegment("emote", colonSplit[0],
                modifier: colonSplit[1]));
          } else {
            tmpBuffer += " " + segment;
          }
        }
        if (tmpBuffer.length > 0) {
          returnList.add(new MessageSegment("text", tmpBuffer + " "));
        }
        if (foundEmote) {
          base.data = "";
          base.subSegemnts = returnList;
        }
      } else if (base.subSegemnts != null) {
        for (MessageSegment segment in base.subSegemnts) {
          _tokenizeEmotes(segment);
        }
      }
    }

    _tokenizeLinks(MessageSegment base) {
      if ((base.type == 'text' || base.type == 'spoiler') &&
          base.subSegemnts == null) {
        // TODO: improve regex
        RegExp reg = new RegExp(
            r'(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,20}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)');
        List<MessageSegment> newSegments = new List<MessageSegment>();
        Iterable<RegExpMatch> matches = reg.allMatches(base.data);
        if (matches.length > 0) {
          List<String> withoutUrls = base.data.split(reg);
          for (var i = 0; i < withoutUrls.length; i++) {
            if (withoutUrls[i].length > 0) {
              newSegments.add(new MessageSegment('text', withoutUrls[i]));
            }
            if (matches.length > i) {
              newSegments.add(
                  new MessageSegment('url', matches.elementAt(i).group(0)));
            }
          }
          base.subSegemnts = newSegments;
          base.data = "";
        }
      } else if (base.subSegemnts != null) {
        for (MessageSegment segment in base.subSegemnts) {
          _tokenizeLinks(segment);
        }
      }
    }

    _flattenTree(MessageSegment base) {
      if (base.subSegemnts != null) {
        List<MessageSegment> newList = [];
        for (MessageSegment s1 in base.subSegemnts) {
          _flattenTree(s1);
          if (s1.type == 'text' &&
              s1.modifier == null &&
              s1.subSegemnts != null) {
            bool canFlatten = true;
            List<MessageSegment> tmpList = [];
            for (MessageSegment s2 in s1.subSegemnts) {
              tmpList.add(s2);
            }
            if (canFlatten) {
              newList.addAll(tmpList);
            } else {
              newList.add(s1);
            }
          } else {
            newList.add(s1);
          }
        }
        base.subSegemnts = newList;
      }
    }

    MessageSegment _tokenizeMessage(String message) {
      // get /me
      MessageSegment base = _tokenizeSelf(message);
      // get spoiler blocks
      List<MessageSegment> tmp = _tokenizeSpoiler(base.data);
      base.data = '';
      base.subSegemnts = tmp;
      _recursiveCode(base);
      _tokenizeGreentext(base);
      _tokenizeLinks(base);
      _tokenizeEmotes(base);
      _flattenTree(base);

      return base;
    }

    Set<String> recDetermineLinkModfier(
        MessageSegment message, Set<String> modifierSet) {
      if (message.subSegemnts != null) {
        message.subSegemnts.forEach((subSegment) {
          if (subSegment.subSegements != null) {
            modifierSet.addAll(
                recDetermineLinkModfier(subSegment, modifierSet)); // rec down

          } else {
            if (subSegment.data.trim().length >= 4) {
              for (var linkMod in linkModifiers) {
                if (subSegment.data.contains(linkMod)) {
                  modifierSet.add(linkMod);
                  break; // we don't need to search any longer as the importance is front loaded
                }
              }
            }
          }
        });
      }
      return modifierSet;
    }

    _recAttatchLinkModifiers(MessageSegment message, String linkModifier) {
      if (message.subSegemnts != null) {
        message.subSegemnts.forEach((subSegment) {
          if (subSegment.subSegements != null) {
            _recAttatchLinkModifiers(subSegment, linkModifier); // rec down

          } else {
            if (subSegment.type == "url") {
              subSegment.linkModifier = linkModifier;
            }
          }
        });
      }
    }

    _attatchLinkModifiers(MessageSegment message) {
      Set<String> linkModSet = new Set();
      linkModSet = recDetermineLinkModfier(message, linkModSet);
      for (var mod in linkModifiers) {
        if (linkModSet.contains(mod)) {
          _recAttatchLinkModifiers(message, mod);
          break; // attach only most important modifier
        }
      }
    }

    String msgString = parsedJson['data'];
    MessageSegment message = _tokenizeMessage(msgString);
    _attatchLinkModifiers(message);
    bool hasKwrd = false;
    for (String word in settings.wordsHighlighted) {
      if (msgString.contains(word)) {
        hasKwrd = true;
        break;
      }
    }
    if (hasKwrd) {}

    return Message(
        messageData: msgString,
        hasKeyword: hasKwrd,
        userNickname: userNickname,
        mentioned: msgString.contains(userNickname),
        type: type,
        nick: parsedJson['nick'],
        timestamp: parsedJson['timestamp'] as int,
        data: message);
  }
}

class MessageSegment {
  bool containsUsername;
  String type;
  String data;
  String linkModifier;
  String modifier;
  List<MessageSegment> subSegemnts;
  get getLinkModifier => linkModifier;
  get subSegements => subSegemnts;

  @override
  String toString() {
    return toStringIndent(1);
  }

  String toStringIndent(int depth) {
    String segs = '';
    if (subSegemnts != null) {
      for (MessageSegment segment in subSegemnts) {
        segs += '    ' * depth + segment.toStringIndent(depth + 1) + '\n';
      }
    }
    String dataS = (data.length > 0) ? ', data: "' + data + '" ' : '';
    String mod = (modifier != null) ? ', mod: ' + modifier : '';
    String newline =
        (segs.length > 0) ? '\n' + segs + '    ' * (depth - 1) + ']}' : ']}';
    return '{type: ' + type + mod + dataS + ', children: [' + newline;
  }

  String getData() {
    return data;
  }

  MessageSegment(this.type, this.data, {this.modifier, this.subSegemnts});
}
