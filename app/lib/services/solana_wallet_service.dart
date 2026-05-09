import 'dart:typed_data';
import 'package:solana_mobile_client/solana_mobile_client.dart';
import 'package:bs58/bs58.dart';

class SolanaWalletService {
  static Future<String?> connectWallet() async {
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
        // Return public key as base58 string
        return base58.encode(Uint8List.fromList(result.publicKey));
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error connecting wallet: $e');
      return 'Error: $e';
    }
    return null;
  }
}
