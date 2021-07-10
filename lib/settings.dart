import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'storage.dart';

class SettingsRoute extends StatefulWidget {
  final Settings settings;
  SettingsRoute(this.settings);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<SettingsRoute> {
  Storage storage = Storage();
  Settings settings; // < holds everything
  SettingsNotifier settingsNotifier; //

  //bool _showFlairs = false; @legacy
  // // ignoring notifications for now
  // bool _autocompleteHelper;
  // List<String> _customHighlights;
  // String _bannedMessages;

  void _showTimeChanged(bool value) {
    setState(() => settings.toggles['showTime'] = value);
    settings.storeToggles();
  }

  void _hideNSFWNSFLChanged(bool value) {
    setState(() => settings.toggles['hideNSFWNSFL'] = value);
    settings.storeToggles();
  }

  void _harshIgnoreChanged(bool value) {
    setState(() => settings.toggles['harshIgnore'] = value);
    settings.storeToggles();
  }

  void _loopAnimatedEmotesForeverChanged(bool value) {
    setState(() => settings.toggles['loopAnimatedEmotesForever'] = value);
    settings.storeToggles();
  }

  void _inlineWhispersChanged(bool value) {
    setState(() => settings.toggles['inlineWhispers'] = value);
    settings.storeToggles();
  }

  void _highlightOnMentionChanged(bool value) {
    setState(() => settings.toggles['highlightOnMention'] = value);
    settings.storeToggles();
  }

  void _increasedVisibilityOfTaggedUsersChanged(bool value) {
    setState(
        () => settings.toggles['increasedVisibilityOfTaggedUsers'] = value);
    settings.storeToggles();
  }

  void _autocompleteHelperChanged(bool value) {
    setState(() => settings.toggles['autocompleteHelper'] = value);
    settings.storeToggles();
  }

  void _greentextChanged(bool value) {
    setState(() => settings.toggles['greentext'] = value);
    settings.storeToggles();
  }

  void _emotesChanged(bool value) {
    setState(() => settings.toggles['emotes'] = value);
    settings.storeToggles();
  }

  @override
  Widget build(BuildContext context) {
    settings = Provider.of<SettingsNotifier>(context).settings;
    return Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
        ),
        body: Container(
            height: 750.0,
            padding: EdgeInsets.all(8.0),
            child: ListView(children: <Widget>[
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Messages'.toUpperCase())),
              CheckboxListTile(
                value: settings.toggles['showTime'],
                onChanged: _showTimeChanged,
                title: Text('Show time'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              CheckboxListTile(
                value: settings.toggles['harshIgnore'],
                onChanged: _harshIgnoreChanged,
                title: Text('Harsh ignore'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              CheckboxListTile(
                value: settings.toggles['hideNSFWNSFL'],
                onChanged: _hideNSFWNSFLChanged,
                title: Text('Hide messages with nsfl, nsfw'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              CheckboxListTile(
                value: settings.toggles['loopAnimatedEmotesForever'],
                onChanged: _loopAnimatedEmotesForeverChanged,
                title: Text('Loop animated emotes forever'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              // banned messages dropdown
              // inapp notifactionx?
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Whispers'.toUpperCase())),
              CheckboxListTile(
                value: settings.toggles['inlineWhispers'],
                onChanged: _inlineWhispersChanged,
                title: Text('In-line messages'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Highlights, Focus, & Tags'.toUpperCase())),
              CheckboxListTile(
                value: settings.toggles['highlightOnMention'],
                onChanged: _highlightOnMentionChanged,
                title: Text('Highlight when mentioned'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              CheckboxListTile(
                value: settings.toggles['increasedVisibilityOfTaggedUsers'],
                onChanged: _increasedVisibilityOfTaggedUsersChanged,
                title: Text('Increased visibility of tagged users'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              // Custom highlights
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Autocomplete'.toUpperCase())),
              CheckboxListTile(
                value: settings.toggles['autocompleteHelper'],
                onChanged: _autocompleteHelperChanged,
                title: Text('Auto-complete helper'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Message Formatters'.toUpperCase())),
              CheckboxListTile(
                value: settings.toggles['greentext'],
                onChanged: _greentextChanged,
                title: Text('Greentext'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              CheckboxListTile(
                value: settings.toggles['emotes'],
                onChanged: _emotesChanged,
                title: Text('Emotes'),
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
  Map<String, bool> toggles = <String, bool>{}; // <- settings
  Map<String, String> userTags = <String, String>{}; // username + colour
  Set<String> wordsHighlighted = <String>{}; // word
  Set<String> usersIgnored = <String>{}; // username
  Set<String> wordsHidden = <String>{}; // word
  int maxMessages = 300; // default value for max messages in chat
  int batchDeleteAmount = 20; // the amount of messages to delete at a time
  Storage storage = Storage();

  Map<String, Theme> themes; // the themes users can use

  final Color _cardColor = Color.fromARGB(255, 22, 25, 28); // card color
  Color get cardColor => _cardColor;
  final Color _privateCardColor =
      Color.fromARGB(255, 196, 94, 0); // card color for private messages
  Color get privateCardColor => _privateCardColor;
  final Color _bgColor =
      Color.fromARGB(255, 153, 153, 153); // global background
  Color get bgColor => _bgColor;

  void storeSettings() {
    storeUserTags(userTags);
    storeFilter(wordsHighlighted, 'wordsHighlight');
    storeFilter(usersIgnored, 'usersIgnored');
    storeFilter(wordsHidden, 'wordsHidden');
  }

  void storeToggles() {
    int i = 0;
    var keys = toggles.keys;
    var values = toggles.values;
    for (var key in keys) {
      var value = values.elementAt(i);
      storage.addSetting(key, value.toString());
      i++;
    }
  }

  void storeUserTags(Map<String, String> inputMap) {
    if (inputMap == null || inputMap.isEmpty) {
      storage.addSetting('userTags', '');
    } else {
      String userTags = '';
      var keys = inputMap.keys;
      for (var key in keys) {
        var value = inputMap[key];
        userTags += key + ':' + value + ',';
      }
      storage.addSetting('userTags', userTags);
    }
  }

  void storeFilter(Set<String> inputSet, String inputKey) {
    if (inputSet == null || inputSet.isEmpty) {
      storage.addSetting(inputKey, '');
    } else {
      String outputString = '';
      for (var each in inputSet) {
        outputString += each + ',';
      }
      storage.addSetting(inputKey, outputString);
    }
  }

  Future<void> loadOnStart() async {
    await storage.loadSettings();
    if (storage.hasSetting('showTime')) {
      // TODO: add function to check for all settings instead of assuming they are all there ?
      var loadedSettings = storage.getSettings;
      toggles.addAll({
        'showTime':
            loadedSettings['showTime'].toString().toLowerCase() == 'true',
        'harshIgnore':
            loadedSettings['harshIgnore'].toString().toLowerCase() == 'true',
        'hideNSFWNSFL':
            loadedSettings['hideNSFWNSFL'].toString().toLowerCase() == 'true',
        'loopAnimatedEmotesForever': loadedSettings['loopAnimatedEmotesForever']
                .toString()
                .toLowerCase() ==
            'true',
        'inlineWhispers':
            loadedSettings['inlineWhispers'].toString().toLowerCase() == 'true',
        'highlightOnMention':
            loadedSettings['highlightOnMention'].toString().toLowerCase() ==
                'true',
        'increasedVisibilityOfTaggedUsers':
            loadedSettings['increasedVisibilityOfTaggedUsers']
                    .toString()
                    .toLowerCase() ==
                'true',
        'autocompleteHelper':
            loadedSettings['autocompleteHelper'].toString().toLowerCase() ==
                'true',
        'greentext':
            loadedSettings['greentext'].toString().toLowerCase() == 'true',
        'emotes': loadedSettings['emotes'].toString().toLowerCase() == 'true',
      });

      if (!loadUserTags()) {
        // error here for not being able to load settings
      }
      usersIgnored = loadFilter('usersIgnored');
      wordsHighlighted = loadFilter('wordsHighlight');
      wordsHidden = loadFilter('wordsHidden');
    } else {
      loadDefaultSettings();
    }
  }

  bool loadUserTags() {
    if (storage.hasSetting('userTags')) {
      // if we find it
      String userTagsString = storage.getSetting('userTags');
      if (userTagsString == null || userTagsString.isEmpty) {
        userTags = <String, String>{};
      } else {
        var splitUserTags =
            userTagsString.split(','); // split each entry on ","
        for (var userTag in splitUserTags) {
          if (userTag == '') {
            continue;
          }
          var keyValue = userTag.split(':'); // split key and value on ":"
          var key = keyValue[0];
          var value = keyValue[1];
          if (key != '' && value != '') {
            userTags.addAll({key: value});
          }
        }
        return true;
      }
    }
    return false;
  }

  Set<String> loadFilter(String key) {
    Set<String> returnSet = <String>{};
    if (storage.hasSetting(key)) {
      var values = storage.getSetting(key);
      var valuesSplit = values.split(','); // each value split on ","
      for (var filterValue in valuesSplit) {
        if (filterValue != '') {
          returnSet.add(filterValue);
        }
      }
      return returnSet;
    }
    return returnSet;
  }

  void loadDefaultSettings() {
    toggles = <String, bool>{};
    userTags = <String, String>{};
    wordsHighlighted = <String>{};
    usersIgnored = <String>{};
    wordsHidden = <String>{};

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
    settings.storeSettings();
    notifyListeners();
  }

  bool setToggle(String key, bool value) {
    if (settings.toggles.containsKey(key)) {
      settings.toggles.addAll({key: value});
      notifyListeners();
      return true;
    }
    return false;
  }

  void addUserTags(String user, String color) {
    settings.userTags.addAll({user: color});
    updateSettings();
  }

  void addUsersIgnored(String user) {
    settings.usersIgnored.add(user);
    updateSettings();
  }

  void addWordsHighlighted(String word) {
    settings.wordsHighlighted.add(word);
    updateSettings();
  }

  void addWordsHidden(String word) {
    settings.wordsHidden.add(word);
    updateSettings();
  }

// add ^ remove v
  void removeUserTags(String user) {
    settings.userTags.remove(user);
    updateSettings();
  }

  void removeUsersIgnored(String user) {
    settings.usersIgnored.remove(user);
    updateSettings();
  }

  void removeWordsHighlighted(String word) {
    settings.wordsHighlighted.remove(word);
    updateSettings();
  }

  void removeWordsHidden(String word) {
    settings.wordsHidden.remove(word);
    updateSettings();
  }
}
