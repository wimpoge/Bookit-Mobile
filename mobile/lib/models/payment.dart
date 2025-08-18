import 'dart:convert';

class PaymentMethod {
  final int id;
  final int userId;
  final String type;
  final String provider;
  final Map<String, dynamic> accountInfo;
  final bool isDefault;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.provider,
    required this.accountInfo,
    required this.isDefault,
    required this.createdAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      provider: json['provider'],
      accountInfo: Map<String, dynamic>.from(json['account_info']),
      isDefault: json['is_default'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'provider': provider,
      'account_info': accountInfo,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  PaymentMethod copyWith({
    int? id,
    int? userId,
    String? type,
    String? provider,
    Map<String, dynamic>? accountInfo,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      accountInfo: accountInfo ?? this.accountInfo,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayName {
    switch (provider.toLowerCase()) {
      case 'visa':
      case 'mastercard':
        final lastFour = accountInfo['last_four'] ?? '****';
        return '$provider •••• $lastFour';
      case 'apple_pay':
        return 'Apple Pay';
      case 'google_pay':
        return 'Google Pay';
      case 'paypal':
        return accountInfo['email'] ?? 'PayPal';
      case 'qris':
        return 'QRIS';
      default:
        return provider;
    }
  }

  String get iconAsset {
    switch (provider.toLowerCase()) {
      case 'visa':
        return 'assets/icons/visa.svg';
      case 'mastercard':
        return 'assets/icons/mastercard.svg';
      case 'apple_pay':
        return 'assets/icons/apple_pay.svg';
      case 'google_pay':
        return 'assets/icons/google_pay.svg';
      case 'paypal':
        return 'assets/icons/paypal.svg';
      case 'qris':
        return 'assets/icons/qris.svg';
      default:
        return 'assets/icons/credit_card.svg';
    }
  }
}

class Payment {
  final int id;
  final double amount;
  final String currency;
  final String status;
  final String? transactionId;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    this.transactionId,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      status: json['status'],
      transactionId: json['transaction_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'status': status,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  Payment copyWith({
    int? id,
    double? amount,
    String? currency,
    String? status,
    String? transactionId,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isFailed => status.toLowerCase() == 'failed';
}