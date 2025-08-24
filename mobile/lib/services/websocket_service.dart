import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../models/chat_message.dart';

class WebSocketService {
  static const String baseWsUrl = 'ws://localhost:8000/ws/chat';
  
  WebSocketChannel? _channel;
  StreamController<ChatMessage>? _messageController;
  Timer? _heartbeatTimer;
  String? _token;
  
  Stream<ChatMessage>? get messageStream => _messageController?.stream;
  
  bool get isConnected => _channel != null;
  
  void setToken(String token) {
    _token = token;
  }
  
  Future<void> connectAsUser(int hotelId) async {
    if (_token == null) {
      print('WebSocket: No token provided, using placeholder');
      _token = 'placeholder_token';
    }
    
    print('WebSocket: Connecting to $baseWsUrl/user/$hotelId');
    await _connect('$baseWsUrl/user/$hotelId?token=$_token');
  }
  
  Future<void> connectAsOwner(int hotelId, int userId) async {
    if (_token == null) {
      throw Exception('Token not set');
    }
    
    await _connect('$baseWsUrl/owner/$hotelId/$userId?token=$_token');
  }
  
  Future<void> _connect(String url) async {
    try {
      await disconnect();
      
      _messageController = StreamController<ChatMessage>.broadcast();
      print('WebSocket: Attempting connection to $url');
      
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      _channel!.stream.listen(
        (data) {
          try {
            print('WebSocket: Received raw data: $data');
            final jsonData = jsonDecode(data);
            print('WebSocket: Parsed JSON: $jsonData');
            
            if (jsonData['type'] == 'new_message') {
              final message = ChatMessage.fromJson(jsonData['message']);
              print('WebSocket: New message received: ${message.message}');
              _messageController?.add(message);
            } else if (jsonData['type'] == 'message') {
              // Handle direct message format
              final message = ChatMessage.fromJson(jsonData);
              print('WebSocket: Direct message received: ${message.message}');
              _messageController?.add(message);
            }
          } catch (e) {
            print('WebSocket: Error parsing message: $e');
            print('WebSocket: Raw data was: $data');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          // Don't reconnect immediately to avoid spam
          Future.delayed(const Duration(seconds: 5), () => _reconnect(url));
        },
        onDone: () {
          print('WebSocket connection closed');
          Future.delayed(const Duration(seconds: 5), () => _reconnect(url));
        },
      );
      
      _startHeartbeat();
      print('WebSocket: Connection established successfully');
      
    } catch (e) {
      print('WebSocket: Failed to connect: $e');
      // Don't throw exception, just log and continue without WebSocket
    }
  }
  
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'heartbeat'}));
        } catch (e) {
          print('Heartbeat failed: $e');
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }
  
  void _reconnect(String url) {
    Future.delayed(const Duration(seconds: 3), () {
      if (_messageController != null && !_messageController!.isClosed) {
        _connect(url);
      }
    });
  }
  
  void sendMessage(String message) {
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode({
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        }));
      } catch (e) {
        print('Failed to send message: $e');
        throw Exception('Failed to send message');
      }
    } else {
      throw Exception('Not connected to chat server');
    }
  }
  
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    
    await _channel?.sink.close(status.goingAway);
    _channel = null;
    
    await _messageController?.close();
    _messageController = null;
  }
  
  void dispose() {
    disconnect();
  }
}