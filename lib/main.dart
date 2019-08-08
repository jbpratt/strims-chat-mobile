import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'settings.dart';
import 'chat.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  Settings settings = new Settings();
  @override
  Widget build(BuildContext context) {
    //
    return ChangeNotifierProvider(
        builder: (context) => SettingsNotifier(settings),
        child: MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.grey[800],
            accentColor: Colors.orange[700],
          ),
          home: new ChatPage(),
        ));
  }
}
