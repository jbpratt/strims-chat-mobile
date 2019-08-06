import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:majora/storage.dart';

class SettingsRoute extends StatefulWidget {
  // Map<String, bool> settings = new Map<String, bool>();
  Settings settings;
  SettingsRoute(
      this.settings); // SettingsRoute({Key key, this.settings}) : super(key: key){

  @override
  _SettingsState createState() => new _SettingsState(this.settings);

  // get settings
  // void getSettings() {
  //   settings = _state.settings;
  // }
}

class _SettingsState extends State<SettingsRoute> {
  // Map<String, bool> settings;
  Map<String, String> userTags; // username + colour
  Set<String> wordsHighight; // word
  Set<String> usersIgnored; // username
  Set<String> wordsHidden; // word
  Storage storage = new Storage();
  Settings settings; // < holds everything

  _SettingsState(this.settings) {
    loadOnStart(this.storage);
    this.settings.usersIgnored.add("pepelaugh");
  }

  @override
  void initState() {
    // loadDefaultSettings();
    loadOnStart(this.storage);
  }

  storeSettings(Storage storage) {
    // storeUserTags(this.settings.userTags, storage);
    // storeFilter(this.settings.wordsHighight, "wordsHighlight", storage);
    // storeFilter(this.settings.usersIgnored, "usersIgnored", storage);
    // storeFilter(this.settings.wordsHidden, "wordsHidden", storage);
    // if (this.settings == null || this.settings.toggles.isEmpty) {
    //   loadDefaultSettings();
    //   return;
    // }
    int i = 0;
    var keys = this.settings.toggles.keys;
    var values = this.settings.toggles.values;
    for (var key in keys) {
      var value = values.elementAt(i);
      print("adding: " + i.toString() + " th");
      storage.deleteSetting(key);
      storage.addSetting(key, value.toString());
      i++;
    }
  }

  storeUserTags(Map<String, String> inputMap, Storage storage) {
    if (inputMap == null || inputMap.isEmpty) {
      storage.addSetting('userTags', "");
    } else {
      String userTags = "";
      var keys = inputMap.keys;
      var values = inputMap.values;
      for (var key in keys) {
        for (var value in values) {
          userTags += key + ":" + value + ",";
        }
      }
      storage.addSetting('userTags', userTags);
    }
  }

  storeFilter(Set<String> inputSet, String inputKey, Storage storage) {
    if (inputSet == null || inputSet.isEmpty) {
      storage.addSetting(inputKey, "");
    } else {
      String outputString = "";
      for (var each in inputSet) {
        outputString += each + ",";
      }
      storage.addSetting(inputKey, outputString);
    }
  }

// need to load settings out of storage
  void loadSettingsFromStorage(Storage storage) {
    var loadedSettings = storage.loadSettings();

    // print(loadedSettings);
  }

  void loadOnStart(Storage storage) {
    storage.resetSettings();
    storage.loadSettings();
    if (this.settings == null) {
      this.settings = new Settings();
    }
    if (this.settings.toggles == null) {
      this.settings.toggles = new Map<String, bool>();
    }
    if (this.settings.toggles.isEmpty) {
      this.settings.toggles = new Map<String, bool>();
      if (storage.hasSetting("showTime")) {
        // TODO: add function to check for all settings instead of assuming they are all there ?
        var loadedSettings = storage.getSettings;
        this.settings.toggles.addAll({
          'showTime':
              loadedSettings['showTime'].toString().toLowerCase() == "true",
          'hideNSFWNSFL':
              loadedSettings['hideNSFWNSFL'].toString().toLowerCase() == "true",
          'harshIgnore':
              loadedSettings['harshIgnore'].toString().toLowerCase() == "true",
          'loopAnimatedEmotesForever':
              loadedSettings['loopAnimatedEmotesForever']
                      .toString()
                      .toLowerCase() ==
                  "true",
          'inlineWhispers':
              loadedSettings['inlineWhispers'].toString().toLowerCase() ==
                  "true",
          'highlightOnMention':
              loadedSettings['highlightOnMention'].toString().toLowerCase() ==
                  "true",
          'increasedVisibilityOfTaggedUsers':
              loadedSettings['increasedVisibilityOfTaggedUsers']
                      .toString()
                      .toLowerCase() ==
                  "true",
          'increasedVisibilityOfTaggedUsers':
              loadedSettings['autocompleteHelper'].toString().toLowerCase() ==
                  "true",
          'increasedVisibilityOfTaggedUsers':
              loadedSettings['greentext'].toString().toLowerCase() == "true",
          'increasedVisibilityOfTaggedUsers':
              loadedSettings['emotes'].toString().toLowerCase() == "true",
        });
        setState(() {
          settings.toggles;
        });
        if (!loadUserTags()) {
          // error here for not being able to load settings
        }
        this.settings.usersIgnored = loadFilter("usersIgnored");
        this.settings.wordsHighlighted = loadFilter("wordsHighlight");
        this.settings.wordsHidden = loadFilter("wordsHidden");
      } else {
        loadDefaultSettings();
      }
    }
  }

  bool loadUserTags() {
    if (storage.hasSetting("userTags")) {
      // if we find it
      String userTagsString = storage.getSetting("userTags");
      if (userTagsString == null || userTagsString.length < 1) {
        this.settings.userTags = new Map<String, String>();
      } else {
        var splitUserTags =
            userTagsString.split(","); // split each entry on ","
        for (var userTag in splitUserTags) {
          if (userTag == "") {
            continue;
          }
          var keyValue = userTag.split(":"); // split key and value on ":"
          var key = keyValue[0];
          var value = keyValue[1];
          if (key != "" && value != "") {
            this.settings.userTags.addAll({key: value});
          }
        }
        return true;
      }
    }
    return false;
  }

