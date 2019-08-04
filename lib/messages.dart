import 'package:flutter/cupertino.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:majora/settings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:majora/emotes.dart';

class MessageList extends StatelessWidget {
  final ScrollController _controller = ScrollController();
  final List<Message> _messages;
  final String _userNickname;
  Settings _settings; // < imported from ?

  MessageList(this._messages, this._settings, this._userNickname) {
    // print("miyanobird:" + this._settings.toggles.toString()); // TODO: remove
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.grey,
        child: ListView.builder(
          shrinkWrap: true,
          reverse: true,
          controller: _controller,
          itemCount: _messages.length,
          itemBuilder: (BuildContext ctx, int index) {
            Message msg = _messages[index];

            var bgColour = Colors.pink;

            return Card(
                color: (msg.type == "PRIVMSG"
                    ? _settings.privateCardColor
                    : _settings.cardColor),
                // TODO: do this properly
                child: _MessageListItem(msg, this._settings,
                    _userNickname)); //Text.rich(TextSpan(children: output)));
          },
        ));
  }
}

class _MessageListItem extends ListTile {
  Settings _settings;
  String _userNickname;
  _MessageListItem(Message msg, this._settings, this._userNickname)
      : super(
            dense: true,
            title: Text.rich(
              TextSpan(
                  children: messageToWidget(
                msg.data,
                _settings,
                _userNickname,
                msg.nick,
                msg.type,
              )), // colour here somehow
            ),
            subtitle:
                Text(msg.type == "PRIVMSG" ? msg.nick + " whispered" : msg.nick,
                    style: TextStyle(
                      color: flipColor(
                          msg.type == "PRIVMSG"
                              ? _settings.privateCardColor
                              : _settings.cardColor,
                          100),
                    )),
            trailing: Icon(
              Icons.more_vert,
              color: flipColor(
                  msg.type == "PRIVMSG"
                      ? _settings.privateCardColor
                      : _settings.cardColor,
                  100),
            ),
            onTap: () {});

  static _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static Color flipColor(Color color, int offset) {
    int r = color.red;
    int g = color.green;
    int b = color.blue;
    double lum = color.computeLuminance();
    if (lum > 0.5) {
      offset *= -1;
    }

    int newR = min(max(0, r + offset), 255);
    int newG = min(max(0, g + offset), 255);
    int newB = min(max(0, b + offset), 255);
    Color newColor = Color.fromARGB(255, newR, newG, newB);

    return newColor;
  }

  static messageToWidget(MessageSegment segment, Settings settings,
      String userNick, String senderNick, String msgType) {
    var output = <InlineSpan>[];
    if (segment.subSegements != null) {
      segment.subSegements.forEach((val) {
        // TODO: get this from the settings class
        var bgColour = Colors.blueGrey; // default colour

        if (userNick == senderNick) {
          bgColour = Colors.amber;
        } else {
          if (userNick == null || userNick.isEmpty) {
            // messsage contains anonymous
          }
        }
        switch (val.type) {
          case "text":
            TextSpan x = TextSpan(
                text: val.data.toString(),
                children: messageToWidget(
                    val, settings, userNick, senderNick, msgType),
                style: TextStyle(
                    color: flipColor(
                        msgType == "PRIVMSG"
                            ? settings.privateCardColor
                            : settings.cardColor,
                        150), // TODO: implement a function for this
                    background: Paint()..color = Colors.transparent));
            output.add(x);
            break;
          case "emote":
            AssetImage img = AssetImage('assets/${val.data}');
            Image x = Image(
              image: img,
              height: 32,
            );
            output.add(WidgetSpan(
              child: x,
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
                    background: Paint()..color = bgColour));
            output.add(x);
            break;
          default:
            TextSpan x = TextSpan(
                children: messageToWidget(
                    val, settings, userNick, senderNick, msgType));
            output.add(x);
            break;
        }
      });
      return output;
    }
  }
}

class Message {
  String type;
  String nick;
  int timestamp;
  MessageSegment data;
  bool mentioned;
  static const List linkModifiers = ['nsfl', 'nsfw', 'loud', 'weeb'];
  Message({this.type, this.nick, this.timestamp, this.data});

  @override
  String toString() {
    return _recReturnMessageAsString(this.data);
  }

  String _recReturnMessageAsString(MessageSegment message) {
    String messageAsString = "";
    if (message.subSegemnts != null) {
      message.subSegemnts.forEach((subSegment) {
        if (subSegment.subSegements != null) {
          messageAsString += _recReturnMessageAsString(subSegment); // rec down

        } else {
          if (subSegment.data != null) {
            messageAsString += subSegment.data;
          }
        }
      });
    }
    return messageAsString;
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

  factory Message.fromJson(String type, Map parsedJson) {
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

    bool _containsUserNickname(MessageSegment message, String userNickname) {}

    MessageSegment message = _tokenizeMessage(parsedJson['data']);
    _attatchLinkModifiers(message);
    return Message(
        type: type,
        nick: parsedJson['nick'],
        timestamp: parsedJson['timestamp'],
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
