import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Chatter {
  Chatter(this.nick, {this.features = const <String>[]});

  factory Chatter.fromJson(Map<String, dynamic> parsedJson) {
    return Chatter(parsedJson['nick'], features: parsedJson['features']);
  }

  String nick;
  List<String> features;
}

List<Chatter> buildChatterList(String input) {
  final List<dynamic> userList = jsonDecode(input)['users'];
  final List<Chatter> output = [];
  for (int i = 0; i < userList.length; i++) {
    output.add(Chatter(userList[i]['nick']));
  }

  // sort chatter list
  output.sort((a, b) => a.nick.compareTo(b.nick));
  return output;
}

int getConnectionCount(String input) {
  return jsonDecode(input)['connectioncount'];
}

class ChatterListRoute extends StatelessWidget {
  const ChatterListRoute(this._chatterList, {Key? key}) : super(key: key);

  final List<Chatter> _chatterList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Chatters'),
        ),
        body: ListView(
          children: <Widget>[ChatterList(_chatterList)],
        ));
  }
}

class ChatterList extends StatelessWidget {
  ChatterList(this._chatters, {Key? key}) : super(key: key);

  final ScrollController _controller = ScrollController();
  final List<Chatter> _chatters;

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
