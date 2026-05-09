import 'dart:async';
import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/audit_timeline.dart';

class IntentState {
  final bool isListening;
  final List<AuditEvent> events;
  final double currentVolume;

  IntentState({
    required this.isListening,
    required this.events,
    this.currentVolume = 0.0,
  });

  IntentState copyWith({
    bool? isListening,
    List<AuditEvent>? events,
    double? currentVolume,
  }) {
    return IntentState(
      isListening: isListening ?? this.isListening,
      events: events ?? this.events,
      currentVolume: currentVolume ?? this.currentVolume,
    );
  }
}

class IntentStore extends Notifier<IntentState> {
  WebSocketChannel? _channel;
  final _audioRecorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  @override
  IntentState build() {
    return IntentState(
      isListening: false,
      events: [],
    );
  }

  Future<void> startVoiceSession() async {
    if (state.isListening) return;

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      addEvent('Permission Denied', 'Microphone access required.', false);
      return;
    }

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

    // ElevenLabs WebSocket endpoint (placeholder agent_id)
    final wsUrl = Uri.parse('wss://api.elevenlabs.io/v1/convai/conversation?agent_id=zentry_agent_01');
    
    try {
      _channel = WebSocketChannel.connect(wsUrl);

      _channel!.stream.listen(
        (message) {
          _handleVoiceMessage(message);
        },
        onDone: () => stopVoiceSession(),
        onError: (e) {
          addEvent('Connection Error', 'WS error: $e', false);
          stopVoiceSession();
        },
      );
      
      // Start microphone stream
      const config = RecordConfig();
      final stream = await _audioRecorder.startStream(config);

      // Map microphone amplitude to volume state
      _amplitudeSubscription = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
        // Normalizing amplitude (-160 to 0) to 0.0 - 1.0 range
        double volume = (amp.current + 160) / 160;
        volume = volume.clamp(0.0, 1.0);
        updateVolume(volume);
      });

      // Pipe audio data to WebSocket
      stream.listen((data) {
        if (state.isListening) {
          _channel?.sink.add(data);
        }
      });

    } catch (e) {
      addEvent('Error', 'Failed to initialize session: $e', false);
      stopVoiceSession();
    }
  }

  void stopVoiceSession() async {
    if (!state.isListening) return;
    
    await _audioRecorder.stop();
    _amplitudeSubscription?.cancel();
    _channel?.sink.close();
    _channel = null;

    state = state.copyWith(
      isListening: false,
      currentVolume: 0.0,
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
        
        // Speculative UI Logic: Partial transcript keywords
        if (data['type'] == 'transcript' || data['type'] == 'text_prediction') {
          final text = (data['value'] ?? data['transcript'] ?? '').toString().toLowerCase();
          if (text.contains('send') || text.contains('transfer') || text.contains('sol')) {
            // Check if we already have a Thinking node for this
            if (!state.events.any((e) => e.title == 'Thinking...')) {
              addEvent('Thinking...', 'Analyzing intent: $text', true);
            }
          }
        }

        // Full intent confirmed
        if (data['type'] == 'intent_detection' && data['intent'] != null) {
          prepareZentryTransaction('Detected: ${data['intent']}');
        }
      }
    } catch (_) {}
  }

  void updateVolume(double volume) {
    state = state.copyWith(currentVolume: volume);
  }

  void prepareZentryTransaction(String description) {
    addEvent(
      'Transaction Prepared',
      description,
      true,
    );
    addEvent(
      'Sentinel Bundle',
      '[Zentry Protocol, System Transfer]',
      true,
    );
  }

  void addEvent(String title, String description, bool isSuccess) {
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
