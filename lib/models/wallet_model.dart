class WalletModel {
  final String? publicKey;
  final double balance;
  final bool isConnected;

  WalletModel({
    this.publicKey,
    this.balance = 0.0,
    this.isConnected = false,
  });

  WalletModel copyWith({
    String? publicKey,
    double? balance,
    bool? isConnected,
  }) {
    return WalletModel(
      publicKey: publicKey ?? this.publicKey,
      balance: balance ?? this.balance,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
