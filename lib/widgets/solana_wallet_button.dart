import 'package:flutter/material.dart';
import '../services/solana_wallet_service.dart';
import '../models/wallet_model.dart';

class SolanaWalletButton extends StatefulWidget {
  const SolanaWalletButton({super.key});

  @override
  State<SolanaWalletButton> createState() => _SolanaWalletButtonState();
}

class _SolanaWalletButtonState extends State<SolanaWalletButton> {
  late SolanaWalletService _walletService;
  WalletModel _walletState = WalletModel();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    _walletService = await SolanaWalletService.initialize();
    await _walletService.loadExistingWallet();
    await _updateWalletState();
  }

  Future<void> _updateWalletState() async {
    if (!mounted) return;

    final balance = await _walletService.getBalance();
    setState(() {
      _walletState = WalletModel(
        publicKey: _walletService.publicKey,
        balance: balance,
        isConnected: _walletService.isConnected,
      );
    });
  }

  Future<void> _connectWallet() async {
    setState(() => _isLoading = true);
    
    try {
      await _walletService.createWallet();
      await _updateWalletState();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error connecting wallet: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnectWallet() async {
    await _walletService.disconnect();
    await _updateWalletState();
  }

  @override
  Widget build(BuildContext context) {
    if (_walletState.isConnected) {
      return _buildConnectedButton();
    }
    return _buildConnectButton();
  }

  Widget _buildConnectButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _connectWallet,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Connect Wallet'),
    );
  }

  Widget _buildConnectedButton() {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_walletState.balance.toStringAsFixed(4)} SOL',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              '${_walletState.publicKey!.substring(0, 4)}...${_walletState.publicKey!.substring(_walletState.publicKey!.length - 4)}',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'disconnect',
          child: const Text('Disconnect'),
          onTap: _disconnectWallet,
        ),
      ],
    );
  }
}
