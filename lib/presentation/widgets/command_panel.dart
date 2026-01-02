import 'package:flutter/material.dart';
import '../../data/models/common_command.dart';
import '../../services/command_service.dart';

class CommandPanel extends StatefulWidget {
  final Function(String) onCommandSelected;
  final CommandService commandService;

  const CommandPanel({
    Key? key,
    required this.onCommandSelected,
    required this.commandService,
  }) : super(key: key);

  @override
  State<CommandPanel> createState() => _CommandPanelState();
}

class _CommandPanelState extends State<CommandPanel> {
  List<CommonCommand> _commands = [];
  List<CommonCommand> _filteredCommands = [];
  String _searchQuery = '';
  String _selectedCategory = 'all';
  List<String> _categories = ['all'];

  @override
  void initState() {
    super.initState();
    _loadCommands();
  }

  Future<void> _loadCommands() async {
    final commands = await widget.commandService.getAllCommands();
    final categories = await widget.commandService.getCategories();
    
    setState(() {
      _commands = commands;
      _filteredCommands = commands;
      _categories = ['all', ...categories];
    });
  }

  void _filterCommands() {
    setState(() {
      _filteredCommands = _commands.where((cmd) {
        final matchesSearch = _searchQuery.isEmpty ||
            cmd.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            cmd.command.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesCategory = _selectedCategory == 'all' ||
            cmd.category == _selectedCategory;
        
        return matchesSearch && matchesCategory;
      }).toList();
      
      // Sort by usage count
      _filteredCommands.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildSearchAndFilter(),
          Expanded(child: _buildCommandList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.terminal, size: 16),
          const SizedBox(width: 8),
          const Text('常用命令', style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 16),
            onPressed: _loadCommands,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 32,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: '搜索命令...',
                  prefixIcon: Icon(Icons.search, size: 16),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  isDense: true,
                ),
                onChanged: (value) {
                  _searchQuery = value;
                  _filterCommands();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: DropdownButton<String>(
              value: _selectedCategory,
              isDense: true,
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? 'all';
                });
                _filterCommands();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandList() {
    if (_filteredCommands.isEmpty) {
      return const Center(
        child: Text('暂无命令', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: _filteredCommands.length,
      itemBuilder: (context, index) {
        final command = _filteredCommands[index];
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          visualDensity: VisualDensity.compact,
          title: Text(
            command.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            command.command,
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '${command.usageCount}',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          onTap: () async {
            widget.onCommandSelected(command.command);
            await widget.commandService.updateCommandUsage(command.id);
            _loadCommands(); // Refresh to update usage count
          },
        );
      },
    );
  }
}
