import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:majora/storage.dart';
import 'package:provider/provider.dart';

class SettingsRoute extends StatefulWidget {
  // Map<String, bool> settings = new Map<String, bool>();
  Settings settings;
  SettingsRoute(
      this.settings); // SettingsRoute({Key key, this.settings}) : super(key: key){

  @override
  _SettingsState createState() => new _SettingsState();
}

class _SettingsState extends State<SettingsRoute> {
  Storage storage = new Storage();
  Settings settings; // < holds everything
  SettingsNotifier settingsNotifier; //

  @override
  void initState() {
    // this.settings = new Settings();
  }

  //bool _showFlairs = false; @legacy
  // // ignoring notifications for now
  // bool _autocompleteHelper;
  // List<String> _customHighlights;
  // String _bannedMessages;

  void _showTimeChanged(bool value) {
    setState(() => this.settings.toggles['showTime'] = value);
    this.settings.storeToggles();
  }

  void _hideNSFWNSFLChanged(bool value) {
    setState(() => this.settings.toggles['hideNSFWNSFL'] = value);
    this.settings.storeToggles();
  }

  void _harshIgnoreChanged(bool value) {
    setState(() => this.settings.toggles['harshIgnore'] = value);
    this.settings.storeToggles();
  }

  void _loopAnimatedEmotesForeverChanged(bool value) {
    setState(() => this.settings.toggles['loopAnimatedEmotesForever'] = value);
    this.settings.storeToggles();
  }

  void _inlineWhispersChanged(bool value) {
    setState(() => this.settings.toggles['inlineWhispers'] = value);
    this.settings.storeToggles();
  }

  void _highlightOnMentionChanged(bool value) {
    setState(() => this.settings.toggles['highlightOnMention'] = value);
    this.settings.storeToggles();
  }

  void _increasedVisibilityOfTaggedUsersChanged(bool value) {
    setState(() =>
        this.settings.toggles['increasedVisibilityOfTaggedUsers'] = value);
    this.settings.storeToggles();
  }

  void _autocompleteHelperChanged(bool value) {
    setState(() => this.settings.toggles['autocompleteHelper'] = value);
    this.settings.storeToggles();
  }

  void _greentextChanged(bool value) {
    setState(() => this.settings.toggles['greentext'] = value);
    this.settings.storeToggles();
  }

  void _emotesChanged(bool value) {
    setState(() => this.settings.toggles['emotes'] = value);
    this.settings.storeToggles();
  }

  @override
  Widget build(BuildContext context) {
    this.settings = Provider.of<SettingsNotifier>(context).settings;
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
  Settings() {
    loadOnStart(); // load from storage
  }
  Map<String, bool> toggles = new Map<String, bool>(); // <- settings
  Map<String, String> userTags = new Map<String, String>(); // username + colour
  Set<String> wordsHighlighted = new Set<String>(); // word
  Set<String> usersIgnored = new Set<String>(); // username
  Set<String> wordsHidden = new Set<String>(); // word
  Storage storage = new Storage();

  Map<String, Theme> themes; // the themes users can use

  Color _cardColor = Color.fromARGB(255, 22, 25, 28); // card color
  get cardColor => _cardColor;
  Color _privateCardColor =
      Color.fromARGB(255, 196, 94, 0); // card color for private messages
  get privateCardColor => _privateCardColor;
  Color _bgColor = Color.fromARGB(255, 153, 153, 153); // global background
  get bgColor => _bgColor;

  storeSettings() {
    storeUserTags(this.userTags);
    storeFilter(this.wordsHighlighted, "wordsHighlight");
    storeFilter(this.usersIgnored, "usersIgnored");
    storeFilter(this.wordsHidden, "wordsHidden");
  }

  storeToggles() {
    int i = 0;
    var keys = this.toggles.keys;
    var values = this.toggles.values;
    for (var key in keys) {
      var value = values.elementAt(i);
      storage.addSetting(key, value.toString());
      i++;
    }
  }

  storeUserTags(Map<String, String> inputMap) {
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

  storeFilter(Set<String> inputSet, String inputKey) {
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

  loadOnStart() async {
    await storage.loadSettings();
    if (storage.hasSetting("showTime")) {
      // TODO: add function to check for all settings instead of assuming they are all there ?
      var loadedSettings = storage.getSettings;
      this.toggles.addAll({
        'showTime':
            loadedSettings['showTime'].toString().toLowerCase() == "true",
        'harshIgnore':
            loadedSettings['harshIgnore'].toString().toLowerCase() == "true",
        'hideNSFWNSFL':
            loadedSettings['hideNSFWNSFL'].toString().toLowerCase() == "true",
        'loopAnimatedEmotesForever': loadedSettings['loopAnimatedEmotesForever']
                .toString()
                .toLowerCase() ==
            "true",
        'inlineWhispers':
            loadedSettings['inlineWhispers'].toString().toLowerCase() == "true",
        'highlightOnMention':
            loadedSettings['highlightOnMention'].toString().toLowerCase() ==
                "true",
        'increasedVisibilityOfTaggedUsers':
            loadedSettings['increasedVisibilityOfTaggedUsers']
                    .toString()
                    .toLowerCase() ==
                "true",
        'autocompleteHelper':
            loadedSettings['autocompleteHelper'].toString().toLowerCase() ==
                "true",
        'greentext':
            loadedSettings['greentext'].toString().toLowerCase() == "true",
        'emotes': loadedSettings['emotes'].toString().toLowerCase() == "true",
      });

      if (!loadUserTags()) {
        // error here for not being able to load settings
      }
      this.usersIgnored = loadFilter("usersIgnored");
      this.wordsHighlighted = loadFilter("wordsHighlight");
      this.wordsHidden = loadFilter("wordsHidden");
    } else {
      loadDefaultSettings();
    }
  }

  bool loadUserTags() {
    if (storage.hasSetting("userTags")) {
      // if we find it
      String userTagsString = storage.getSetting("userTags");
      if (userTagsString == null || userTagsString.length < 1) {
        this.userTags = new Map<String, String>();
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
            this.userTags.addAll({key: value});
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
    toggles = new Map<String, bool>();
    userTags = new Map<String, String>();
    wordsHighlighted = new Set<String>();
    usersIgnored = new Set<String>();
    wordsHidden = new Set<String>();

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
  Settings settings;
  SettingsNotifier(this.settings);

  void updateSettings() {
    notifyListeners();
  }

  bool setToggle(String key, bool value) {
    if (this.settings.toggles.containsKey(key)) {
      this.settings.toggles.addAll({key: value});
      notifyListeners();
      return true;
    }
    return false;
  }

  void addUserTags(String user, String color) {
    this.settings.userTags.addAll({user: color});
    notifyListeners();
  }

  void addUsersIgnored(String user) {
    this.settings.usersIgnored.add(user);
    notifyListeners();
  }

  void addWordsHighlighted(String word) {
    this.settings.wordsHighlighted.add(word);
    notifyListeners();
  }

  void addWordsHidden(String word) {
    this.settings.wordsHighlighted.add(word);
    notifyListeners();
  }
}
