import 'package:flutter/material.dart';
import '../../data/models/common_command.dart';
import '../../services/command_service.dart';

class CommandImportDialog extends StatefulWidget {
  final CommandService commandService;

  const CommandImportDialog({
    Key? key,
    required this.commandService,
  }) : super(key: key);

  @override
  State<CommandImportDialog> createState() => _CommandImportDialogState();
}

class _CommandImportDialogState extends State<CommandImportDialog> {
  final TextEditingController _textController = TextEditingController();
  List<CommonCommand> _previewCommands = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入常用命令'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _importFromFile,
                    icon: const Icon(Icons.file_upload, size: 16),
                    label: const Text('从文件导入', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _previewFromText,
                    icon: const Icon(Icons.preview, size: 16),
                    label: const Text('预览', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: '在此输入命令，每行一个命令...\n例如：\nls -la\nps aux\ndf -h',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                expands: true,
              ),
            ),
            const SizedBox(height: 16),
            if (_previewCommands.isNotEmpty) ...[
              const Text('预览命令:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListView.builder(
                    itemCount: _previewCommands.length,
                    itemBuilder: (context, index) {
                      final command = _previewCommands[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          command.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          command.command,
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 16),
                          onPressed: () {
                            setState(() {
                              _previewCommands.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _previewCommands.isEmpty || _isLoading ? null : _importCommands,
          child: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('导入'),
        ),
      ],
    );
  }

  Future<void> _importFromFile() async {
    setState(() => _isLoading = true);
    
    try {
      final commands = await widget.commandService.importCommandsFromFile();
      setState(() {
        _previewCommands = commands;
        _textController.text = commands.map((cmd) => cmd.command).join('\n');
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _previewFromText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final commands = widget.commandService.parseCommandsFromText(text);
    setState(() {
      _previewCommands = commands;
    });
  }

  Future<void> _importCommands() async {
    setState(() => _isLoading = true);
    
    try {
      await widget.commandService.importCommands(_previewCommands);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功导入 ${_previewCommands.length} 个命令')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
