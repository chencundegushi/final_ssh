import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/ssh_config.dart';
import '../providers/ssh_config_provider.dart';
import '../../services/ssh_service.dart';

class TerminalPage extends StatefulWidget {
  final SSHConfig config;

  const TerminalPage({super.key, required this.config});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final _commandController = TextEditingController();
  final _scrollController = ScrollController();
  final List<String> _output = [];
  final List<String> _commandHistory = [];
  int _historyIndex = -1;
  bool _isConnected = false;
  bool _isConnecting = false;
  
  SSHConfigProvider? _provider; // 添加Provider引用

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectToServer();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<SSHConfigProvider>();
  }

  Future<void> _connectToServer() async {
    setState(() {
      _isConnecting = true;
    });

    final provider = context.read<SSHConfigProvider>();
    
    _addOutput('正在连接到 ${widget.config.host}:${widget.config.port}...');
    _addOutput('用户名: ${widget.config.username}');
    _addOutput('认证方式: ${widget.config.authType == AuthType.password ? '密码' : '私钥'}');
    
    final success = await provider.connect(widget.config);
    
    setState(() {
      _isConnecting = false;
      _isConnected = success;
    });

    if (success) {
      _addOutput('✓ 连接成功！');
      // 监听输出流
      SSHService.getOutputStream(widget.config.id)?.listen((output) {
        _addOutput(output);
      });
    } else {
      _addOutput('✗ 连接失败');
      _addOutput('可能的原因:');
      _addOutput('1. 服务器地址或端口错误');
      _addOutput('2. 网络连接问题');
      _addOutput('3. 认证信息错误');
      _addOutput('4. 服务器拒绝连接');
      _addOutput('5. 防火墙阻止连接');
    }
  }

  void _addOutput(String text) {
    setState(() {
      _output.add(text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _executeCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;

    _addOutput('\$ $command');
    _commandHistory.insert(0, command);
    _historyIndex = -1;
    _commandController.clear();

    if (!_isConnected) {
      _addOutput('错误: 未连接到服务器');
      return;
    }

    try {
      final output = await SSHService.executeCommand(widget.config.id, command);
      if (output.isNotEmpty) {
        _addOutput(output);
      } else {
        _addOutput('(命令执行完成，无输出)');
      }
    } catch (e) {
      _addOutput('命令执行错误: $e');
    }
  }

  void _navigateHistory(bool up) {
    if (_commandHistory.isEmpty) return;

    if (up) {
      if (_historyIndex < _commandHistory.length - 1) {
        _historyIndex++;
        _commandController.text = _commandHistory[_historyIndex];
      }
    } else {
      if (_historyIndex > 0) {
        _historyIndex--;
        _commandController.text = _commandHistory[_historyIndex];
      } else if (_historyIndex == 0) {
        _historyIndex = -1;
        _commandController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config.name),
        backgroundColor: _isConnected 
            ? Colors.green 
            : _isConnecting 
                ? Colors.orange 
                : Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _output.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 连接状态指示器
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: _isConnected 
                ? Colors.green.withOpacity(0.1)
                : _isConnecting 
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
            child: Text(
              _isConnecting 
                  ? '正在连接...' 
                  : _isConnected 
                      ? '已连接' 
                      : '连接失败',
              style: TextStyle(
                color: _isConnected 
                    ? Colors.green 
                    : _isConnecting 
                        ? Colors.orange 
                        : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 输出区域
          Expanded(
            child: Container(
              color: Colors.black,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _output.length,
                itemBuilder: (context, index) {
                  return SelectableText(
                    _output[index],
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  );
                },
              ),
            ),
          ),
          // 命令输入区域
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                // 历史记录按钮
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed: () => _navigateHistory(true),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: () => _navigateHistory(false),
                ),
                // 命令输入框
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    enabled: _isConnected,
                    decoration: const InputDecoration(
                      hintText: '输入命令...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _executeCommand(),
                  ),
                ),
                const SizedBox(width: 8),
                // 发送按钮
                ElevatedButton(
                  onPressed: _isConnected ? _executeCommand : null,
                  child: const Text('发送'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    // 安全地断开连接
    _provider?.disconnect(widget.config.id);
    super.dispose();
  }
}
