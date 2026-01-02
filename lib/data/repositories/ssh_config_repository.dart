import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ssh_config.dart';

class SSHConfigRepository {
  static const String _configsKey = 'ssh_configs';

  Future<List<SSHConfig>> getAllConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getStringList(_configsKey) ?? [];
    return configsJson
        .map((json) => SSHConfig.fromMap(jsonDecode(json)))
        .toList();
  }

  Future<SSHConfig?> getConfigById(String id) async {
    final configs = await getAllConfigs();
    try {
      return configs.firstWhere((config) => config.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveConfig(SSHConfig config) async {
    final configs = await getAllConfigs();
    final existingIndex = configs.indexWhere((c) => c.id == config.id);
    
    if (existingIndex >= 0) {
      configs[existingIndex] = config;
    } else {
      configs.add(config);
    }
    
    await _saveConfigs(configs);
  }

  Future<void> deleteConfig(String id) async {
    final configs = await getAllConfigs();
    configs.removeWhere((config) => config.id == id);
    await _saveConfigs(configs);
  }

  Future<void> updateConfig(SSHConfig config) async {
    await saveConfig(config);
  }

  Future<void> _saveConfigs(List<SSHConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = configs
        .map((config) => jsonEncode(config.toMap()))
        .toList();
    await prefs.setStringList(_configsKey, configsJson);
  }
}
