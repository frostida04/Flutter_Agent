import 'package:solana/solana.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Fixed import
import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:hex/hex.dart';

class SolanaWalletService {
  static const String _privateKeyKey = 'private_key';
  static const String _publicKeyKey = 'public_key';
  static const int lamportsPerSol = 1000000000; // Added constant
  
  final SharedPreferences _prefs;
  final SolanaClient _client;
  Ed25519HDKeyPair? _keypair;
  
  SolanaWalletService._(this._prefs, this._client);
  
  static Future<SolanaWalletService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final client = SolanaClient(
      rpcUrl: Uri.parse('https://api.devnet.solana.com'),
      websocketUrl: Uri.parse('wss://api.devnet.solana.com'),
    );
    
    return SolanaWalletService._(prefs, client);
  }

  bool get isConnected => _keypair != null;
  
  String? get publicKey => _keypair?.address;
  
  Future<void> createWallet() async {
    try {
      // Generate a new mnemonic
      final mnemonic = bip39.generateMnemonic();
      final seed = bip39.mnemonicToSeed(mnemonic);
      final masterKey = await ED25519_HD_KEY.getMasterKeyFromSeed(seed);
      
      _keypair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
        privateKey: masterKey.key,
      );
      
      // Save the keys
      await _prefs.setString(_privateKeyKey, HEX.encode(masterKey.key));
      await _prefs.setString(_publicKeyKey, _keypair!.address);
      
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadExistingWallet() async {
    final privateKeyHex = _prefs.getString(_privateKeyKey);
    if (privateKeyHex != null) {
      final privateKey = HEX.decode(privateKeyHex);
      _keypair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
        privateKey: privateKey,
      );
    }
  }

  Future<double> getBalance() async {
    if (_keypair == null) return 0.0;
    
    try {
      final balance = await _client.rpcClient.getBalance(
        _keypair!.address,
        commitment: Commitment.confirmed,
      );
      
      // Fixed balance calculation
      return balance.value / lamportsPerSol;
    } catch (e) {
      return 0.0;
    }
  }

  Future<String?> sendTransaction({
    required String recipient,
    required double amount,
  }) async {
    if (_keypair == null) return null;
    
    try {
      final instruction = SystemInstruction.transfer(
        fundingAccount: _keypair!.publicKey,
        recipientAccount: Ed25519HDPublicKey.fromBase58(recipient),
        lamports: (amount * lamportsPerSol).toInt(),
      );

      final message = Message(instructions: [instruction]);
      final signature = await _client.sendAndConfirmTransaction(
        message: message,
        signers: [_keypair!],
        commitment: Commitment.confirmed,
      );
      
      return signature;
    } catch (e) {
      return null;
    }
  }

  Future<void> disconnect() async {
    await _prefs.remove(_privateKeyKey);
    await _prefs.remove(_publicKeyKey);
    _keypair = null;
  }
}
