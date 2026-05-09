import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../widgets/audit_timeline.dart';

class IntentState {
  final bool isListening;
  final List<AuditEvent> events;

  IntentState({
    required this.isListening,
    required this.events,
  });

  IntentState copyWith({
    bool? isListening,
    List<AuditEvent>? events,
  }) {
    return IntentState(
      isListening: isListening ?? this.isListening,
      events: events ?? this.events,
    );
  }
}

class IntentStore extends Notifier<IntentState> {
  WebSocketChannel? _channel;

  @override
  IntentState build() {
    return IntentState(
      isListening: false,
      events: [],
    );
  }

  void startVoiceSession() {
    if (state.isListening) return;

    state = state.copyWith(
      isListening: true,
      events: [
        ...state.events,
        AuditEvent(
          title: 'Voice Session Started',
          description: 'Connecting to ElevenLabs 1.5 Mini...',
          timestamp: DateTime.now(),
          isSuccess: true,
        ),
      ],
    );

    final wsUrl = Uri.parse('wss://api.elevenlabs.io/v1/convai/conversation');
    
    try {
      _channel = WebSocketChannel.connect(wsUrl);

      _channel!.stream.listen(
        (message) {
          _handleVoiceMessage(message);
        },
        onDone: () {
          stopVoiceSession();
        },
        onError: (error) {
          _addEvent('Connection Error', 'WebSocket error: $error', false);
          stopVoiceSession();
        },
      );
      
      // Mock an intent being detected after a few seconds
      // since we aren't hooking up a full WebRTC/audio streaming pipeline here.
      Future.delayed(const Duration(seconds: 3), () {
        if (state.isListening) {
          _addEvent('Intent Detected', 'Parsed intent: Transfer.', true);
        }
      });
      
    } catch (e) {
      _addEvent('Error', 'Failed to connect: $e', false);
      stopVoiceSession();
    }
  }

  void stopVoiceSession() {
    if (!state.isListening) return;
    _channel?.sink.close();
    _channel = null;

    state = state.copyWith(
      isListening: false,
      events: [
        ...state.events,
        AuditEvent(
          title: 'Voice Session Ended',
          description: 'Connection closed.',
          timestamp: DateTime.now(),
          isSuccess: true,
        ),
      ],
    );
  }

  void _handleVoiceMessage(dynamic message) {
    try {
      if (message is String) {
        final data = jsonDecode(message);
        if (data['type'] == 'intent_detection' && data['intent'] != null) {
          _addEvent('Intent Detected', 'Action: ${data['intent']}', true);
        }
      }
    } catch (_) {
      // Ignore parse errors (e.g. if it's binary audio)
    }
  }

  void _addEvent(String title, String description, bool isSuccess) {
    state = state.copyWith(
      events: [
        ...state.events,
        AuditEvent(
          title: title,
          description: description,
          timestamp: DateTime.now(),
          isSuccess: isSuccess,
        ),
      ],
    );
  }
}

final intentStoreProvider = NotifierProvider<IntentStore, IntentState>(IntentStore.new);
