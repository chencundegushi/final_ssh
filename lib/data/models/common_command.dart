class CommonCommand {
  final String id;
  final String name;
  final String command;
  final String? description;
  final String category;
  final int usageCount;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  CommonCommand({
    required this.id,
    required this.name,
    required this.command,
    this.description,
    this.category = 'default',
    this.usageCount = 0,
    required this.createdAt,
    this.lastUsedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'command': command,
      'description': description,
      'category': category,
      'usage_count': usageCount,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_used_at': lastUsedAt?.millisecondsSinceEpoch,
    };
  }

  factory CommonCommand.fromMap(Map<String, dynamic> map) {
    return CommonCommand(
      id: map['id'],
      name: map['name'],
      command: map['command'],
      description: map['description'],
      category: map['category'] ?? 'default',
      usageCount: map['usage_count'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      lastUsedAt: map['last_used_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['last_used_at'])
          : null,
    );
  }

  CommonCommand copyWith({
    String? id,
    String? name,
    String? command,
    String? description,
    String? category,
    int? usageCount,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return CommonCommand(
      id: id ?? this.id,
      name: name ?? this.name,
      command: command ?? this.command,
      description: description ?? this.description,
      category: category ?? this.category,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}
