import 'dart:convert';

class ChatMessage {
  final int id;
  final int userId;
  final int hotelId;
  final String message;
  final bool isFromUser;
  final bool isAiResponse;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.hotelId,
    required this.message,
    required this.isFromUser,
    required this.isAiResponse,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      userId: json['user_id'],
      hotelId: json['hotel_id'],
      message: json['message'],
      isFromUser: json['is_from_user'],
      isAiResponse: json['is_ai_response'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'hotel_id': hotelId,
      'message': message,
      'is_from_user': isFromUser,
      'is_ai_response': isAiResponse,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  ChatMessage copyWith({
    int? id,
    int? userId,
    int? hotelId,
    String? message,
    bool? isFromUser,
    bool? isAiResponse,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      hotelId: hotelId ?? this.hotelId,
      message: message ?? this.message,
      isFromUser: isFromUser ?? this.isFromUser,
      isAiResponse: isAiResponse ?? this.isAiResponse,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get senderType {
    if (isFromUser) {
      return 'You';
    } else if (isAiResponse) {
      return 'AI Assistant';
    } else {
      return 'Hotel Staff';
    }
  }
}