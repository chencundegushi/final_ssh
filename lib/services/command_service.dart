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
}
