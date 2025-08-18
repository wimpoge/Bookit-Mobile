import 'dart:convert';

class User {
  final int id;
  final String email;
  final String username;
  final String? fullName;
  final String? phone;
  final String role;
  final bool isActive;
  final String? profileImage;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.phone,
    required this.role,
    required this.isActive,
    this.profileImage,
    required this.createdAt,
  });

  factory User.fromJson(dynamic json) {
    if (json is String) {
      json = jsonDecode(json);
    }
    
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      fullName: json['full_name'],
      phone: json['phone'],
      role: json['role'],
      isActive: json['is_active'],
      profileImage: json['profile_image'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'is_active': isActive,
      'profile_image': profileImage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  User copyWith({
    int? id,
    String? email,
    String? username,
    String? fullName,
    String? phone,
    String? role,
    bool? isActive,
    String? profileImage,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isOwner => role == 'owner';
  bool get isUser => role == 'user';
}