import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/ssh_config.dart';
import '../../data/repositories/ssh_config_repository.dart';
import '../../services/encryption_service.dart';
import '../../services/ssh_service.dart';

class SSHConfigProvider extends ChangeNotifier {
  final SSHConfigRepository _repository = SSHConfigRepository();
  List<SSHConfig> _configs = [];
  bool _isLoading = false;
  final Map<String, ConnectionStatus> _connectionStatus = {};

  List<SSHConfig> get configs => _configs;
  bool get isLoading => _isLoading;
  
  ConnectionStatus getConnectionStatus(String configId) {
    return _connectionStatus[configId] ?? ConnectionStatus.disconnected;
  }

  Future<void> loadConfigs() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _configs = await _repository.getAllConfigs();
    } catch (e) {
      debugPrint('Error loading configs: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addConfig(SSHConfig config) async {
    try {
      await _repository.saveConfig(config);
      _configs.add(config);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding config: $e');
    }
  }

  Future<void> updateConfig(SSHConfig config) async {
    try {
      await _repository.updateConfig(config);
      final index = _configs.indexWhere((c) => c.id == config.id);
      if (index != -1) {
        _configs[index] = config;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating config: $e');
    }
  }

  Future<void> deleteConfig(String id) async {
    try {
      await _repository.deleteConfig(id);
      await EncryptionService.deletePassword(id);
      await EncryptionService.deletePrivateKey(id);
      _configs.removeWhere((c) => c.id == id);
      _connectionStatus.remove(id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting config: $e');
    }
  }

  Future<bool> connect(SSHConfig config) async {
    _connectionStatus[config.id] = ConnectionStatus.connecting;
    notifyListeners();
    
    try {
      // 尝试真实的SSH连接
      final success = await SSHService.connect(config);
      _connectionStatus[config.id] = success 
          ? ConnectionStatus.connected 
          : ConnectionStatus.error;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('SSH连接错误: $e');
      _connectionStatus[config.id] = ConnectionStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect(String configId) async {
    _connectionStatus[configId] = ConnectionStatus.disconnected;
    notifyListeners();
  }

  SSHConfig createNewConfig({
    required String name,
    required String host,
    required int port,
    required String username,
    required AuthType authType,
    String? privateKeyPath,
  }) {
    return SSHConfig(
      id: const Uuid().v4(),
      name: name,
      host: host,
      port: port,
      username: username,
      authType: authType,
      privateKeyPath: privateKeyPath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
