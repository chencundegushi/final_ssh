import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ssh_config_provider.dart';
import '../widgets/ssh_config_card.dart';
import 'config_edit_page.dart';
import '../../services/ssh_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SSHConfigProvider>().loadConfigs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Final SSH'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _disconnectAll,
            icon: const Icon(Icons.power_off),
            tooltip: '断开所有连接',
          ),
        ],
      ),
      body: Consumer<SSHConfigProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.configs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.computer, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '暂无SSH配置',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '点击右下角按钮添加SSH连接',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.configs.length,
            itemBuilder: (context, index) {
              final config = provider.configs[index];
              return SSHConfigCard(
                config: config,
                onTap: () => _connectToServer(config),
                onEdit: () => _editConfig(config),
                onDelete: () => _deleteConfig(config),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewConfig,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addNewConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConfigEditPage(),
      ),
    );
  }

  void _editConfig(config) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfigEditPage(config: config),
      ),
    );
  }

  void _deleteConfig(config) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除配置'),
        content: Text('确定要删除配置 "${config.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<SSHConfigProvider>().deleteConfig(config.id);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _connectToServer(config) {
    Navigator.pushNamed(context, '/terminal', arguments: config);
  }

  Future<void> _disconnectAll() async {
    final provider = context.read<SSHConfigProvider>();
    
    // 获取所有连接的配置ID并断开
    for (final config in provider.configs) {
      if (SSHService.isConnected(config.id)) {
        await SSHService.disconnect(config.id);
        await provider.disconnect(config.id);
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已断开所有连接')),
      );
    }
  }
}
