import 'package:flutter/material.dart';
import '../../services/ssh_session_manager.dart';

class ConnectionManagerWidget extends StatefulWidget {
  final List<String> configIds;
  final Map<String, String> configNames;
  final VoidCallback? onConnectionsChanged;

  const ConnectionManagerWidget({
    Key? key,
    required this.configIds,
    required this.configNames,
    this.onConnectionsChanged,
  }) : super(key: key);

  @override
  State<ConnectionManagerWidget> createState() => _ConnectionManagerWidgetState();
}

class _ConnectionManagerWidgetState extends State<ConnectionManagerWidget> {
  Set<String> _selectedConfigs = {};
  bool _isMultiSelectMode = false;

  @override
  Widget build(BuildContext context) {
    final connectionStatus = SSHSessionManager.getAllConnectionStatus();
    final activeConnections = SSHSessionManager.getActiveConnections();

    return Column(
      children: [
        _buildHeader(activeConnections.length),
        if (_isMultiSelectMode) _buildMultiSelectActions(),
        Expanded(
          child: ListView.builder(
            itemCount: widget.configIds.length,
            itemBuilder: (context, index) {
              final configId = widget.configIds[index];
              final configName = widget.configNames[configId] ?? configId;
              final status = connectionStatus[configId] ?? ConnectionStatus.disconnected;
              
              return _buildConnectionItem(configId, configName, status);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(int activeCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi,
            color: activeCount > 0 ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            '活跃连接: $activeCount',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (activeCount > 0)
            ElevatedButton.icon(
              onPressed: _disconnectAll,
              icon: const Icon(Icons.power_off, size: 16),
              label: const Text('全部断开'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              setState(() {
                _isMultiSelectMode = !_isMultiSelectMode;
                _selectedConfigs.clear();
              });
            },
            icon: Icon(_isMultiSelectMode ? Icons.close : Icons.checklist),
            tooltip: _isMultiSelectMode ? '退出多选' : '多选模式',
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectActions() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Text('已选择: ${_selectedConfigs.length}'),
          const Spacer(),
          TextButton(
            onPressed: _selectedConfigs.isEmpty ? null : _selectAll,
            child: const Text('全选'),
          ),
          TextButton(
            onPressed: _selectedConfigs.isEmpty ? null : _clearSelection,
            child: const Text('清除'),
          ),
          ElevatedButton(
            onPressed: _selectedConfigs.isEmpty ? null : _disconnectSelected,
            child: const Text('断开选中'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionItem(String configId, String configName, ConnectionStatus status) {
    final isSelected = _selectedConfigs.contains(configId);
    final isConnected = status == ConnectionStatus.connected;

    return ListTile(
      leading: _isMultiSelectMode
          ? Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedConfigs.add(configId);
                  } else {
                    _selectedConfigs.remove(configId);
                  }
                });
              },
            )
          : _buildStatusIcon(status),
      title: Text(configName),
      subtitle: Text(_getStatusText(status)),
      trailing: isConnected
          ? IconButton(
              onPressed: () => _disconnectSingle(configId),
              icon: const Icon(Icons.power_off, color: Colors.red),
              tooltip: '断开连接',
            )
          : null,
      onTap: _isMultiSelectMode
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedConfigs.remove(configId);
                } else {
                  _selectedConfigs.add(configId);
                }
              });
            }
          : null,
      selected: _isMultiSelectMode && isSelected,
    );
  }

  Widget _buildStatusIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return const Icon(Icons.circle, color: Colors.green, size: 12);
      case ConnectionStatus.connecting:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case ConnectionStatus.error:
        return const Icon(Icons.circle, color: Colors.red, size: 12);
      case ConnectionStatus.disconnected:
        return const Icon(Icons.circle, color: Colors.grey, size: 12);
    }
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return '已连接';
      case ConnectionStatus.connecting:
        return '连接中...';
      case ConnectionStatus.error:
        return '连接错误';
      case ConnectionStatus.disconnected:
        return '未连接';
    }
  }

  Future<void> _disconnectAll() async {
    final confirmed = await _showConfirmDialog('确定要断开所有连接吗？');
    if (confirmed) {
      await SSHSessionManager.disconnectAll();
      widget.onConnectionsChanged?.call();
      setState(() {});
    }
  }

  Future<void> _disconnectSingle(String configId) async {
    await SSHSessionManager.disconnectSession(configId);
    widget.onConnectionsChanged?.call();
    setState(() {});
  }

  Future<void> _disconnectSelected() async {
    final confirmed = await _showConfirmDialog('确定要断开选中的 ${_selectedConfigs.length} 个连接吗？');
    if (confirmed) {
      for (final configId in _selectedConfigs) {
        await SSHSessionManager.disconnectSession(configId);
      }
      widget.onConnectionsChanged?.call();
      setState(() {
        _selectedConfigs.clear();
      });
    }
  }

  void _selectAll() {
    setState(() {
      _selectedConfigs = Set.from(widget.configIds);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedConfigs.clear();
    });
  }

  Future<bool> _showConfirmDialog(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认操作'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
