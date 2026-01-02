import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/ssh_config.dart';
import '../providers/ssh_config_provider.dart';
import '../../services/encryption_service.dart';

class ConfigEditPage extends StatefulWidget {
  final SSHConfig? config;

  const ConfigEditPage({super.key, this.config});

  @override
  State<ConfigEditPage> createState() => _ConfigEditPageState();
}

class _ConfigEditPageState extends State<ConfigEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  AuthType _authType = AuthType.password;
  String? _privateKeyPath;
  String? _privateKeyContent; // 添加私钥内容变量
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.config != null) {
      _nameController.text = widget.config!.name;
      _hostController.text = widget.config!.host;
      _portController.text = widget.config!.port.toString();
      _usernameController.text = widget.config!.username;
      _authType = widget.config!.authType;
      _privateKeyPath = widget.config!.privateKeyPath;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config == null ? '添加SSH配置' : '编辑SSH配置'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveConfig,
            child: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '配置名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入配置名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: '主机地址',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入主机地址';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: '端口',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入端口';
                }
                final port = int.tryParse(value);
                if (port == null || port < 1 || port > 65535) {
                  return '请输入有效的端口号 (1-65535)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入用户名';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text('认证方式', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RadioListTile<AuthType>(
              title: const Text('密码认证'),
              value: AuthType.password,
              groupValue: _authType,
              onChanged: (value) {
                setState(() {
                  _authType = value!;
                });
              },
            ),
            RadioListTile<AuthType>(
              title: const Text('私钥认证'),
              value: AuthType.privateKey,
              groupValue: _authType,
              onChanged: (value) {
                setState(() {
                  _authType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_authType == AuthType.password) ...[
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '密码',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  return null;
                },
              ),
            ] else ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.vpn_key),
                  title: Text(_privateKeyPath ?? '选择私钥文件'),
                  trailing: const Icon(Icons.folder_open),
                  onTap: _pickPrivateKey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickPrivateKey() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // 改为any类型，支持更多文件
        allowMultiple: false,
        withData: true, // 获取文件数据
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        // 检查文件扩展名
        final fileName = file.name.toLowerCase();
        if (fileName.endsWith('.pem') || 
            fileName.endsWith('.key') || 
            fileName.endsWith('.ppk') ||
            fileName.contains('key')) {
          setState(() {
            _privateKeyPath = file.name;
            _privateKeyContent = String.fromCharCodes(file.bytes!); // 存储文件内容
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请选择有效的私钥文件 (.pem, .key, .ppk)')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择文件失败: $e')),
      );
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_authType == AuthType.privateKey && (_privateKeyPath == null || _privateKeyPath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择私钥文件')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<SSHConfigProvider>();
      
      if (widget.config == null) {
        // 添加新配置
        final config = provider.createNewConfig(
          name: _nameController.text,
          host: _hostController.text,
          port: int.parse(_portController.text),
          username: _usernameController.text,
          authType: _authType,
          privateKeyPath: _privateKeyPath,
        );
        
        if (_authType == AuthType.password) {
          await EncryptionService.storePassword(config.id, _passwordController.text);
        } else if (_privateKeyContent != null) {
          // 存储私钥文件内容
          await EncryptionService.storePrivateKey(config.id, _privateKeyContent!);
        }
        
        await provider.addConfig(config);
      } else {
        // 更新配置
        final updatedConfig = widget.config!.copyWith(
          name: _nameController.text,
          host: _hostController.text,
          port: int.parse(_portController.text),
          username: _usernameController.text,
          authType: _authType,
          privateKeyPath: _privateKeyPath,
        );
        
        if (_authType == AuthType.password && _passwordController.text.isNotEmpty) {
          await EncryptionService.storePassword(updatedConfig.id, _passwordController.text);
        }
        
        await provider.updateConfig(updatedConfig);
      }
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
