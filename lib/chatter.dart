import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ws/types.dart';

class ChatterListRoute extends StatelessWidget {
  const ChatterListRoute(this._chatterList, {Key? key}) : super(key: key);

  final Chatters _chatterList;

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
  final Chatters _chatters;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        controller: _controller,
        itemCount: _chatters.users.length,
        itemBuilder: (BuildContext ctx, int index) {
          return Card(
            color: Colors.grey[900],
            child: _ChatterListItem(_chatters.users[index]),
          );
        });
  }
}

class _ChatterListItem extends ListTile {
  _ChatterListItem(User chtr)
      : super(dense: true, title: Text(chtr.nick), onTap: () {});
}
