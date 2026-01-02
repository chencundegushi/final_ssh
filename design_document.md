# Final SSH - 代码设计文档

## 1. 系统架构

### 1.1 整体架构
```
┌─────────────────────────────────────────┐
│                UI Layer                 │
│  ┌─────────────┐  ┌─────────────────────┐│
│  │   Pages     │  │    Widgets          ││
│  └─────────────┘  └─────────────────────┘│
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│            Business Layer               │
│  ┌─────────────┐  ┌─────────────────────┐│
│  │ Providers   │  │    Services         ││
│  └─────────────┘  └─────────────────────┘│
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│              Data Layer                 │
│  ┌─────────────┐  ┌─────────────────────┐│
│  │ Repository  │  │    Models           ││
│  └─────────────┘  └─────────────────────┘│
└─────────────────────────────────────────┘
```

### 1.2 技术栈
- **框架**: Flutter 3.0+
- **状态管理**: Provider
- **本地存储**: SQLite (sqflite)
- **安全存储**: flutter_secure_storage
- **SSH连接**: dartssh2
- **路由**: go_router

## 2. 项目结构

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── routes.dart
├── core/
│   ├── constants/
│   ├── utils/
│   ├── exceptions/
│   └── extensions/
├── data/
│   ├── models/
│   ├── repositories/
│   ├── datasources/
│   └── database/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── pages/
│   ├── widgets/
│   ├── providers/
│   └── themes/
└── services/
    ├── ssh_service.dart
    ├── encryption_service.dart
    ├── storage_service.dart
    └── file_service.dart
```

## 3. 数据模型设计

### 3.1 SSH配置模型
```dart
class SSHConfig {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final AuthType authType;
  final String? password;
  final String? privateKeyPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // 构造函数、序列化方法等
}

enum AuthType { password, privateKey }
```

### 3.2 连接会话模型
```dart
class SSHSession {
  final String configId;
  final SSHClient client;
  final ConnectionStatus status;
  final DateTime connectedAt;
  final List<CommandHistory> history;
  
  // 方法定义
}

enum ConnectionStatus { 
  disconnected, 
  connecting, 
  connected, 
  error 
}
```

### 3.3 常用命令模型
```dart
class CommonCommand {
  final String id;
  final String name;
  final String command;
  final String? description;
  final String category;
  final int usageCount;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  
  // 构造函数、序列化方法等
}

class CommandCategory {
  final String id;
  final String name;
  final String? description;
  final int order;
}
```
```dart
class CommandHistory {
  final String command;
  final String output;
  final DateTime executedAt;
  final bool isError;
}
```

## 4. 数据层设计

### 4.1 数据库设计
```sql
-- SSH配置表
CREATE TABLE ssh_configs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  host TEXT NOT NULL,
  port INTEGER DEFAULT 22,
  username TEXT NOT NULL,
  auth_type TEXT NOT NULL,
  private_key_path TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- 常用命令表
CREATE TABLE common_commands (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  command TEXT NOT NULL,
  description TEXT,
  category TEXT DEFAULT 'default',
  usage_count INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  last_used_at INTEGER
);

-- 命令分类表
CREATE TABLE command_categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  order_index INTEGER DEFAULT 0
);

-- 命令历史表
CREATE TABLE command_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  config_id TEXT NOT NULL,
  command TEXT NOT NULL,
  output TEXT,
  executed_at INTEGER NOT NULL,
  is_error INTEGER DEFAULT 0,
  FOREIGN KEY (config_id) REFERENCES ssh_configs (id)
);
```

### 4.2 Repository接口
```dart
abstract class SSHConfigRepository {
  Future<List<SSHConfig>> getAllConfigs();
  Future<SSHConfig?> getConfigById(String id);
  Future<void> saveConfig(SSHConfig config);
  Future<void> deleteConfig(String id);
  Future<void> updateConfig(SSHConfig config);
}

abstract class CommandHistoryRepository {
  Future<List<CommandHistory>> getHistory(String configId);
  Future<void> saveCommand(String configId, CommandHistory command);
  Future<void> clearHistory(String configId);
}

