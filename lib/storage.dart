import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Storage {
  Storage();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late Map<String, String> settings = <String, String>{};

  Future<void> initS() async {
    settings = await _storage.readAll();
  }

  Future<void> loadSettings() async {
    WidgetsFlutterBinding.ensureInitialized();
    settings = await _storage.readAll();
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
    await loadSettings();
  }

  Future<void> addSetting(String key, String value) async {
    print('adding: key: $key, value: $value');
    await _storage.write(key: key, value: value);
    await loadSettings();
    final String succ = settings.containsKey(key).toString();
    print('added successfully?: $succ');
  }

  Future<void> deleteSetting(String key) async {
    await _storage.delete(key: key);
    await loadSettings();
  }

  String getSetting(String key) {
    return settings.containsKey(key) ? settings[key]! : '';
  }

  bool hasSetting(String key) {
    return settings.containsKey(key);
  }
}
