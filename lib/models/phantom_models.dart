/// Response wrapper for Phantom wallet operations
class PhantomResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? errorCode;

  PhantomResponse._({
    required this.success,
    this.data,
    this.error,
    this.errorCode,
  });

  factory PhantomResponse.success(T data) {
    return PhantomResponse._(
      success: true,
      data: data,
    );
  }

  factory PhantomResponse.error(String error, [String? errorCode]) {
    return PhantomResponse._(
      success: false,
      error: error,
      errorCode: errorCode,
    );
  }

  bool get isSuccess => success;
  bool get isError => !success;
}

/// Phantom wallet connection state
enum PhantomConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Phantom wallet account information
class PhantomAccount {
  final String publicKey;
  final String? label;
  final String? icon;

  PhantomAccount({
    required this.publicKey,
    this.label,
    this.icon,
  });

  factory PhantomAccount.fromJson(Map<String, dynamic> json) {
    return PhantomAccount(
      publicKey: json['public_key'] as String,
      label: json['label'] as String?,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'public_key': publicKey,
      if (label != null) 'label': label,
      if (icon != null) 'icon': icon,
    };
  }

  @override
  String toString() {
    return 'PhantomAccount(publicKey: $publicKey, label: $label)';
  }
}

/// Transaction signature response
class TransactionSignature {
  final String signature;
  final String? publicKey;

  TransactionSignature({
    required this.signature,
    this.publicKey,
  });

  factory TransactionSignature.fromJson(Map<String, dynamic> json) {
    return TransactionSignature(
      signature: json['signature'] as String,
      publicKey: json['public_key'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'signature': signature,
      if (publicKey != null) 'public_key': publicKey,
    };
  }
}

/// Message signature response
class MessageSignature {
  final String signature;
  final String publicKey;

  MessageSignature({
    required this.signature,
    required this.publicKey,
  });

  factory MessageSignature.fromJson(Map<String, dynamic> json) {
    return MessageSignature(
      signature: json['signature'] as String,
      publicKey: json['public_key'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'signature': signature,
      'public_key': publicKey,
    };
  }
}

/// Phantom wallet error codes
enum PhantomErrorCode {
  userRejectedTheRequest(4001),
  unauthorizedToPerformRequestedMethod(4100),
  unsupportedMethod(4200),
  disconnected(4900),
  chainDisconnected(4901);

  const PhantomErrorCode(this.code);
  final int code;

  static PhantomErrorCode? fromCode(int code) {
    for (final errorCode in PhantomErrorCode.values) {
      if (errorCode.code == code) {
        return errorCode;
      }
    }
    return null;
  }
}

/// Phantom wallet error
class PhantomError {
  final PhantomErrorCode code;
  final String message;

  PhantomError({
    required this.code,
    required this.message,
  });

  factory PhantomError.fromJson(Map<String, dynamic> json) {
    final code = PhantomErrorCode.fromCode(json['code'] as int) ??
        PhantomErrorCode.userRejectedTheRequest;
    return PhantomError(
      code: code,
      message: json['message'] as String,
    );
  }

  @override
  String toString() {
    return 'PhantomError(code: ${code.code}, message: $message)';
  }
}

/// Solana cluster configuration
enum SolanaCluster {
  mainnetBeta('mainnet-beta'),
  testnet('testnet'),
  devnet('devnet');

  const SolanaCluster(this.value);
  final String value;
}

/// Phantom connection parameters
class PhantomConnectParams {
  final String appUrl;
  final SolanaCluster cluster;
  final String? redirectLink;

  PhantomConnectParams({
    required this.appUrl,
    this.cluster = SolanaCluster.mainnetBeta,
    this.redirectLink,
  });

  Map<String, dynamic> toJson() {
    return {
      'app_url': appUrl,
      'cluster': cluster.value,
      if (redirectLink != null) 'redirect_link': redirectLink,
    };
  }
}

