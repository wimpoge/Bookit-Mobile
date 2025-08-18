part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
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
