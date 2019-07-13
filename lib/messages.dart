import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:majora/emotes.dart';

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
        Message msg = _messages[index];

        var output = <InlineSpan>[];

        var ts = TextSpan(
            text: msg.readTimestamp() + " ",
            style: TextStyle(color: Colors.blueGrey[700]));

        output.add(ts);

        var nick;
        switch (msg.type) {
          case "PRIVMSG":
            nick = TextSpan(
                text: msg.nick + " whispered: ",
                style: TextStyle(background: Paint()..color = Colors.blue[400]));
            break;
          default:
            nick = TextSpan(
                text: msg.nick + ": ", style: TextStyle(background: Paint()..color = Colors.grey[900]));
        }

        output.add(nick);

        msg.data.forEach((val) {
          // if type text, render text text span
          // if type emote, render img span
          // output.add(x);
          switch (val.type) {
            case "text":
              TextSpan x = TextSpan(
                  text: val.data.toString(),
                  style: TextStyle(color: Colors.grey[400]));
              output.add(x);
              break;
            case "emote":
              Image x = Image(
                image: AssetImage('assets/${val.data}.png'), // not the best way
              );
              output.add(WidgetSpan(child: x));
              break;
            default:
              print(val.type);
          }
        });

        return Card(
            color: Colors.transparent,
            child: Text.rich(TextSpan(children: output)));
      },
    );
  }
}

class Message {
  String type;
  String nick;
  int timestamp;
  List<MessageSegment> data;

  Message({this.type, this.nick, this.timestamp, this.data});

  String readTimestamp() {
    if (this.timestamp != 0) {
      DateTime d =
          new DateTime.fromMillisecondsSinceEpoch(this.timestamp, isUtc: true);
      return d.hour.toString() + ":" + d.minute.toString();
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
        } else if (str[(index - 1)] == '\\') {
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
          String afterSecondTick = afterick.substring(indexTwo + 1);
          returnList = (beforeFirstTick.length > 0)
              ? returnList = [
                  new MessageSegment('text', beforeFirstTick),
                  new MessageSegment('code', betweenTicks)
                ]
              : returnList = [new MessageSegment('code', betweenTicks)];
          if (afterSecondTick.length > 0) {
            returnList.addAll(_tokenizeCode(afterSecondTick));
          }
        }
      } else {
        returnList.add(new MessageSegment('text', str));
      }
      return returnList;
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

    List<MessageSegment> _tokenizeEmotes(String data) {
      List<MessageSegment> returnList = new List<MessageSegment>();
      String tmpBuffer = "";

      for (String segment in data.split(" ")) {
        List<String> colonSplit = segment.split(":");
        if (colonSplit.length == 1 && kEmotes.containsKey(segment)) {
          returnList.add(new MessageSegment("text", tmpBuffer + " "));
          tmpBuffer = "";
          returnList.add(new MessageSegment("emote", segment));
        } else if (colonSplit.length == 2 &&
            kEmotes.containsKey(colonSplit[0]) &&
            kEmoteModifiers.contains(colonSplit[1])) {
          returnList.add(new MessageSegment("text", tmpBuffer + " "));
          tmpBuffer = "";
          returnList.add(new MessageSegment("emote", colonSplit[0],
              modifier: colonSplit[1]));
        } else {
          tmpBuffer += " " + segment;
        }
      }

      if (tmpBuffer != "") {
        returnList.add(new MessageSegment("text", tmpBuffer + " "));
      }

      return returnList;
    }

    List<MessageSegment> _tokenizeLinks(String str) {
      List<MessageSegment> returnList = new List<MessageSegment>();
      RegExp reg = new RegExp(
          r'(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,20}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)');
      Iterable<RegExpMatch> matches = reg.allMatches(str);
      List<String> withoutUrls = str.split(reg);
      for (var i = 0; i < withoutUrls.length; i++) {
        returnList.add(new MessageSegment('text', withoutUrls[i]));
        if (matches.length > i) {
          returnList
              .add(new MessageSegment('url', matches.elementAt(i).group(0)));
        }
      }
    }

    List<MessageSegment> message = _tokenizeEmotes(parsedJson['data']);
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
  String modifier;
  List<MessageSegment> subSegemnts;

  @override
  String toString() {
    String segs;
    for (MessageSegment segment in subSegemnts) {
      segs += "\n" + segment.toString();
    }
    return "{ type: \"" +
        type +
        "\", data: \"" +
        data +
        "modifier: \"" +
        modifier +
        "segments: \"" +
        segs +
        "}";
  }

  String getData() {
    return data;
  }

  MessageSegment(this.type, this.data, {this.modifier, this.subSegemnts});
}
