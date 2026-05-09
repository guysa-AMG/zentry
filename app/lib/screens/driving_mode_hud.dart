import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../widgets/pulsating_ai_orb.dart';
import '../widgets/audit_timeline.dart';
import '../services/solana_wallet_service.dart';

import '../stitch/identity_store.dart';
import '../stitch/intent_store.dart';

class DrivingModeHud extends HookConsumerWidget {
  const DrivingModeHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityState = ref.watch(identityStoreProvider);
    final isConnected = identityState.isConnected;
    final walletAddress = identityState.activePublicKey;

    final intentState = ref.watch(intentStoreProvider);

    return Scaffold(
      backgroundColor: Colors.black,
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
                    'HUD ACTIVE',
                    style: TextStyle(
                      color: Color(0xFF9FFC2D),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (!isConnected) {
                        final result = await SolanaWalletService.connectWallet();
                        if (result != null && !result.address.startsWith('Error')) {
                          Future.microtask(() {
                            ref.read(identityStoreProvider.notifier).updateAccount(
                              result.address, 
                              result.authToken
                            );
                            
                            final intentNotifier = ref.read(intentStoreProvider.notifier);
                            intentNotifier.addEvent(
                              'Wallet Connected',
                              'Address: ${result.address.substring(0, 4)}...${result.address.substring(result.address.length - 4)}',
                              true,
                            );
                            intentNotifier.addEvent(
                              'Zentry Sentinel Active',
                              'Sentinel Protocol initialized.',
                              true,
                            );
                          });
                        } else if (result != null) {
                          ref.read(identityStoreProvider.notifier).updateAccount(result.address, '');
                        }
                      } else {
                        // Show Account Management Dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Manage Accounts'),
                            backgroundColor: const Color(0xFF1E293B),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: identityState.accounts.length,
                                itemBuilder: (context, index) {
                                  final account = identityState.accounts[index];
                                  final isCurrent = account.publicKey == walletAddress;
                                  return ListTile(
                                    title: Text(
                                      '${account.publicKey.substring(0, 6)}...${account.publicKey.substring(account.publicKey.length - 6)}',
                                      style: TextStyle(
                                        color: isCurrent ? Colors.greenAccent : Colors.white,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!isCurrent)
                                          IconButton(
                                            icon: const Icon(Icons.swap_horiz, color: Colors.blueAccent),
                                            onPressed: () {
                                              ref.read(identityStoreProvider.notifier).switchAccount(account.publicKey);
                                              Navigator.pop(context);
                                            },
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                                          onPressed: () {
                                            ref.read(identityStoreProvider.notifier).removeAccount(account.publicKey);
                                            if (identityState.accounts.length <= 1) {
                                              Navigator.pop(context);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Add Account'),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final result = await SolanaWalletService.connectWallet();
                                  if (result != null && !result.address.startsWith('Error')) {
                                    ref.read(identityStoreProvider.notifier).updateAccount(result.address, result.authToken);
                                  }
                                },
                              ),
                              TextButton(
                                child: const Text('Close'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      isConnected ? Icons.check_circle : Icons.account_balance_wallet,
                      color: isConnected ? Colors.greenAccent : Colors.white,
                    ),
                    label: Text(
                      isConnected && walletAddress != null
                          ? walletAddress.length > 8
                              ? '${walletAddress.substring(0, 4)}...${walletAddress.substring(walletAddress.length - 4)}'
                              : walletAddress
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
            Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Center(
                child: PulsatingAiOrb(
                  size: 200,
                  color: intentState.isListening ? Colors.purpleAccent : Colors.blueAccent,
                  isActive: intentState.isListening,
                  volume: intentState.currentVolume,
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SYSTEM LOG',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: AuditTimeline(events: intentState.events.reversed.toList()),
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
                    final notifier = ref.read(intentStoreProvider.notifier);
                    if (intentState.isListening) {
                      notifier.stopVoiceSession();
                    } else {
                      notifier.startVoiceSession();
                    }
                  },
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: intentState.isListening ? Colors.redAccent : const Color(0xFF9FFC2D),
                      boxShadow: [
                        BoxShadow(
                          color: (intentState.isListening ? Colors.redAccent : const Color(0xFF9FFC2D)).withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      intentState.isListening ? Icons.stop : Icons.mic,
                      size: 40,
                      color: Colors.black,
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
