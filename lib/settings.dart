import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsRoute extends StatefulWidget {
  Map<String, bool> settings = new Map<String, bool>();

  SettingsRoute({Key key, this.settings}) : super(key: key);

  @override
  _SettingsState createState() => new _SettingsState(settings: this.settings);
}

class _SettingsState extends State<SettingsRoute> {
  Map<String, bool> settings;

  _SettingsState({this.settings});

  @override
  void initState() {
    loadDefaultSettings();
  }

// need to load settings out of storage
  void loadDefaultSettings() {
    if (settings == null) {
      settings = new Map<String, bool>();
    }
    settings.addAll({
      'showTime': true,
      'hideNSFWNSFL': false,
      'harshIgnore': false,
      'loopAnimatedEmotesForever': false,
      'inlineWhispers': true,
      'highlightOnMention': true,
      'increasedVisibilityOfTaggedUsers': false,
      'autocompleteHelper': true,
      'greentext': true,
      'emotes': true,
    });
  }
  //bool _showFlairs = false; @legacy
  // // ignoring notifications for now
  // bool _autocompleteHelper;
  // List<String> _customHighlights;
  // String _bannedMessages;

  void _showTimeChanged(bool value) =>
      setState(() => settings['showTime'] = value);

  void _hideNSFWNSFLChanged(bool value) =>
      setState(() => settings['hideNSFWNSFL'] = value);

  void _harshIgnoreChanged(bool value) =>
      setState(() => settings['hideNSFWNSFL'] = value);

  void _loopAnimatedEmotesForeverChanged(bool value) =>
      setState(() => settings['loopAnimatedEmotesForever'] = value);

  void _inlineWhispersChanged(bool value) =>
      setState(() => settings['inlineWhispers'] = value);

  void _highlightOnMentionChanged(bool value) =>
      setState(() => settings['highlightOnMention'] = value);

  void _increasedVisibilityOfTaggedUsersChanged(bool value) =>
      setState(() => settings['increasedVisibilityOfTaggedUsers'] = value);

  void _autocompleteHelperChanged(bool value) =>
      setState(() => settings['autocompleteHelper'] = value);

  void _greentextChanged(bool value) =>
      setState(() => settings['greentext'] = value);

  void _emotesChanged(bool value) => setState(() => settings['emotes'] = value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
        ),
        body: Container(
            height: 750.0,
            padding: new EdgeInsets.all(8.0),
            child: new ListView(children: <Widget>[
              new Align(
                  alignment: Alignment.centerLeft,
                  child: new Text('Messages'.toUpperCase())),
              new CheckboxListTile(
                value: settings['showTime'],
                onChanged: _showTimeChanged,
                title: new Text('Show time'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              new CheckboxListTile(
                value: settings['harshIgnore'],
                onChanged: _harshIgnoreChanged,
                title: new Text('Harsh ignore'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              new CheckboxListTile(
                value: settings['hideNSFWNSFL'],
                onChanged: _hideNSFWNSFLChanged,
                title: new Text('Hide messages with nsfl, nsfw'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              new CheckboxListTile(
                value: settings['loopAnimatedEmotesForever'],
                onChanged: _loopAnimatedEmotesForeverChanged,
                title: new Text('Loop animated emotes forever'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              // banned messages dropdown
              // inapp notifactionx?
              new Align(
                  alignment: Alignment.centerLeft,
                  child: new Text('Whispers'.toUpperCase())),
              new CheckboxListTile(
                value: settings['inlineWhispers'],
                onChanged: _inlineWhispersChanged,
                title: new Text('In-line messages'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              new Align(
                  alignment: Alignment.centerLeft,
                  child: new Text('Highlights, Focus, & Tags'.toUpperCase())),
              new CheckboxListTile(
                value: settings['highlightOnMention'],
                onChanged: _highlightOnMentionChanged,
                title: new Text('Highlight when mentioned'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              new CheckboxListTile(
                value: settings['increasedVisibilityOfTaggedUsers'],
                onChanged: _increasedVisibilityOfTaggedUsersChanged,
                title: new Text('Increased visibility of tagged users'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              // Custom highlights
              new Align(
                  alignment: Alignment.centerLeft,
                  child: new Text('Autocomplete'.toUpperCase())),
              new CheckboxListTile(
                value: settings['autocompleteHelper'],
                onChanged: _autocompleteHelperChanged,
                title: new Text('Auto-complete helper'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              new Align(
                  alignment: Alignment.centerLeft,
                  child: new Text('Message Formatters'.toUpperCase())),
              new CheckboxListTile(
                value: settings['greentext'],
                onChanged: _greentextChanged,
                title: new Text('Greentext'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              new CheckboxListTile(
                value: settings['emotes'],
                onChanged: _emotesChanged,
                title: new Text('Emotes'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
            ])));
  }
}
