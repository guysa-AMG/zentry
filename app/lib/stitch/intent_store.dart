import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:audio_session/audio_session.dart';
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
  StreamSubscription<List<int>>? _audioSubscription;

  @override
  IntentState build() {
    // Ensure cleanup when provider is disposed
    ref.onDispose(() {
      stopVoiceSession();
    });
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
    final wsUrl = Uri.parse('wss://api.elevenlabs.io/v1/convai/conversation?agent_id=user_6201kr5xvc1he9j8mb0jm3gmxv08&xi-api-key=sk_6d981f307429943ca520914839ce0a1c8252caffcbc253dc');
    
    try {
      addEvent('WebSocket Request Sent...', 'Initializing connection...', true);
      _channel = WebSocketChannel.connect(wsUrl);
      
      // Ensure the WebSocket connection is established
      await _channel!.ready;
      addEvent('Socket Opened...', 'Handshake in progress.', true);

      // Send initiation data immediately
      _channel!.sink.add(jsonEncode({
        "type": "conversation_initiation_client_data",
        "conversation_config_override": {
          "agent": {
            "first_message": "Zentry active.",
            "language": "en"
          }
        }
      }));

      _channel!.stream.listen(
        (message) {
          
          debugPrint('WS Message: $message');
          try {
            final data = jsonDecode(message);
            // Catch ElevenLabs server-side errors
            if (data['type'] == 'error' || data['error'] != null) {
              final errorMsg = data['message'] ?? data['error'] ?? 'Unknown remote error';
              addEvent('ElevenLabs Error', errorMsg, false);
            }
            // Check for session initiation confirmation
            if (data['type'] == 'conversation_initiation_metadata') {
              addEvent('Session Ready', 'Handshake confirmed.', true);
            }
          } catch (_) {}
          _handleVoiceMessage(message);
        },
        onDone: () {
          addEvent('Connection Closed', 'Session ended.', false);
          stopVoiceSession();
        },
        onError: (e) {
          addEvent('Connection Error', 'WS error: $e', false);
          stopVoiceSession();
        },
      );
      
      // Audio Session Keep-Alive Pattern
      try {
        addEvent('Mic Requesting Focus...', 'Configuring audio session.', true);
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.speech());
        
        final activated = await session.setActive(true);
        if (!activated) {
          addEvent('Session Error', 'OS denied audio focus.', false);
          stopVoiceSession();
          return;
        }

        // 200ms delay for OS driver rerouting
        await Future.delayed(const Duration(milliseconds: 200));
        
      } catch (e) {
        addEvent('Session Error', 'Audio session failed: $e', false);
        stopVoiceSession();
        return;
      }

      if (!state.isListening) return;

      // Start microphone stream
      try {
        const config = RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        );
        
        final stream = await _audioRecorder.startStream(config);
        addEvent('Mic Start', 'Streaming PCM 16k (Base64)', true);

        // Map microphone amplitude to volume state
        _amplitudeSubscription = _audioRecorder
            .onAmplitudeChanged(const Duration(milliseconds: 100))
            .listen((amp) {
          double volume = (amp.current + 50) / 40;
          volume = volume.clamp(0.0, 1.0);
          updateVolume(volume);
        });

        // Pipe audio data to WebSocket as Base64 JSON chunks
        _audioSubscription = stream.listen((data) {
          if (state.isListening) {
            final base64Chunk = base64Encode(data);
            _channel?.sink.add(jsonEncode({
              "user_audio_chunk": base64Chunk,
            }));
          }
        }, onError: (e) {
          addEvent('Mic Stream Error', '$e', false);
        });
      } catch (e) {
        addEvent('Mic Error', 'Failed to start stream: $e', false);
        stopVoiceSession();
      }

    } catch (e) {
      addEvent('Error', 'Failed to initialize session: $e', false);
      stopVoiceSession();
    }
  }

  void stopVoiceSession() async {
    if (!state.isListening) return;
    
    await _audioRecorder.stop();
    _amplitudeSubscription?.cancel();
    _audioSubscription?.cancel();
    _channel?.sink.close();
    _channel = null;

    // Release audio session
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (_) {}

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
