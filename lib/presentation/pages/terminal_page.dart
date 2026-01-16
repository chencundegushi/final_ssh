import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/command_panel.dart';
import '../widgets/command_import_dialog.dart';
import '../providers/ssh_config_provider.dart';
import '../../services/command_service.dart';
import '../../services/ssh_service.dart';
import '../../data/repositories/command_repository.dart';
import '../../data/models/ssh_config.dart';

class TerminalPage extends StatefulWidget {
  final String configId;
  final String configName;

  const TerminalPage({
    Key? key,
    required this.configId,
    required this.configName,
  }) : super(key: key);

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _outputController = ScrollController();
  late final CommandService _commandService;
  String _output = '';
  bool _showCommandPanel = false;

  @override
  void initState() {
    super.initState();
    _commandService = CommandService(CommandRepositoryImpl());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectToSSH();
    });
  }

  Future<void> _connectToSSH() async {
    // 获取SSH配置并建立连接
    final provider = context.read<SSHConfigProvider>();
    final config = provider.configs.firstWhere(
      (c) => c.id == widget.configId,
      orElse: () => throw Exception('Config not found'),
    );
    
    setState(() {
      _output += 'Connecting to ${config.host}...\n';
    });
    
    final success = await provider.connect(config);
    if (success) {
      setState(() {
        _output += 'Connected successfully!\n';
      });
      _listenToOutput();
    } else {
      setState(() {
        _output += 'Connection failed!\n';
      });
    }
  }

  void _listenToOutput() {
    final outputStream = SSHService.getOutputStream(widget.configId);
    outputStream?.listen((output) {
      if (mounted) {
        setState(() {
          _output += output;
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_outputController.hasClients) {
        _outputController.animateTo(
          _outputController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.configName),
        actions: [
          IconButton(
            onPressed: _showImportDialog,
            icon: const Icon(Icons.file_upload),
            tooltip: '导入命令',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _showCommandPanel = !_showCommandPanel;
              });
            },
            icon: Icon(_showCommandPanel ? Icons.keyboard_hide : Icons.keyboard),
            tooltip: '切换命令面板',
          ),
          IconButton(
            onPressed: _disconnect,
            icon: const Icon(Icons.power_off),
            tooltip: '断开连接',
          ),
        ],
      ),
      body: Column(
        children: [
          // 输出区域
          Expanded(
            flex: _showCommandPanel ? 2 : 3,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black,
              child: SingleChildScrollView(
                controller: _outputController,
                child: SelectableText(
                  _output,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          
          // 命令面板
          if (_showCommandPanel)
            Expanded(
              flex: 1,
              child: CommandPanel(
                commandService: _commandService,
                onCommandSelected: (command) {
                  _commandController.text = command;
                },
              ),
            ),
          
          // 输入区域
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    decoration: const InputDecoration(
                      hintText: '输入命令...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: _executeCommand,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _executeCommand(_commandController.text),
                  child: const Text('发送'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _stopCommand,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('停止'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _stopCommand() async {
    await SSHService.cancelCommand(widget.configId);
    setState(() {
      _output += '\n[命令已停止]\n';
    });
  }

  Future<void> _executeCommand(String command) async {
    if (command.trim().isEmpty) return;

    if (!SSHService.isConnected(widget.configId)) {
      setState(() {
        _output += 'Error: Not connected\n';
      });
      return;
    }

    setState(() {
      _output += '\$ $command\n';
    });

    try {
      await SSHService.executeCommand(widget.configId, command);
      _commandController.clear();
    } catch (e) {
      setState(() {
        _output += 'Error: $e\n';
      });
    }
  }

  Future<void> _disconnect() async {
    await SSHService.disconnect(widget.configId);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showImportDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CommandImportDialog(
        commandService: _commandService,
      ),
    );

    if (result == true) {
      // 刷新命令面板
      setState(() {});
    }
  }

  @override
  void dispose() {
    _commandController.dispose();
    _outputController.dispose();
    super.dispose();
  }
}