abstract class CommonCommandRepository {
  Future<List<CommonCommand>> getAllCommands();
  Future<List<CommonCommand>> getCommandsByCategory(String category);
  Future<void> saveCommand(CommonCommand command);
  Future<void> deleteCommand(String id);
  Future<void> updateUsageCount(String id);
  Future<void> importCommands(List<String> commands);
}
```

## 5. 服务层设计

### 5.1 SSH服务
```dart
class SSHService {
  static final Map<String, SSHSession> _sessions = {};
  
  Future<SSHSession> connect(SSHConfig config);
  Future<void> disconnect(String configId);
  Future<String> executeCommand(String configId, String command);
  Stream<String> getOutputStream(String configId);
  bool isConnected(String configId);
}
```

### 5.2 加密服务
```dart
class EncryptionService {
  static const String _passwordKey = 'ssh_passwords';
  
  Future<void> storePassword(String configId, String password);
  Future<String?> getPassword(String configId);
  Future<void> deletePassword(String configId);
  
  Future<String> encryptPrivateKey(String keyContent);
  Future<String> decryptPrivateKey(String encryptedKey);
}
```

### 5.4 命令管理服务
```dart
class CommandService {
  Future<List<CommonCommand>> getCommonCommands();
  Future<void> importCommandsFromFile();
  Future<void> addCommand(String name, String command, String category);
  Future<void> updateCommandUsage(String commandId);
  Future<List<CommonCommand>> searchCommands(String query);
}
```
```dart
class FileService {
  Future<String> importPrivateKey();
  Future<void> savePrivateKey(String configId, String keyContent);
  Future<String?> getPrivateKey(String configId);
  Future<void> deletePrivateKey(String configId);
}
```

## 6. 业务逻辑层

### 6.1 状态管理 (Provider)
```dart
class SSHConfigProvider extends ChangeNotifier {
  List<SSHConfig> _configs = [];
  bool _isLoading = false;
  
  List<SSHConfig> get configs => _configs;
  bool get isLoading => _isLoading;
  
  Future<void> loadConfigs();
  Future<void> addConfig(SSHConfig config);
  Future<void> updateConfig(SSHConfig config);
  Future<void> deleteConfig(String id);
}

class SSHSessionProvider extends ChangeNotifier {
  final Map<String, SSHSession> _sessions = {};
  
  Map<String, SSHSession> get sessions => _sessions;
  
  Future<void> connect(SSHConfig config);
  Future<void> disconnect(String configId);
  Future<void> disconnectAll();
  Future<void> executeCommand(String configId, String command);
}

class CommonCommandProvider extends ChangeNotifier {
  List<CommonCommand> _commands = [];
  List<CommonCommand> _filteredCommands = [];
  
  List<CommonCommand> get commands => _commands;
  List<CommonCommand> get filteredCommands => _filteredCommands;
  
  Future<void> loadCommands();
  Future<void> importCommands(String filePath);
  Future<void> addCommand(CommonCommand command);
  void filterCommands(String query);
  Future<void> updateUsage(String commandId);
}
```

## 7. UI层设计

### 7.1 页面结构
```dart
// 主页面
class HomePage extends StatelessWidget {
  // SSH配置列表
  // 添加按钮
  // 搜索功能
  // 批量选择模式
  // 批量断开连接功能
}

// 配置编辑页面
class ConfigEditPage extends StatefulWidget {
  // 表单字段
  // 认证方式选择
  // 连接测试
}

// 终端页面
class TerminalPage extends StatefulWidget {
  // 命令输入
  // 输出显示
  // 连接状态
  // 常用命令面板
}

// 命令管理页面
class CommandManagePage extends StatefulWidget {
  // 命令列表
  // 分类管理
  // 导入功能
  // 搜索筛选
}
```

### 7.2 关键Widget
```dart
class SSHConfigCard extends StatelessWidget {
  // 配置信息显示
  // 连接状态指示
  // 操作按钮
  // 多选支持
}

class TerminalOutput extends StatefulWidget {
  // 滚动文本显示
  // 颜色代码支持
  // 文本选择
}

class CommandInput extends StatefulWidget {
  // 输入框
  // 历史记录
  // 自动补全
}

class CommandPanel extends StatefulWidget {
  // 常用命令展示
  // 分类筛选
  // 搜索功能
  // 命令选择回调
}