  Set<String> loadFilter(String key) {
    Set<String> returnSet = new Set<String>();
    if (storage.hasSetting(key)) {
      var values = storage.getSetting(key);
      var valuesSplit = values.split(","); // each value split on ","
      for (var filterValue in valuesSplit) {
        if (filterValue != "") {
          returnSet.add(filterValue);
        }
      }
      return returnSet;
    }
    return returnSet;
  }

  void loadDefaultSettings() {
    this.settings.toggles = new Map<String, bool>();

    this.settings.toggles.addAll({
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

    this.settings.userTags = new Map<String, String>();
    this.settings.wordsHighlighted = new Set<String>();
    this.settings.usersIgnored = new Set<String>();
    this.settings.wordsHidden = new Set<String>();
  }
  //bool _showFlairs = false; @legacy
  // // ignoring notifications for now
  // bool _autocompleteHelper;
  // List<String> _customHighlights;
  // String _bannedMessages;

  void _showTimeChanged(bool value) =>
      setState(() => this.settings.toggles['showTime'] = value);

  void _hideNSFWNSFLChanged(bool value) =>
      setState(() => this.settings.toggles['hideNSFWNSFL'] = value);

  void _harshIgnoreChanged(bool value) =>
      setState(() => this.settings.toggles['hideNSFWNSFL'] = value);

  void _loopAnimatedEmotesForeverChanged(bool value) => setState(
      () => this.settings.toggles['loopAnimatedEmotesForever'] = value);

  void _inlineWhispersChanged(bool value) =>
      setState(() => this.settings.toggles['inlineWhispers'] = value);

  void _highlightOnMentionChanged(bool value) =>
      setState(() => this.settings.toggles['highlightOnMention'] = value);

  void _increasedVisibilityOfTaggedUsersChanged(bool value) => setState(
      () => this.settings.toggles['increasedVisibilityOfTaggedUsers'] = value);

  void _autocompleteHelperChanged(bool value) =>
      setState(() => this.settings.toggles['autocompleteHelper'] = value);

  void _greentextChanged(bool value) =>
      setState(() => this.settings.toggles['greentext'] = value);

  void _emotesChanged(bool value) {
    setState(() => this.settings.toggles['emotes'] = value);
    // this.storeSettings(this.storage);
    // print("SETTINGS AS STORED");
    // print(this.settings.toggles);
  }

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
                value: this.settings.toggles['showTime'],
                onChanged: _showTimeChanged,
                title: new Text('Show time'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              new CheckboxListTile(
                value: this.settings.toggles['harshIgnore'],
                onChanged: _harshIgnoreChanged,
                title: new Text('Harsh ignore'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              new CheckboxListTile(
                value: this.settings.toggles['hideNSFWNSFL'],
                onChanged: _hideNSFWNSFLChanged,
                title: new Text('Hide messages with nsfl, nsfw'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              new CheckboxListTile(
                value: this.settings.toggles['loopAnimatedEmotesForever'],
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
                value: this.settings.toggles['inlineWhispers'],
                onChanged: _inlineWhispersChanged,
                title: new Text('In-line messages'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              new Align(
                  alignment: Alignment.centerLeft,
                  child: new Text('Highlights, Focus, & Tags'.toUpperCase())),
              new CheckboxListTile(
                value: this.settings.toggles['highlightOnMention'],
                onChanged: _highlightOnMentionChanged,
                title: new Text('Highlight when mentioned'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              new CheckboxListTile(
                value:
                    this.settings.toggles['increasedVisibilityOfTaggedUsers'],
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
                value: this.settings.toggles['autocompleteHelper'],
                onChanged: _autocompleteHelperChanged,
                title: new Text('Auto-complete helper'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              new Align(
                  alignment: Alignment.centerLeft,
                  child: new Text('Message Formatters'.toUpperCase())),
              new CheckboxListTile(
                value: this.settings.toggles['greentext'],
                onChanged: _greentextChanged,
                title: new Text('Greentext'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              new CheckboxListTile(
                value: this.settings.toggles['emotes'],
                onChanged: _emotesChanged,
                title: new Text('Emotes'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
            ])));
  }
}

class Settings {
  Map<String, bool> toggles; // <- settings
  Map<String, String> userTags; // username + colour
  Set<String> wordsHighlighted; // word
  Set<String> usersIgnored; // username
  Set<String> wordsHidden; // word

  Map<String, Theme> themes; // the themes users can use

  Color cardColor = Color.fromARGB(255, 22, 25, 28); // card color
  Color privateCardColor =
      Color.fromARGB(255, 196, 94, 0); // card color for private messages
  Color bgColor = Color.fromARGB(255, 153, 153, 153); // global background

  Settings() {
    toggles = new Map<String, bool>();
    userTags = new Map<String, String>();
    wordsHighlighted = new Set<String>();
    usersIgnored = new Set<String>();
    wordsHidden = new Set<String>();

    // settings defaults for testing  // TODO: remove

    toggles.addAll({
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
}

class SettingsNotifier extends ChangeNotifier {
  Settings settings = new Settings();
  void updateSettings() {
    notifyListeners();
  }
}
