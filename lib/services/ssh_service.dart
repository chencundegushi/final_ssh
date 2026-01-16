import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dartssh2/dartssh2.dart';
import '../data/models/ssh_config.dart';
import 'encryption_service.dart';

class SSHService {
  static final Map<String, SSHClient> _clients = {};
  static final Map<String, StreamController<String>> _outputControllers = {};
  static final Map<String, StreamSubscription> _subscriptions = {};

  static Future<bool> connect(SSHConfig config) async {
    try {
      debugPrint('=== SSH连接开始 ===');
      debugPrint('主机: ${config.host}:${config.port}');
      debugPrint('用户名: ${config.username}');
      debugPrint('认证类型: ${config.authType.name}');
      debugPrint('配置ID: ${config.id}');
      debugPrint('==================');
      
      // 创建socket连接
      final socket = await SSHSocket.connect(
        config.host, 
        config.port,
        timeout: const Duration(seconds: 10),
      );
      
      debugPrint('Socket连接成功，开始SSH握手');
      
      // 创建SSH客户端
      SSHClient client;
      
      if (config.authType == AuthType.privateKey) {
        // 私钥认证
        debugPrint('=== 私钥认证流程 ===');
        debugPrint('配置ID: ${config.id}');
        debugPrint('私钥路径: ${config.privateKeyPath}');
        
        final privateKeyContent = await EncryptionService.getPrivateKey(config.id);
        if (privateKeyContent == null || privateKeyContent.isEmpty) {
          debugPrint('私钥获取失败 - 内容为空或null');
          debugPrint('回退到密码认证');
          return false;
        }
        
        debugPrint('使用私钥认证，用户名: ${config.username}');
        debugPrint('私钥内容长度: ${privateKeyContent.length}');
        
        // 清理和验证私钥内容
        String cleanedKey = privateKeyContent.trim();
        
        // 确保每行都正确结束
        List<String> lines = cleanedKey.split('\n');
        for (int i = 0; i < lines.length; i++) {
          lines[i] = lines[i].trim();
        }
        cleanedKey = lines.join('\n');
        
        // 验证PEM格式
        if (!cleanedKey.startsWith('-----BEGIN')) {
          debugPrint('私钥格式错误：缺少BEGIN标头');
          socket.close();
          return false;
        }
        if (!cleanedKey.endsWith('-----')) {
          debugPrint('私钥格式错误：缺少END标尾');
          socket.close();
          return false;
        }
        
        debugPrint('私钥格式验证通过，行数: ${lines.length}');
        
        try {
          final keyPairs = SSHKeyPair.fromPem(cleanedKey);
          debugPrint('成功解析私钥，找到 ${keyPairs.length} 个密钥对');
          
          client = SSHClient(
            socket,
            username: config.username,
            identities: keyPairs,
          );
        } catch (keyError, keyStackTrace) {
          debugPrint('=== 私钥解析失败 ===');
          debugPrint('错误: $keyError');
          debugPrint('私钥开头: ${cleanedKey.substring(0, cleanedKey.length > 50 ? 50 : cleanedKey.length)}');
          debugPrint('私钥结尾: ${cleanedKey.substring(cleanedKey.length > 50 ? cleanedKey.length - 50 : 0)}');
          debugPrint('私钥总行数: ${cleanedKey.split('\n').length}');
          debugPrint('堆栈跟踪: $keyStackTrace');
          debugPrint('==================');
          socket.close();
          return false;
        }
      } else {
        // 密码认证
        client = SSHClient(
          socket,
          username: config.username,
          onPasswordRequest: () async {
            debugPrint('服务器请求密码认证');
            final password = await EncryptionService.getPassword(config.id);
            debugPrint('密码获取${password != null ? '成功' : '失败'}');
            return password ?? '';
          },
        );
      }

      _clients[config.id] = client;
      _outputControllers[config.id] = StreamController<String>.broadcast();
      
      debugPrint('SSH连接建立成功');
      return true;
    } catch (e, stackTrace) {
      debugPrint('=== SSH连接失败详细日志 ===');
      debugPrint('错误信息: $e');
      debugPrint('错误类型: ${e.runtimeType}');
      debugPrint('连接配置:');
      debugPrint('  - 主机: ${config.host}:${config.port}');
      debugPrint('  - 用户名: ${config.username}');
      debugPrint('  - 认证方式: ${config.authType}');
      debugPrint('堆栈跟踪:');
      debugPrint('$stackTrace');
      
      // 特殊处理认证失败
      if (e.toString().contains('SSHAuthFailError') || e.toString().contains('Authentication failed')) {
        debugPrint('=== 认证失败排查建议 ===');
        debugPrint('1. 用户名检查 (AWS EC2常用: ubuntu, ec2-user, admin, centos)');
        debugPrint('2. 私钥文件是否正确完整');
        debugPrint('3. 私钥是否与EC2实例密钥对匹配');
        debugPrint('4. EC2安全组是否允许SSH(22端口)访问');
      }
      debugPrint('========================');
      
      return false;
    }
  }

