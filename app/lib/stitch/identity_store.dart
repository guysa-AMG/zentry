import 'package:hooks_riverpod/hooks_riverpod.dart';

class IdentityState {
  final String? publicKey;
  final bool isConnected;

  IdentityState({this.publicKey, this.isConnected = false});

  IdentityState copyWith({String? publicKey, bool? isConnected}) {
    return IdentityState(
      publicKey: publicKey ?? this.publicKey,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdentityState &&
          runtimeType == other.runtimeType &&
          publicKey == other.publicKey &&
          isConnected == other.isConnected;

  @override
  int get hashCode => publicKey.hashCode ^ isConnected.hashCode;
}

class IdentityStore extends Notifier<IdentityState> {
  @override
  IdentityState build() {
    return IdentityState();
  }

  void setPublicKey(String key) {
    state = state.copyWith(publicKey: key, isConnected: true);
  }

  void disconnect() {
    state = state.copyWith(publicKey: null, isConnected: false);
  }
}

final identityStoreProvider = NotifierProvider<IdentityStore, IdentityState>(IdentityStore.new);
