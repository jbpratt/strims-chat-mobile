import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'chat.dart';

void main() => runApp(App());

class App extends StatelessWidget {

  @override
  Widget build(BuildContext context) { // TODO: add routes https://flutter.dev/docs/cookbook/navigation/navigate-with-arguments#3-register-the-widget-in-the-routes-table
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.grey[800],
        accentColor: Colors.orange[700],
      ),
      home: new ChatPage(),
    );
  }
}
