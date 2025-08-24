part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatLoadEvent extends ChatEvent {
  final int hotelId;

  const ChatLoadEvent({required this.hotelId});

  @override
  List<Object> get props => [hotelId];
}

class ChatSendMessageEvent extends ChatEvent {
  final int hotelId;
  final String message;

  const ChatSendMessageEvent({
    required this.hotelId,
    required this.message,
  });

  @override
  List<Object> get props => [hotelId, message];
}

class ChatOwnerReplyEvent extends ChatEvent {
  final int hotelId;
  final String message;

  const ChatOwnerReplyEvent({
    required this.hotelId,
    required this.message,
  });

  @override
  List<Object> get props => [hotelId, message];
}

class ChatDeleteMessageEvent extends ChatEvent {
  final int messageId;

  const ChatDeleteMessageEvent({required this.messageId});

  @override
  List<Object> get props => [messageId];
}

class OwnerChatsLoadEvent extends ChatEvent {
  const OwnerChatsLoadEvent();
}

class ChatMessagesLoadEvent extends ChatEvent {
  final int hotelId;
  final int? userId;

  const ChatMessagesLoadEvent({
    required this.hotelId,
    required this.userId,
  });

  @override
  List<Object?> get props => [hotelId, userId];
}

class ChatMessageSendEvent extends ChatEvent {
  final int hotelId;
  final int? userId;
  final String message;
  final bool isFromOwner;

  const ChatMessageSendEvent({
    required this.hotelId,
    required this.userId,
    required this.message,
    this.isFromOwner = false,
  });

  @override
  List<Object?> get props => [hotelId, userId, message, isFromOwner];
}

class ChatConnectWebSocketEvent extends ChatEvent {
  final int hotelId;
  final String token;

  const ChatConnectWebSocketEvent({
    required this.hotelId,
    required this.token,
  });

  @override
  List<Object> get props => [hotelId, token];
}

class ChatNewMessageReceived extends ChatEvent {
  final ChatMessage message;

  const ChatNewMessageReceived({required this.message});

  @override
  List<Object> get props => [message];
}
