import 'package:equatable/equatable.dart';
import 'chat_message.dart';
import 'hotel.dart';

class ChatConversation extends Equatable {
  final String id;
  final String hotelId;
  final String userId;
  final Hotel hotel;
  final String guestName;
  final ChatMessage lastMessage;
  final bool hasUnreadMessages;
  final int unreadCount;
  final DateTime updatedAt;

  const ChatConversation({
    required this.id,
    required this.hotelId,
    required this.userId,
    required this.hotel,
    required this.guestName,
    required this.lastMessage,
    required this.hasUnreadMessages,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: (json['id'] ?? '0').toString(),
      hotelId: (json['hotel_id'] ?? '0').toString(),
      userId: (json['user_id'] ?? '0').toString(),
      hotel: Hotel.fromJson(json['hotel'] ?? {}),
      guestName: json['guest_name'] ?? 'Guest',
      lastMessage: ChatMessage.fromJson(json['last_message'] ?? {}),
      hasUnreadMessages: json['has_unread_messages'] ?? false,
      unreadCount: json['unread_count'] ?? 0,
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hotel_id': hotelId,
      'user_id': userId,
      'hotel': hotel.toJson(),
      'guest_name': guestName,
      'last_message': lastMessage.toJson(),
      'has_unread_messages': hasUnreadMessages,
      'unread_count': unreadCount,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChatConversation copyWith({
    String? id,
    String? hotelId,
    String? userId,
    Hotel? hotel,
    String? guestName,
    ChatMessage? lastMessage,
    bool? hasUnreadMessages,
    int? unreadCount,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      userId: userId ?? this.userId,
      hotel: hotel ?? this.hotel,
      guestName: guestName ?? this.guestName,
      lastMessage: lastMessage ?? this.lastMessage,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        hotelId,
        userId,
        hotel,
        guestName,
        lastMessage,
        hasUnreadMessages,
        unreadCount,
        updatedAt,
      ];
}
