import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/api_service.dart';
import '../../models/chat_message.dart';
import '../../models/chat_conversation.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiService _apiService;

  ChatBloc(this._apiService) : super(ChatInitial()) {
    on<ChatLoadEvent>(_onLoadChat);
    on<ChatSendMessageEvent>(_onSendMessage);
    on<ChatOwnerReplyEvent>(_onOwnerReply);
    on<ChatDeleteMessageEvent>(_onDeleteMessage);
    on<OwnerChatsLoadEvent>(_onOwnerChatsLoad);
    on<ChatMessagesLoadEvent>(_onChatMessagesLoad);
    on<ChatMessageSendEvent>(_onChatMessageSend);
  }

  Future<void> _onLoadChat(ChatLoadEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      final messages = await _apiService.getChatMessages(event.hotelId);
      emit(ChatLoaded(messages));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onSendMessage(
      ChatSendMessageEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(ChatMessageSending(currentState.messages));
    }
    try {
      final message =
          await _apiService.sendMessage(event.hotelId, event.message);
      final messages = await _apiService.getChatMessages(event.hotelId);
      emit(ChatLoaded(messages));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onOwnerReply(
      ChatOwnerReplyEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(ChatMessageSending(currentState.messages));
    }
    try {
      final message =
          await _apiService.ownerReply(event.hotelId, event.message);
      final messages = await _apiService.getChatMessages(event.hotelId);
      emit(ChatLoaded(messages));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onDeleteMessage(
      ChatDeleteMessageEvent event, Emitter<ChatState> emit) async {
    try {
      await _apiService.deleteMessage(event.messageId);
      if (state is ChatLoaded) {
        final currentMessages = (state as ChatLoaded).messages;
        final hotelId =
            currentMessages.isNotEmpty ? currentMessages.first.hotelId : 0;
        final messages = await _apiService.getChatMessages(hotelId);
        emit(ChatLoaded(messages));
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onOwnerChatsLoad(
    OwnerChatsLoadEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(ChatLoading());
      final conversations = await _apiService.getOwnerConversations();
      emit(OwnerChatsLoaded(conversations));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onChatMessagesLoad(
    ChatMessagesLoadEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(ChatLoading());
      final messages = await _apiService.getChatMessagesForOwner(
        hotelId: event.hotelId,
        userId: event.userId,
      );
      emit(ChatMessagesLoaded(
        messages: messages,
        hotelId: event.hotelId,
        userId: event.userId,
      ));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onChatMessageSend(
    ChatMessageSendEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final message = await _apiService.sendOwnerMessage(
        hotelId: event.hotelId,
        userId: event.userId,
        message: event.message,
        isFromOwner: event.isFromOwner,
      );

      emit(ChatMessageSent(message));

      add(ChatMessagesLoadEvent(
        hotelId: event.hotelId,
        userId: event.userId,
      ));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }
}
