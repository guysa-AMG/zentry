import 'package:hooks_riverpod/hooks_riverpod.dart';

class IdentityState {
  final String? publicKey;
  final String? authToken;
  final bool isConnected;

  IdentityState({this.publicKey, this.authToken, this.isConnected = false});

  IdentityState copyWith({String? publicKey, String? authToken, bool? isConnected}) {
    return IdentityState(
      publicKey: publicKey ?? this.publicKey,
      authToken: authToken ?? this.authToken,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdentityState &&
          runtimeType == other.runtimeType &&
          publicKey == other.publicKey &&
          authToken == other.authToken &&
          isConnected == other.isConnected;

  @override
  int get hashCode => publicKey.hashCode ^ authToken.hashCode ^ isConnected.hashCode;
}

class IdentityStore extends Notifier<IdentityState> {
  @override
  IdentityState build() {
    return IdentityState();
  }

  void updateAccount(String key, String token) {
    state = state.copyWith(publicKey: key, authToken: token, isConnected: true);
  }

  void disconnect() {
    state = state.copyWith(publicKey: null, authToken: null, isConnected: false);
  }
}

final identityStoreProvider = NotifierProvider<IdentityStore, IdentityState>(IdentityStore.new);
