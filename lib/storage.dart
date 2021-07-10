import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Storage {
  FlutterSecureStorage _storage;
  Map<String, String> _settings = <String, String>{};
  Map<String, String> get getSettings => _settings;

  Storage() {
    _storage = FlutterSecureStorage();
  }

  Future<void> initS() async {
    _settings = await _storage.readAll();
  }

  Future<void> loadSettings() async {
    WidgetsFlutterBinding.ensureInitialized();
    _settings = await _storage.readAll();
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
    await loadSettings();
  }

  Future<void> addSetting(String key, String value) async {
    print('adding: key: $key, value: $value');
    await _storage.write(key: key, value: value);
    await loadSettings();
    String succ = _settings.containsKey(key).toString();
    print('added successfully?: $succ');
  }

  Future<void> deleteSetting(String key) async {
    await _storage.delete(key: key);
    await loadSettings();
  }

  String getSetting(String key) {
    return _settings[key];
  }

  bool hasSetting(String key) {
    return _settings.containsKey(key);
  }
}
