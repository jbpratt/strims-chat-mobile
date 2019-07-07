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
        var msg = _messages[index];

        var output = <InlineSpan>[];

        msg.data.forEach((val) {
          // if type text, render text text span
          // if type emote, render img span
          // output.add(x);

          switch (val.type) {
            case "text":
              var x = TextSpan(
                  text: val.data.toString(),
                  style: TextStyle(color: Colors.grey[400]));
              output.add(x);
              break;
            case "emote":
              var x = Image(
                image: AssetImage('assets/${val.data}.png'), // not the best way
              );
              output.add(WidgetSpan(child: x));
              break;
            default:
              print(val.type);
          }
        });
        var nick = TextSpan(
            text: "\n" + msg.readTimestamp() + " " + msg.nick,
            style: TextStyle(color: Colors.grey[600]));
        output.add(nick);
        // var lt = ListTile(
        //   subtitle: Text(msg.readTimestamp() + " " + msg.nick,
        //       style: TextStyle(
        //         color: Colors.grey[600],
        //       )),
        // );
        return Card(
          color: Colors.grey[900],
          child: Text.rich(TextSpan(
              children:
                  output)), //_MessageListItem(_messages[index]), // WidgetSpan()
        );
      },
    );
  }
}

// can be deleted, i like the styling of 
// the listtile tho
class _MessageListItem extends ListTile {
  _MessageListItem(Message msg)
      : super(
            dense: true,
            title: Text(msg.data.toString(),
                style: TextStyle(
                  color: Colors.grey[400],
                )),
            subtitle: Text(msg.readTimestamp() + " " + msg.nick,
                style: TextStyle(
                  color: Colors.grey[600],
                )),
            onTap: () {});
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
    List<MessageSegment> _tokenizeMsg(String data) {
      List<MessageSegment> tmpData = [];
      String tmpBuffer = "";
      if (data == null) {
        return tmpData;
      }

      for (String segment in data.split(" ")) {
        List<String> colonSplit = segment.split(":");
        if (colonSplit.length == 1 && kEmotes.containsKey(segment)) {
          tmpData.add(new MessageSegment("text", tmpBuffer + " "));
          tmpBuffer = "";
          tmpData.add(new MessageSegment("emote", segment));
        } else if (colonSplit.length == 2 &&
            kEmotes.containsKey(colonSplit[0]) &&
            kEmoteModifiers.contains(colonSplit[1])) {
          tmpData.add(new MessageSegment("text", tmpBuffer + " "));
          tmpBuffer = "";
          tmpData.add(new MessageSegment("emote", colonSplit[0],
              modifier: colonSplit[1]));
        } else {
          tmpBuffer += " " + segment;
        }
      }

      if (tmpBuffer != "") {
        tmpData.add(new MessageSegment("text", tmpBuffer + " "));
      }

      return tmpData;
    }

    List<MessageSegment> message = _tokenizeMsg(parsedJson['data']);
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

  @override
  String toString() {
    return data;
    //return "{ type: \"" + type + "\", data: \"" + data + "\" }";
  }

  MessageSegment(this.type, this.data, {this.modifier});
}