import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/api_service.dart';
import '../../models/chat_message.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiService _apiService;

  ChatBloc(this._apiService) : super(ChatInitial()) {
    on<ChatLoadEvent>(_onLoadChat);
    on<ChatSendMessageEvent>(_onSendMessage);
    on<ChatOwnerReplyEvent>(_onOwnerReply);
    on<ChatDeleteMessageEvent>(_onDeleteMessage);
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

      // Reload messages to get potential AI response
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

      // Reload messages
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
}
