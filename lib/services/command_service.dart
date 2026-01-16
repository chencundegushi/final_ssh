import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../data/models/common_command.dart';
import '../data/repositories/command_repository.dart';

class CommandService {
  final CommandRepository _repository;

  CommandService(this._repository);

  Future<List<CommonCommand>> getAllCommands() async {
    return await _repository.getAllCommands();
  }

  Future<List<CommonCommand>> getCommandsByCategory(String category) async {
    return await _repository.getCommandsByCategory(category);
  }

  Future<List<CommonCommand>> searchCommands(String query) async {
    final allCommands = await _repository.getAllCommands();
    return allCommands.where((cmd) => 
      cmd.name.toLowerCase().contains(query.toLowerCase()) ||
      cmd.command.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Future<void> addCommand(CommonCommand command) async {
    await _repository.saveCommand(command);
  }

  Future<void> updateCommandUsage(String commandId) async {
    await _repository.updateUsageCount(commandId);
  }

  Future<void> deleteCommand(String commandId) async {
    await _repository.deleteCommand(commandId);
  }

  Future<List<CommonCommand>> importCommandsFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'sh', 'cmd'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        return parseCommandsFromText(content);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to import commands: $e');
    }
  }

  List<CommonCommand> parseCommandsFromText(String text) {
    final lines = text.split('\n');
    final commands = <CommonCommand>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      
      final command = CommonCommand(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
        name: _generateCommandName(line),
        command: line,
        description: _extractDescription(line),
        category: 'imported',
        createdAt: DateTime.now(),
      );
      commands.add(command);
    }
    
    return commands;
  }

  Future<void> importCommands(List<CommonCommand> commands) async {
    for (final command in commands) {
      await _repository.saveCommand(command);
    }
  }

  String _generateCommandName(String command) {
    final parts = command.split(' ');
    if (parts.isNotEmpty) {
      return parts[0].replaceAll(RegExp(r'[^\w]'), '');
    }
    return 'command';
  }

  String? _extractDescription(String command) {
    if (command.contains('#')) {
      final parts = command.split('#');
      if (parts.length > 1) {
        return parts[1].trim();
      }
    }
    return null;
  }

  Future<List<String>> getCategories() async {
    final commands = await _repository.getAllCommands();
    final categories = commands.map((cmd) => cmd.category).toSet().toList();
    categories.sort();
    return categories;
  }

  Future<List<CommonCommand>> getMostUsedCommands({int limit = 10}) async {
    final commands = await _repository.getAllCommands();
    commands.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return commands.take(limit).toList();
  }

  List<CommonCommand> getDefaultCommands() {
    final now = DateTime.now();
    return [
      CommonCommand(
        id: 'default_top',
        name: '系统进程监控',
        command: 'top -n 1',
        description: '查看系统进程和资源使用情况',
        category: '系统监控',
        createdAt: now,
      ),
      CommonCommand(
        id: 'default_df',
        name: '磁盘使用情况',
        command: 'df -h',
        description: '查看磁盘空间使用情况',
        category: '系统监控',
        createdAt: now,
      ),
      CommonCommand(
        id: 'default_free',
        name: '内存使用情况',
        command: 'free -h',
        description: '查看内存使用情况',
        category: '系统监控',
        createdAt: now,
      ),
      CommonCommand(
        id: 'default_k8s_pods',
        name: '查看所有Pod',
        command: 'kubectl get pods -A',
        description: '查看所有命名空间的Pod',
        category: 'Kubernetes',
        createdAt: now,
      ),
      CommonCommand(
        id: 'default_k8s_logs',
        name: '查看Pod日志',
        command: 'kubectl logs -f --tail 200 ',
        description: '实时查看Pod日志（需补充Pod名称）',
        category: 'Kubernetes',
        createdAt: now,
      ),
      CommonCommand(
        id: 'default_docker_ps',
        name: '查看运行容器',
        command: 'docker ps',
        description: '查看正在运行的容器',
        category: 'Docker',
        createdAt: now,
      ),
      CommonCommand(
        id: 'default_docker_logs',
        name: '查看容器日志',
        command: 'docker logs -f --tail 200 ',
        description: '实时查看容器日志（需补充容器ID）',
        category: 'Docker',
        createdAt: now,
      ),
      CommonCommand(
        id: 'default_tail',
        name: '实时查看日志',
        command: 'tail -f ',
        description: '实时查看文件内容（需补充文件路径）',
        category: '日志查看',
        createdAt: now,
      ),
    ];
  }

  Future<void> initializeDefaultCommands() async {
    final existingCommands = await _repository.getAllCommands();
    if (existingCommands.isEmpty) {
      final defaultCommands = getDefaultCommands();
      for (final command in defaultCommands) {
        await _repository.saveCommand(command);
      }
    }
  }
}
