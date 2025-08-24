part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;

  const ChatLoaded(this.messages);

  @override
  List<Object> get props => [messages];
}

class ChatMessageSending extends ChatState {
  final List<ChatMessage> messages;

  const ChatMessageSending(this.messages);

  @override
  List<Object> get props => [messages];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}

class OwnerChatsLoaded extends ChatState {
  final List<ChatConversation> conversations;

  const OwnerChatsLoaded(this.conversations);

  @override
  List<Object> get props => [conversations];
}

class ChatMessagesLoaded extends ChatState {
  final List<ChatMessage> messages;
  final int hotelId;
  final int? userId;

  const ChatMessagesLoaded({
    required this.messages,
    required this.hotelId,
    required this.userId,
  });

  @override
  List<Object?> get props => [messages, hotelId, userId];
}

class ChatMessageSent extends ChatState {
  final ChatMessage message;

  const ChatMessageSent(this.message);

  @override
  List<Object> get props => [message];
}
