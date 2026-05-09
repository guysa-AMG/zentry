import 'dart:typed_data';
import 'package:solana_mobile_client/solana_mobile_client.dart';
import 'package:bs58/bs58.dart';

class WalletConnectionResult {
  final String address;
  final String authToken;
  WalletConnectionResult(this.address, this.authToken);
}

class SolanaWalletService {
  static Future<WalletConnectionResult?> connectWallet() async {
    if (!await LocalAssociationScenario.isAvailable()) {
      return null;
    }

    try {
      final session = await LocalAssociationScenario.create();
      session.startActivityForResult(null).ignore();
      
      final client = await session.start();
      
      final result = await client.authorize(
        identityUri: Uri.parse('https://example.com'),
        iconUri: Uri.parse('https://example.com/favicon.ico'),
        identityName: 'Zentry Voice App',
        cluster: 'devnet',
      );
      
      await session.close();
      
      if (result != null) {
        // Return public key as base58 string and the auth token
        final address = base58.encode(Uint8List.fromList(result.publicKey));
        return WalletConnectionResult(address, result.authToken);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error connecting wallet: $e');
      return WalletConnectionResult('Error: $e', '');
    }
    return null;
  }
}
