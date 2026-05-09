import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../widgets/pulsating_ai_orb.dart';
import '../widgets/audit_timeline.dart';
import '../services/solana_wallet_service.dart';

class WalletConnection extends Notifier<bool> {
  @override
  bool build() => false;
  void setConnected(bool value) { state = value; }
}
final walletConnectionProvider = NotifierProvider<WalletConnection, bool>(WalletConnection.new);

class WalletAddress extends Notifier<String?> {
  @override
  String? build() => null;
  void setAddress(String? value) { state = value; }
}
final walletAddressProvider = NotifierProvider<WalletAddress, String?>(WalletAddress.new);

class DrivingModeHud extends HookConsumerWidget {
  const DrivingModeHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(walletConnectionProvider);
    final walletAddress = ref.watch(walletAddressProvider);

    final dummyEvents = [
      AuditEvent(
        title: 'Voice Command Received',
        description: 'Initiate token transfer to multisig.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isSuccess: true,
      ),
      AuditEvent(
        title: 'Policy Check',
        description: 'Validating against VoicePolicy PDA constraints.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        isSuccess: true,
      ),
      AuditEvent(
        title: 'Transaction Signed',
        description: 'Signed securely via connected wallet.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        isSuccess: true,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate
      body: SafeArea(
        child: Stack(
          children: [
            // Top Bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DRIVING MODE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (!isConnected) {
                        final address = await SolanaWalletService.connectWallet();
                        if (address != null) {
                          ref.read(walletConnectionProvider.notifier).setConnected(true);
                          ref.read(walletAddressProvider.notifier).setAddress(address);
                        }
                      }
                    },
                    icon: Icon(
                      isConnected ? Icons.check_circle : Icons.account_balance_wallet,
                      color: isConnected ? Colors.greenAccent : Colors.white,
                    ),
                    label: Text(
                      isConnected
                          ? '${walletAddress?.substring(0, 4)}...${walletAddress?.substring(walletAddress.length - 4)}'
                          : 'Connect MWA',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // AI Orb Component
            const Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Center(
                child: PulsatingAiOrb(
                  size: 200,
                  color: Colors.blueAccent,
                ),
              ),
            ),

            // Audit Timeline
            Positioned(
              top: 380,
              left: 16,
              right: 16,
              bottom: 150,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Audit Timeline',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: AuditTimeline(events: dummyEvents),
                    ),
                  ],
                ),
              ),
            ),

            // Massive Microphone Button
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    // Logic for mic action
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.purpleAccent, Colors.deepPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purpleAccent.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
