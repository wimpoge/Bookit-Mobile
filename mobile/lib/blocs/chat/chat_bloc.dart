import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import '../../models/chat_message.dart';
import '../../models/chat_conversation.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiService _apiService;
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription<ChatMessage>? _webSocketSubscription;
  Timer? _messageRefreshTimer;
  int? _currentHotelId;

  ChatBloc(this._apiService) : super(ChatInitial()) {
    on<ChatLoadEvent>(_onLoadChat);
    on<ChatSendMessageEvent>(_onSendMessage);
    on<ChatOwnerReplyEvent>(_onOwnerReply);
    on<ChatDeleteMessageEvent>(_onDeleteMessage);
    on<OwnerChatsLoadEvent>(_onOwnerChatsLoad);
    on<ChatMessagesLoadEvent>(_onChatMessagesLoad);
    on<ChatMessageSendEvent>(_onChatMessageSend);
    on<ChatConnectWebSocketEvent>(_onConnectWebSocket);
    on<ChatNewMessageReceived>(_onNewMessageReceived);
  }

  @override
  Future<void> close() {
    _webSocketSubscription?.cancel();
    _messageRefreshTimer?.cancel();
    _webSocketService.dispose();
    return super.close();
  }

  Future<void> _onLoadChat(ChatLoadEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      _currentHotelId = event.hotelId;
      final messages = await _apiService.getChatMessages(event.hotelId);
      emit(ChatLoaded(messages));
      
      // Start periodic refresh for real-time updates (fallback for WebSocket)
      _startMessageRefresh();
      
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _startMessageRefresh() {
    _messageRefreshTimer?.cancel();
    _messageRefreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_currentHotelId != null && state is ChatLoaded) {
        try {
          final messages = await _apiService.getChatMessages(_currentHotelId!);
          final currentMessages = (state as ChatLoaded).messages;
          
          // Only emit if messages have changed
          if (messages.length != currentMessages.length) {
            // New messages found - trigger reload via event
            if (messages.isNotEmpty && currentMessages.isNotEmpty && 
                messages.length > currentMessages.length) {
              // Get the latest message and add it as a new received message
              final latestMessage = messages.last;
              add(ChatNewMessageReceived(message: latestMessage));
            }
          }
        } catch (e) {
          // Silently continue - don't interrupt chat with refresh errors
        }
      }
    });
  }

  Future<void> _onConnectWebSocket(
      ChatConnectWebSocketEvent event, Emitter<ChatState> emit) async {
    try {
      print('Attempting WebSocket connection to hotel ${event.hotelId}...');
      _webSocketService.setToken(event.token);
      await _webSocketService.connectAsUser(event.hotelId);
      
      _webSocketSubscription = _webSocketService.messageStream?.listen(
        (message) {
          print('Received WebSocket message: ${message.message}');
          add(ChatNewMessageReceived(message: message));
        },
        onError: (error) {
          print('WebSocket stream error: $error');
        },
      );
      
      print('WebSocket connected successfully!');
    } catch (e) {
      // Continue without WebSocket if it fails
      print('WebSocket connection failed: $e');
      print('Will rely on periodic refresh for real-time updates');
    }
  }

  Future<void> _onNewMessageReceived(
      ChatNewMessageReceived event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      // Check if message is not already in the list (avoid duplicates)
      final exists = currentState.messages.any((m) => m.id == event.message.id);
      if (!exists) {
        final updatedMessages = [...currentState.messages, event.message];
        emit(ChatLoaded(updatedMessages));
      }
    }
  }

  Future<void> _onSendMessage(
      ChatSendMessageEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(ChatMessageSending(currentState.messages));
    }
    
    try {
      print('Sending message via API: ${event.message}');
      
      // Always send via API first to ensure message is stored
      final message = await _apiService.sendMessage(event.hotelId, event.message);
      print('Message sent successfully via API');
      
      // Also send via WebSocket for real-time delivery to other clients
      if (_webSocketService.isConnected) {
        try {
          _webSocketService.sendMessage(event.message);
          print('Message also sent via WebSocket for real-time delivery');
        } catch (e) {
          print('WebSocket send failed (not critical): $e');
        }
      }
      
      // Add the message to current state immediately for better UX
      if (currentState is ChatLoaded) {
        final updatedMessages = [...currentState.messages, message];
        emit(ChatLoaded(updatedMessages));
      } else {
        // Reload messages if we don't have current state
        final messages = await _apiService.getChatMessages(event.hotelId);
        emit(ChatLoaded(messages));
      }
      
    } catch (e) {
      print('Error sending message: $e');
      
      // Restore previous state on error
      if (currentState is ChatLoaded) {
        emit(ChatLoaded(currentState.messages));
      }
      
      emit(ChatError('Failed to send message: ${e.toString()}'));
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
      if (event.userId == null) {
        throw Exception('User ID is required for owner chat messages');
      }
      final messages = await _apiService.getChatMessagesForOwner(
        hotelId: event.hotelId,
        userId: event.userId!,
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
      if (event.userId == null) {
        throw Exception('User ID is required for sending owner messages');
      }
      final message = await _apiService.sendOwnerMessage(
        hotelId: event.hotelId,
        userId: event.userId!,
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
