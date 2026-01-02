# Final SSH

一个功能完整的跨平台SSH客户端应用，基于Flutter开发，为用户提供安全、便捷的远程服务器管理体验。

## 主要功能

### SSH连接管理
- 保存和管理多个SSH服务器配置
- 支持密码认证和私钥认证
- 实时显示连接状态和错误信息
- 批量连接管理和一键断开功能

### 终端操作
- 完整的SSH终端功能
- 命令历史记录和自动补全
- 实时显示服务器输出，支持颜色代码
- 常用命令快捷面板

### 命令管理
- 批量导入常用命令（换行分割）
- 命令分类和标签管理
- 快捷命令选择和一键发送
- 命令使用频率统计

### 安全特性
- 密码和私钥AES-256加密存储
- SSH主机密钥验证
- 防止中间人攻击
- 最小权限原则

### 用户界面
- Material Design设计规范
- 深色/浅色主题切换
- 响应式布局适配不同设备
- 直观的操作体验

## 系统要求

- **Android**: 6.0+ (API Level 23+)
- **iOS**: 12.0+
- **Flutter**: 3.0+

## 技术栈

- Flutter 3.0+
- Dart 3.0+
- Provider状态管理
- SQLite本地存储
- dartssh2 SSH连接库

## 开发说明

本项目完全由AI（Amazon Q Developer）开发完成，包括需求分析、架构设计、代码实现和文档编写。展示了AI在软件开发领域的强大能力。

## 安装使用

1. 克隆项目
```bash
git clone https://github.com/chencundegushi/final_ssh.git
cd final_ssh
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
flutter run
```

## 许可证

MIT License

---

**注意**: 本应用处理敏感的SSH连接信息，请确保在可信环境中使用。