  static Future<void> disconnect(String configId) async {
    await cancelCommand(configId);
    
    final client = _clients[configId];
    if (client != null) {
      client.close();
      _clients.remove(configId);
    }
    
    final controller = _outputControllers[configId];
    if (controller != null) {
      await controller.close();
      _outputControllers.remove(configId);
    }
  }

  static Future<void> cancelCommand(String configId) async {
    final subscription = _subscriptions[configId];
    if (subscription != null) {
      await subscription.cancel();
      _subscriptions.remove(configId);
    }
  }

  static Future<String> executeCommand(String configId, String command) async {
    final client = _clients[configId];
    if (client == null) {
      throw Exception('Not connected');
    }

    await cancelCommand(configId);

    try {
      debugPrint('原始命令: $command');
      
      String wrappedCommand;
      if (command.startsWith('dt ')) {
        wrappedCommand = '''bash -c "
source ~/.bashrc 2>/dev/null || true
source ~/.bash_profile 2>/dev/null || true  
source ~/.profile 2>/dev/null || true
shopt -s expand_aliases 2>/dev/null || true
$command
"''';
      } else {
        wrappedCommand = 'bash -l -c "$command"'.replaceAll('$command', command);
      }
      
      debugPrint('包装后命令: $wrappedCommand');
      
      final session = await client.execute(wrappedCommand);
      final completer = Completer<String>();
      final outputBuffer = StringBuffer();
      
      // 监听 stdout
      final stdoutSub = session.stdout.listen(
        (data) {
          try {
            final text = utf8.decode(data);
            outputBuffer.write(text);
            _outputControllers[configId]?.add(text);
          } catch (e) {
            final text = latin1.decode(data);
            outputBuffer.write(text);
            _outputControllers[configId]?.add(text);
          }
        },
        onDone: () {
          debugPrint('stdout 流结束');
        },
      );
      
      // 监听 stderr
      final stderrSub = session.stderr.listen(
        (data) {
          try {
            final text = 'STDERR: ${utf8.decode(data)}';
            outputBuffer.write('\n$text');
            _outputControllers[configId]?.add(text);
          } catch (e) {
            final text = 'STDERR: ${latin1.decode(data)}';
            outputBuffer.write('\n$text');
            _outputControllers[configId]?.add(text);
          }
        },
        onDone: () {
          debugPrint('stderr 流结束');
          if (!completer.isCompleted) {
            completer.complete(outputBuffer.toString());
          }
        },
      );
      
      _subscriptions[configId] = stdoutSub;
      
      return completer.future;
    } catch (e) {
      debugPrint('命令执行失败: $e');
      final error = 'Error: $e';
      _outputControllers[configId]?.add(error);
      return error;
    }
  }

  static Stream<String>? getOutputStream(String configId) {
    return _outputControllers[configId]?.stream;
  }

  static bool isConnected(String configId) {
    return _clients.containsKey(configId);
  }
}
