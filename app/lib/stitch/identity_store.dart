import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountInfo {
  final String publicKey;
  final String authToken;

  AccountInfo({required this.publicKey, required this.authToken});

  Map<String, dynamic> toJson() => {
        'publicKey': publicKey,
        'authToken': authToken,
      };

  factory AccountInfo.fromJson(Map<String, dynamic> json) => AccountInfo(
        publicKey: json['publicKey'],
        authToken: json['authToken'],
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountInfo &&
          runtimeType == other.runtimeType &&
          publicKey == other.publicKey &&
          authToken == other.authToken;

  @override
  int get hashCode => publicKey.hashCode ^ authToken.hashCode;
}

class IdentityState {
  final List<AccountInfo> accounts;
  final String? activePublicKey;

  IdentityState({this.accounts = const [], this.activePublicKey});

  bool get isConnected => activePublicKey != null;
  
  AccountInfo? get activeAccount {
    if (activePublicKey == null) return null;
    return accounts.firstWhere((a) => a.publicKey == activePublicKey);
  }

  IdentityState copyWith({
    List<AccountInfo>? accounts,
    String? activePublicKey,
  }) {
    return IdentityState(
      accounts: accounts ?? this.accounts,
      activePublicKey: activePublicKey ?? this.activePublicKey,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdentityState &&
          runtimeType == other.runtimeType &&
          accounts.length == other.accounts.length &&
          activePublicKey == other.activePublicKey;

  @override
  int get hashCode => accounts.length.hashCode ^ activePublicKey.hashCode;
}

class IdentityStore extends Notifier<IdentityState> {
  static const _storageKey = 'zentry_accounts';

  @override
  IdentityState build() {
    _loadFromPrefs();
    return IdentityState();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      try {
        final List<dynamic> json = jsonDecode(data);
        final accounts = json.map((a) => AccountInfo.fromJson(a)).toList();
        final activeKey = prefs.getString('${_storageKey}_active');
        state = state.copyWith(
          accounts: accounts,
          activePublicKey: activeKey ?? (accounts.isNotEmpty ? accounts.first.publicKey : null),
        );
      } catch (_) {}
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(state.accounts.map((a) => a.toJson()).toList());
    await prefs.setString(_storageKey, data);
    if (state.activePublicKey != null) {
      await prefs.setString('${_storageKey}_active', state.activePublicKey!);
    } else {
      await prefs.remove('${_storageKey}_active');
    }
  }

  void updateAccount(String key, String token) {
    final newAccount = AccountInfo(publicKey: key, authToken: token);
    final accounts = List<AccountInfo>.from(state.accounts);
    
    // Replace if exists, otherwise add
    final index = accounts.indexWhere((a) => a.publicKey == key);
    if (index != -1) {
      accounts[index] = newAccount;
    } else {
      accounts.add(newAccount);
    }

    state = state.copyWith(
      accounts: accounts,
      activePublicKey: key,
    );
    _saveToPrefs();
  }

  void switchAccount(String key) {
    if (state.accounts.any((a) => a.publicKey == key)) {
      state = state.copyWith(activePublicKey: key);
      _saveToPrefs();
    }
  }

  void removeAccount(String key) {
    final accounts = state.accounts.where((a) => a.publicKey != key).toList();
    String? newActiveKey = state.activePublicKey;
    if (newActiveKey == key) {
      newActiveKey = accounts.isNotEmpty ? accounts.first.publicKey : null;
    }
    state = state.copyWith(accounts: accounts, activePublicKey: newActiveKey);
    _saveToPrefs();
  }

  void disconnect() {
    state = state.copyWith(activePublicKey: null);
    _saveToPrefs();
  }
}

final identityStoreProvider = NotifierProvider<IdentityStore, IdentityState>(IdentityStore.new);
