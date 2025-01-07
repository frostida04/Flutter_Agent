import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> _copyAddress() async {
    if (_walletState.publicKey != null) {
      await Clipboard.setData(ClipboardData(text: _walletState.publicKey!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
            content: Text('Address copied to clipboard'),
          ),
        );
      }
    }
  }

  String _formatAddress(String address) {
    if (address.length < 8) return address;
    return '${address.substring(0, 4)}...${address.substring(address.length - 4)}';
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
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      onPressed: _isLoading ? null : _connectWallet,
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
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'copy',
          onTap: _copyAddress,
          child: _buildMenuItem(
            icon: Icons.copy,
            text: 'Copy Address',
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'disconnect',
          onTap: _disconnectWallet,
          child: _buildMenuItem(
            icon: Icons.logout,
            text: 'Disconnect',
            isDestructive: true,
          ),
        ),
      ],
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
              _formatAddress(_walletState.publicKey ?? ''),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    bool isDestructive = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDestructive ? Colors.red : null,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isDestructive ? Colors.red : null,
          ),
        ),
      ],
    );
  }
}
