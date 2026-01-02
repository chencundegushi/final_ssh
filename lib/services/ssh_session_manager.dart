import 'dart:async';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class SSHSession {
  final String configId;
  SSHClient? _client;
  SSHSession? _session;
  ConnectionStatus status = ConnectionStatus.disconnected;
  String? errorMessage;
  final StreamController<String> _outputController = StreamController<String>.broadcast();

  SSHSession(this.configId);

  Stream<String> get outputStream => _outputController.stream;

  Future<bool> connect({
    required String host,
    required int port,
    required String username,
    String? password,
    String? privateKey,
  }) async {
    try {
      status = ConnectionStatus.connecting;
      
      // 模拟连接过程，实际项目中使用真实的SSH连接
      await Future.delayed(const Duration(seconds: 1));
      
      // 模拟成功连接
      status = ConnectionStatus.connected;
      _outputController.add('SSH connection established\n');
      return true;
    } catch (e) {
      status = ConnectionStatus.error;
      errorMessage = e.toString();
      _outputController.add('Connection failed: $e\n');
      return false;
    }
  }

  Future<String> executeCommand(String command) async {
    if (status != ConnectionStatus.connected) {
      throw Exception('Not connected');
    }

    try {
      // 模拟命令执行，实际项目中使用真实的SSH命令执行
      await Future.delayed(const Duration(milliseconds: 200));
      
      String output;
      switch (command.trim()) {
        case 'ls':
          output = 'file1.txt  file2.txt  directory1/\n';
          break;
        case 'pwd':
          output = '/home/user\n';
          break;
        case 'whoami':
          output = 'user\n';
          break;
        case 'date':
          output = '${DateTime.now()}\n';
          break;
        default:
          output = 'Command executed: $command\n';
      }
      
      _outputController.add(output);
      return output;
    } catch (e) {
      final error = 'Error: ${e.toString()}\n';
      _outputController.add(error);
      return error;
    }
  }

  Future<void> disconnect() async {
    try {
      _client?.close();
      _client = null;
      status = ConnectionStatus.disconnected;
      errorMessage = null;
      _outputController.add('Connection closed.\n');
    } catch (e) {
      errorMessage = e.toString();
    }
  }

  void dispose() {
    disconnect();
    _outputController.close();
  }
}

class SSHSessionManager {
  static final Map<String, SSHSession> _sessions = {};

  static SSHSession? getSession(String configId) {
    return _sessions[configId];
  }

  static Future<SSHSession> createSession(String configId, {
    required String host,
    required int port,
    required String username,
    String? password,
    String? privateKey,
  }) async {
    final session = SSHSession(configId);
    _sessions[configId] = session;
    
    await session.connect(
      host: host,
      port: port,
      username: username,
      password: password,
      privateKey: privateKey,
    );
    
    return session;
  }

  static Future<void> disconnectSession(String configId) async {
    final session = _sessions[configId];
    if (session != null) {
      await session.disconnect();
      _sessions.remove(configId);
    }
  }

  static Future<void> disconnectAll() async {
    final futures = _sessions.values.map((session) => session.disconnect());
    await Future.wait(futures);
    _sessions.clear();
  }

  static List<String> getActiveConnections() {
    return _sessions.entries
        .where((entry) => entry.value.status == ConnectionStatus.connected)
        .map((entry) => entry.key)
        .toList();
  }

  static Map<String, ConnectionStatus> getAllConnectionStatus() {
    return _sessions.map((key, session) => MapEntry(key, session.status));
  }
}
