import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Chatter {
  String nick;
  List<String> features;

  Chatter({nick, features});

  factory Chatter.fromJson(Map parsedJson) {
    return Chatter(nick: parsedJson['nick'], features: parsedJson['features']);
  }
}

List<Chatter> buildChatterList(String input) {
  List<dynamic> userList = jsonDecode(input)['users'];
  List<Chatter> output = [];
  for (int i = 0; i < userList.length; i++) {
    Chatter newChatter = Chatter();
    newChatter.nick = userList[i]['nick'];
    output.add(newChatter);
  }

  // sort chatter list
  output.sort((a, b) => a.nick.compareTo(b.nick));
  return output;
}

int getConnectionCount(String input) {
  return jsonDecode(input)['connectioncount'];
}

class ChatterListRoute extends StatelessWidget {
  final List<Chatter> _chatterList;

  ChatterListRoute(this._chatterList);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Chatters'),
        ),
        body: ListView(
          children: <Widget>[ChatterList(_chatterList)],
        ));
  }
}

class ChatterList extends StatelessWidget {
  final ScrollController _controller = ScrollController();
  final List<Chatter> _chatters;

  ChatterList(this._chatters);
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        controller: _controller,
        itemCount: _chatters.length,
        itemBuilder: (BuildContext ctx, int index) {
          return Card(
            color: Colors.grey[900],
            child: _ChatterListItem(_chatters[index]),
          );
        });
  }
}

class _ChatterListItem extends ListTile {
  _ChatterListItem(Chatter chtr)
      : super(dense: true, title: Text(chtr.nick), onTap: () {});
}