class CommandImportDialog extends StatefulWidget {
  // 文件选择
  // 预览功能
  // 导入确认
}
```

## 8. 关键算法实现

### 8.1 SSH连接管理
```dart
class ConnectionManager {
  static const int maxRetries = 3;
  static const Duration timeout = Duration(seconds: 30);
  
  Future<SSHClient> establishConnection(SSHConfig config) {
    // 1. 创建SSH客户端
    // 2. 设置连接参数
    // 3. 根据认证类型进行认证
    // 4. 建立连接
    // 5. 错误处理和重试
  }
  
  Future<void> handleReconnection(String configId) {
    // 自动重连逻辑
  }
}
```

### 8.2 密码加密算法
```dart
class PasswordEncryption {
  static Future<String> encrypt(String password) {
    // 使用设备密钥库进行AES-256加密
  }
  
  static Future<String> decrypt(String encryptedPassword) {
    // 解密密码
  }
}
```

### 8.4 命令导入处理
```dart
class CommandImporter {
  static Future<List<CommonCommand>> parseCommandFile(String filePath) {
    // 1. 读取文件内容
    // 2. 按换行符分割命令
    // 3. 过滤空行和注释
    // 4. 创建CommonCommand对象
    // 5. 返回命令列表
  }
  
  static List<CommonCommand> parseCommandText(String text) {
    // 解析文本格式的命令列表
  }
}
```

### 8.5 批量连接管理
```dart
class BatchConnectionManager {
  static Future<void> disconnectAllSessions() {
    // 遍历所有活跃连接并断开
  }
  
  static Future<List<String>> getActiveConnections() {
    // 获取所有活跃连接的配置ID
  }
  
  static Future<void> disconnectSelected(List<String> configIds) {
    // 断开指定的连接
  }
}
```
```dart
class TerminalProcessor {
  static String processOutput(String rawOutput) {
    // 1. 处理ANSI转义序列
    // 2. 颜色代码转换
    // 3. 特殊字符处理
    // 4. 编码转换
  }
}
```

## 9. 错误处理策略

### 9.1 异常类型定义
```dart
abstract class SSHException implements Exception {
  final String message;
  SSHException(this.message);
}

class ConnectionException extends SSHException {
  ConnectionException(String message) : super(message);
}

class AuthenticationException extends SSHException {
  AuthenticationException(String message) : super(message);
}

class CommandExecutionException extends SSHException {
  CommandExecutionException(String message) : super(message);
}
```

### 9.2 错误处理流程
```dart
class ErrorHandler {
  static void handleSSHError(SSHException error) {
    // 1. 记录错误日志
    // 2. 显示用户友好的错误信息
    // 3. 根据错误类型执行相应操作
  }
}
```

## 10. 性能优化策略

### 10.1 连接池管理
- 限制同时连接数量
- 连接复用机制
- 空闲连接自动断开

### 10.2 内存管理
- 命令历史记录限制
- 输出缓冲区大小控制
- 及时释放不用的资源

### 10.3 UI优化
- 列表懒加载
- 图片缓存
- 状态更新优化

## 11. 安全设计

### 11.1 数据保护
- 密码使用设备密钥库加密
- 私钥文件加密存储
- 敏感数据不在日志中输出

### 11.2 网络安全
- 强制使用SSH-2协议
- 主机密钥验证
- 连接超时保护

## 12. 测试策略

### 12.1 单元测试
- 数据模型测试
- 服务层逻辑测试
- 工具类函数测试

### 12.2 集成测试
- SSH连接测试
- 数据库操作测试
- 加密解密测试

### 12.3 UI测试
- 页面导航测试
- 用户交互测试
- 状态变化测试

## 13. 部署配置

### 13.1 构建配置
```yaml
# pubspec.yaml 关键依赖
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  sqflite: ^2.0.0
  flutter_secure_storage: ^9.0.0
  dartssh2: ^2.0.0
  go_router: ^12.0.0
  file_picker: ^6.0.0
```

### 13.2 平台特定配置
- Android: 网络权限、存储权限
- iOS: 网络访问权限、密钥库访问权限

这份设计文档为Final SSH应用的开发提供了完整的技术指导，涵盖了架构设计、数据模型、服务实现等各个方面。
