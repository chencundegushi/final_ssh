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

  SSHConfig({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.authType,
    this.password,
    this.privateKeyPath,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'auth_type': authType.name,
      'private_key_path': privateKeyPath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory SSHConfig.fromMap(Map<String, dynamic> map) {
    return SSHConfig(
      id: map['id'],
      name: map['name'],
      host: map['host'],
      port: map['port'],
      username: map['username'],
      authType: AuthType.values.byName(map['auth_type']),
      privateKeyPath: map['private_key_path'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  SSHConfig copyWith({
    String? name,
    String? host,
    int? port,
    String? username,
    AuthType? authType,
    String? password,
    String? privateKeyPath,
  }) {
    return SSHConfig(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      authType: authType ?? this.authType,
      password: password ?? this.password,
      privateKeyPath: privateKeyPath ?? this.privateKeyPath,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

enum AuthType { password, privateKey }

enum ConnectionStatus { disconnected, connecting, connected, error }

class CommandHistory {
  final String command;
  final String output;
  final DateTime executedAt;
  final bool isError;

  CommandHistory({
    required this.command,
    required this.output,
    required this.executedAt,
    this.isError = false,
  });
}
