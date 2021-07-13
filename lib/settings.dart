import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'storage.dart';

class SettingsRoute extends StatefulWidget {
  const SettingsRoute(this.settings, {Key? key}) : super(key: key);
  final Settings settings;

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<SettingsRoute> {
  Storage storage = Storage();
  late Settings settings; // < holds everything
  late SettingsNotifier settingsNotifier; //

  //bool _showFlairs = false; @legacy
  // // ignoring notifications for now
  // bool _autocompleteHelper;
  // List<String> _customHighlights;
  // String _bannedMessages;

  void _showTimeChanged(bool? value) {
    setState(() => settings.toggles['showTime'] = value ?? false);
    settings.storeToggles();
  }

  void _hideNSFWNSFLChanged(bool? value) {
    setState(() => settings.toggles['hideNSFWNSFL'] = value ?? false);
    settings.storeToggles();
  }

  void _harshIgnoreChanged(bool? value) {
    setState(() => settings.toggles['harshIgnore'] = value ?? false);
    settings.storeToggles();
  }

  void _loopAnimatedEmotesForeverChanged(bool? value) {
    setState(
        () => settings.toggles['loopAnimatedEmotesForever'] = value ?? false);
    settings.storeToggles();
  }

  void _inlineWhispersChanged(bool? value) {
    setState(() => settings.toggles['inlineWhispers'] = value ?? false);
    settings.storeToggles();
  }

  void _highlightOnMentionChanged(bool? value) {
    setState(() => settings.toggles['highlightOnMention'] = value ?? false);
    settings.storeToggles();
  }

  void _increasedVisibilityOfTaggedUsersChanged(bool? value) {
    setState(() =>
        settings.toggles['increasedVisibilityOfTaggedUsers'] = value ?? false);
    settings.storeToggles();
  }

  void _autocompleteHelperChanged(bool? value) {
    setState(() => settings.toggles['autocompleteHelper'] = value ?? false);
    settings.storeToggles();
  }

  void _greentextChanged(bool? value) {
    setState(() => settings.toggles['greentext'] = value ?? false);
    settings.storeToggles();
  }

  void _emotesChanged(bool? value) {
    setState(() => settings.toggles['emotes'] = value ?? false);
    settings.storeToggles();
  }

  @override
  Widget build(BuildContext context) {
    settings = Provider.of<SettingsNotifier>(context).settings;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: Container(
            height: 750,
            padding: const EdgeInsets.all(8),
            child: ListView(children: <Widget>[
              const Align(
                  alignment: Alignment.centerLeft, child: Text('MESSAGES')),
              CheckboxListTile(
                value: settings.toggles['showTime'],
                onChanged: _showTimeChanged,
                title: const Text('Show time'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              CheckboxListTile(
                value: settings.toggles['harshIgnore'],
                onChanged: _harshIgnoreChanged,
                title: const Text('Harsh ignore'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              CheckboxListTile(
                value: settings.toggles['hideNSFWNSFL'],
                onChanged: _hideNSFWNSFLChanged,
                title: const Text('Hide messages with nsfl, nsfw'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              CheckboxListTile(
                value: settings.toggles['loopAnimatedEmotesForever'],
                onChanged: _loopAnimatedEmotesForeverChanged,
                title: const Text('Loop animated emotes forever'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              // banned messages dropdown
              // inapp notifactionx?
              const Align(
                  alignment: Alignment.centerLeft, child: Text('WHISPERS')),
              CheckboxListTile(
                value: settings.toggles['inlineWhispers'],
                onChanged: _inlineWhispersChanged,
                title: const Text('In-line messages'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('HIGHLIGHTS, FOCUS, & TAGS')),
              CheckboxListTile(
                value: settings.toggles['highlightOnMention'],
                onChanged: _highlightOnMentionChanged,
                title: const Text('Highlight when mentioned'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              CheckboxListTile(
                value: settings.toggles['increasedVisibilityOfTaggedUsers'],
                onChanged: _increasedVisibilityOfTaggedUsersChanged,
                title: const Text('Increased visibility of tagged users'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              // Custom highlights
              const Align(
                  alignment: Alignment.centerLeft, child: Text('AUTOCOMPLETE')),
              CheckboxListTile(
                value: settings.toggles['autocompleteHelper'],
                onChanged: _autocompleteHelperChanged,
                title: const Text('Auto-complete helper'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('MESSAGE FORMATTERS')),
              CheckboxListTile(
                value: settings.toggles['greentext'],
                onChanged: _greentextChanged,
                title: const Text('Greentext'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
              CheckboxListTile(
                value: settings.toggles['emotes'],
                onChanged: _emotesChanged,
                title: const Text('Emotes'),
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

  final Storage storage = Storage();
  //  Map<String, Theme> themes; // the themes users can use

  final Color cardColor = const Color.fromARGB(255, 22, 25, 28); // card color
  final Color privateCardColor =
      const Color.fromARGB(255, 196, 94, 0); // card color for private messages
  final Color bgColor =
      const Color.fromARGB(255, 153, 153, 153); // global background

  void storeSettings() {
    storeUserTags(userTags);
    storeFilter(wordsHighlighted, 'wordsHighlight');
    storeFilter(usersIgnored, 'usersIgnored');
    storeFilter(wordsHidden, 'wordsHidden');
  }

  void storeToggles() {
    int i = 0;
    for (final key in toggles.keys) {
      storage.addSetting(key, toggles.values.elementAt(i).toString());
      i++;
    }
  }

  void storeUserTags(Map<String, String> inputMap) {
    if (inputMap.isEmpty) {
      storage.addSetting('userTags', '');
    } else {
      final buffer = StringBuffer();
      for (final key in inputMap.keys) {
        final value = inputMap[key]!;
        buffer.write('$key:$value');
      }
      storage.addSetting('userTags', buffer.toString());
    }
  }

  void storeFilter(Set<String> inputSet, String inputKey) =>
      storage.addSetting(inputKey, inputSet.join(',').toString());

  Future<void> loadOnStart() async {
    await storage.loadSettings();
    if (storage.hasSetting('showTime')) {
      // TODO: add function to check for all settings instead of assuming they are all there ?
      final loadedSettings = storage.settings;
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
      final String userTagsString = storage.getSetting('userTags');
      if (userTagsString.isEmpty) {
        userTags = <String, String>{};
      } else {
        final splitUserTags = userTagsString.split(',');
        for (final userTag in splitUserTags) {
          if (userTag == '') {
            continue;
          }
          final keyValue = userTag.split(':');
          final key = keyValue[0];
          final value = keyValue[1];
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
    final Set<String> returnSet = <String>{};
    if (storage.hasSetting(key)) {
      final values = storage.getSetting(key);
      final valuesSplit = values.split(',');
      for (final filterValue in valuesSplit) {
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
  SettingsNotifier(this.settings);

  final Settings settings;

  void updateSettings() {
    settings.storeSettings();
    notifyListeners();
  }

  bool setToggle(String key, {bool value = false}) {
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
