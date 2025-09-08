import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String hotelId;
  final String? userId;
  final String message;
  final bool isFromOwner;
  final bool isFromUser;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatMessage({
    required this.id,
    required this.hotelId,
    this.userId,
    required this.message,
    this.isFromOwner = false,
    bool? isFromUser,
    this.isRead = false,
    required this.createdAt,
    required this.updatedAt,
  }) : isFromUser = isFromUser ?? !isFromOwner;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final isFromOwner = json['is_from_owner'] ?? false;
    final isFromUser = json['is_from_user'] ?? !isFromOwner;

    return ChatMessage(
      id: (json['id'] ?? '0').toString(),
      hotelId: (json['hotel_id'] ?? '0').toString(),
      userId: json['user_id']?.toString(),
      message: json['message'] ?? '',
      isFromOwner: isFromOwner,
      isFromUser: isFromUser,
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hotel_id': hotelId,
      'user_id': userId,
      'message': message,
      'is_from_owner': isFromOwner,
      'is_from_user': isFromUser,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChatMessage copyWith({
    String? id,
    String? hotelId,
    String? userId,
    String? message,
    bool? isFromOwner,
    bool? isFromUser,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final newIsFromOwner = isFromOwner ?? this.isFromOwner;
    final newIsFromUser =
        isFromUser ?? (isFromOwner != null ? !newIsFromOwner : this.isFromUser);

    return ChatMessage(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      isFromOwner: newIsFromOwner,
      isFromUser: newIsFromUser,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        hotelId,
        userId,
        message,
        isFromOwner,
        isFromUser,
        isRead,
        createdAt,
        updatedAt,
      ];
}
