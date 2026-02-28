import 'dart:convert';

class ServerConfig {
  final String id;
  final String name;
  final String host;
  final String astrBotPort;
  final String napCatPort;
  final String napCatToken;
  final String apiKey;

  ServerConfig({
    required this.id,
    required this.name,
    required this.host,
    this.astrBotPort = '6185',
    this.napCatPort = '6099',
    this.napCatToken = '',
    this.apiKey = '',
  });

  // 🪄 增加克隆技能：方便动态替换令牌喵✨
  ServerConfig copyWith({
    String? id,
    String? name,
    String? host,
    String? astrBotPort,
    String? napCatPort,
    String? napCatToken,
    String? apiKey,
  }) {
    return ServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      astrBotPort: astrBotPort ?? this.astrBotPort,
      napCatPort: napCatPort ?? this.napCatPort,
      napCatToken: napCatToken ?? this.napCatToken,
      apiKey: apiKey ?? this.apiKey,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'astrBotPort': astrBotPort,
      'napCatPort': napCatPort,
      'napCatToken': napCatToken,
      'apiKey': apiKey,
    };
  }

  factory ServerConfig.fromMap(Map<String, dynamic> map) {
    return ServerConfig(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      host: map['host'] ?? '',
      astrBotPort: map['astrBotPort'] ?? '6185',
      napCatPort: map['napCatPort'] ?? '6099',
      napCatToken: map['napCatToken'] ?? '',
      apiKey: map['apiKey'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());
  factory ServerConfig.fromJson(String source) => ServerConfig.fromMap(json.decode(source));
}
