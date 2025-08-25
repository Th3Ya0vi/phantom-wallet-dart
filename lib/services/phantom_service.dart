import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bs58/bs58.dart';
import 'package:pinenacl/x25519.dart';
import 'package:http/http.dart' as http;
import '../models/phantom_models.dart';

class PhantomService extends ChangeNotifier {
  // Constants for URL building
  static const String _baseUrl = 'https://phantom.app/ul/v1';
  static const String _customProtocol = 'phantom://v1';
  
  // Toggle between universal links and custom protocol
  bool _useUniversalLinks = true; // Use universal links as recommended by Phantom
  
  // Wallet connection details
  String? _publicKey;
  String? _session;
  bool _isConnected = false;
  String? _phantomEncryptionPublicKey;
  
  // App configuration
  String _appUrl = 'https://phantom.app'; // Use a proper URL that Phantom can use to fetch app metadata
  String _redirectLink = 'phantomdemo://connect';
  
  // Encryption details - following the NaCl protocol
  String? _dappEncryptionPublicKey;
  PrivateKey? _dappPrivateKey;
  
  // Getters
  String? get publicKey => _publicKey;
  String? get session => _session;
  bool get isConnected => _isConnected;
  String? get redirectLink => _redirectLink;
  
  /// Check if session might be expired (simple heuristic)
  bool get shouldReconnect {
    if (!_isConnected || _session == null || _phantomEncryptionPublicKey == null) {
      return true;
    }
    
    // Additional checks could be added here (time-based, etc.)
    return false;
  }
  
  PhantomService() {
    _generateKeyPair();
    _loadSession();
  }
  
  // Proper base58 encoding for Solana/Phantom compatibility
  String _encodeBase58(Uint8List data) {
    final encoded = base58.encode(data);
    debugPrint('🔍 Base58 encoding: ${data.toList()} → "$encoded"');
    
    // Verify encoding/decoding works
    try {
      final decoded = base58.decode(encoded);
      final matches = decoded.toString() == data.toList().toString();
      debugPrint('🔍 Base58 verification: ${matches ? "✅ PASS" : "❌ FAIL"}');
      if (!matches) {
        debugPrint('  Original: ${data.toList()}');
        debugPrint('  Decoded:  $decoded');
      }
    } catch (e) {
      debugPrint('❌ Base58 verification failed: $e');
    }
    
    return encoded;
  }
  
  // Proper base58 decoding for Solana/Phantom compatibility
  Uint8List _decodeBase58(String encoded) {
    return Uint8List.fromList(base58.decode(encoded));
  }
  
  /// Generate the key pair for encryption using X25519 (compatible with TweetNaCl)
  Future<void> _generateKeyPair() async {
    try {
      // Generate an X25519 key pair for NaCl box encryption using PineNaCl
      _dappPrivateKey = PrivateKey.generate();
      
      // Get the public key and encode as base58
      _dappEncryptionPublicKey = _encodeBase58(_dappPrivateKey!.publicKey.asTypedList);
      
      debugPrint('Generated dapp encryption public key: $_dappEncryptionPublicKey');
      debugPrint('Public key length: ${_dappPrivateKey!.publicKey.asTypedList.length} bytes');
      debugPrint('Private key length: ${_dappPrivateKey!.asTypedList.length} bytes');
    } catch (e) {
      debugPrint('Error generating key pair: $e');
      rethrow;
    }
  }
  
  /// Load saved session from local storage
  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _session = prefs.getString('phantom_session');
      _publicKey = prefs.getString('phantom_public_key');
      _phantomEncryptionPublicKey = prefs.getString('phantom_encryption_public_key');
      _isConnected = _session != null && _publicKey != null && _phantomEncryptionPublicKey != null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading session: $e');
    }
  }
  
  /// Save session to local storage
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_session != null && _publicKey != null && _phantomEncryptionPublicKey != null) {
        await prefs.setString('phantom_session', _session!);
        await prefs.setString('phantom_public_key', _publicKey!);
        await prefs.setString('phantom_encryption_public_key', _phantomEncryptionPublicKey!);
      } else {
        await prefs.remove('phantom_session');
        await prefs.remove('phantom_public_key');
        await prefs.remove('phantom_encryption_public_key');
      }
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }
  
  /// Generate a random nonce for security
  String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (i) => random.nextInt(256)); // NaCl nonce is 24 bytes
    return _encodeBase58(Uint8List.fromList(bytes));
  }
  
  /// Create a dummy transaction for testing (in real usage, use proper Solana transaction)
  String _createDummyTransaction() {
    // Create a minimal but valid Solana transaction structure
    // This matches the format that Phantom expects
    final random = Random.secure();
    
    // Minimal Solana transaction structure:
    // - Signatures section: 1 byte (count) + 64 bytes per signature
    // - Message section with proper header and accounts
    final txBytes = <int>[
      // Signatures section
      1, // Number of signatures
      ...List.filled(64, 0), // Signature placeholder (will be filled by Phantom)
      
      // Message section
      // Header (3 bytes)
      1, // Number of required signatures  
      0, // Number of readonly signed accounts
      1, // Number of readonly unsigned accounts
      
      // Accounts section  
      3, // Number of accounts
      // Account 1: Fee payer (32 bytes)
      ...List.generate(32, (i) => random.nextInt(256)),
      // Account 2: System program (32 bytes) 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      // Account 3: Destination (32 bytes)
      ...List.generate(32, (i) => random.nextInt(256)),
      
      // Recent blockhash (32 bytes)
      ...List.generate(32, (i) => random.nextInt(256)),
      
      // Instructions section
      1, // Number of instructions
      // Instruction 1: Transfer instruction
      1, // Program ID index (system program)
      2, // Number of accounts in instruction
      0, 2, // Account indices (from, to)
      4, // Instruction data length
      2, 0, 0, 0, // Transfer instruction type + minimal lamports
    ];
    
    debugPrint('Generated valid dummy transaction with ${txBytes.length} bytes');
    return _encodeBase58(Uint8List.fromList(txBytes));
  }
  
  /// Create properly encrypted payload using NaCl box (equivalent to React Native nacl.box.after)
  Future<String> _createEncryptedPayload(Map<String, dynamic> data, String nonce, String phantomPublicKey) async {
    try {
      final jsonString = jsonEncode(data);
      debugPrint('JSON payload to encrypt: $jsonString');
      final messageBytes = Uint8List.fromList(utf8.encode(jsonString));
      final nonceBytes = _decodeBase58(nonce);
      
      debugPrint('Message bytes length: ${messageBytes.length}');
      debugPrint('Nonce bytes length: ${nonceBytes.length}');

      // Create Box object (pinenacl automatically computes shared secret internally)
      final phantomPublicKeyBytes = _decodeBase58(phantomPublicKey);
      final phantomPublicKeyObj = PublicKey(phantomPublicKeyBytes);
      final box = Box(myPrivateKey: _dappPrivateKey!, theirPublicKey: phantomPublicKeyObj);
      
      // Encrypt using TweetNaCl box (equivalent to nacl.box.after)
      final encrypted = box.encrypt(messageBytes, nonce: nonceBytes);
      final result = _encodeBase58(encrypted.cipherText.asTypedList);
      
      debugPrint('Encrypted payload length: ${result.length}');
      debugPrint('✅ Encryption successful with NaCl box');
      return result;
    } catch (e) {
      debugPrint('❌ Encryption error: $e');
      rethrow;
    }
  }

  /// Build URL for Phantom deep links
  String _buildUrl(String path, Map<String, String> queryParams) {
    // Create URL based on preference for universal links or custom protocol
    final baseUrl = _useUniversalLinks ? _baseUrl : _customProtocol;
    final uri = Uri.parse('$baseUrl/$path');
    
    // Add query parameters to create the final URL
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '${uri.toString()}?$queryString';
  }

  /// Connect to Phantom wallet
  Future<PhantomResponse<String>> connect({
    String? appUrl,
    String? cluster,
  }) async {
    try {
      // Update app URL if provided
      if (appUrl != null) {
        _appUrl = appUrl;
      }
      
      // Set redirect link for the connection response
      _redirectLink = 'phantomdemo://connect';
      
      // Create query parameters
      final queryParams = {
        'dapp_encryption_public_key': _dappEncryptionPublicKey!,
        'cluster': cluster ?? 'mainnet-beta',
        'app_url': _appUrl,
        'redirect_link': _redirectLink,
      };
      
      // Build the URL using the helper method
      final url = _buildUrl('connect', queryParams);
      
      debugPrint('Connecting to Phantom with URL: $url');
      debugPrint('Using dapp public key: $_dappEncryptionPublicKey');
      
      // Launch the URL
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        return PhantomResponse.error('Failed to launch Phantom app');
      }
      
      return PhantomResponse.success('Connection request sent to Phantom wallet');
    } catch (e) {
      return PhantomResponse.error('Connection failed: $e');
    }
  }
  
  /// Decrypt payload using NaCl box (equivalent to React Native's nacl.box.open.after)
  Future<Map<String, dynamic>> _decryptPayload(String data, String nonce, String phantomPublicKey) async {
    final encryptedBytes = _decodeBase58(data);
    final nonceBytes = _decodeBase58(nonce);

    debugPrint('Decrypting data with ${encryptedBytes.length} bytes');
    debugPrint('Using nonce with ${nonceBytes.length} bytes');

    try {
      // Create Box object (pinenacl automatically computes shared secret internally)
      final phantomPublicKeyBytes = _decodeBase58(phantomPublicKey);
      final phantomPublicKeyObj = PublicKey(phantomPublicKeyBytes);
      final box = Box(myPrivateKey: _dappPrivateKey!, theirPublicKey: phantomPublicKeyObj);
      
      debugPrint('Phantom public key bytes length: ${phantomPublicKeyBytes.length}');
      debugPrint('Our private key length: ${_dappPrivateKey!.asTypedList.length}');
      
      // Decrypt using TweetNaCl box (equivalent to nacl.box.open.after)
      late Uint8List decryptedBytes;
      
      try {
        debugPrint('🔍 Decrypting with NaCl box...');
        
        final encryptedBox = EncryptedMessage(cipherText: encryptedBytes, nonce: nonceBytes);
        decryptedBytes = box.decrypt(encryptedBox);
        debugPrint('✅ NaCl box decryption successful!');
      } catch (e) {
        debugPrint('❌ NaCl box decryption failed: $e');
        throw Exception('Decryption failed with NaCl box approach');
      }
      
      final jsonString = utf8.decode(decryptedBytes);
      debugPrint('✅ Successfully decrypted with TweetNaCl box: $jsonString');
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ TweetNaCl box decryption failed: $e');
      throw Exception('Unable to decrypt data with NaCl box - ensure proper key exchange: $e');
    }
  }
  


  /// Handle connection response from Phantom with proper shared secret generation
  Future<PhantomResponse<String>> handleConnectResponse(Map<String, String> params) async {
    try {
      // Check if we have the phantom encryption public key and nonce
      final phantomEncryptionPublicKey = params['phantom_encryption_public_key'];
      final nonce = params['nonce'];
      final data = params['data'];
      
      if (phantomEncryptionPublicKey == null || nonce == null || data == null) {
        return PhantomResponse.error('Missing encryption parameters from Phantom');
      }
      
      debugPrint('Received phantom encryption public key: $phantomEncryptionPublicKey');
      
      // Store phantom public key for future encryption
      _phantomEncryptionPublicKey = phantomEncryptionPublicKey;
      
      debugPrint('✅ Phantom public key stored for shared secret computation');
      
      // Decrypt the data using NaCl box encryption
      final decryptedData = await _decryptPayload(data, nonce, phantomEncryptionPublicKey);
      
      // Extract the REAL wallet public key and session
      _publicKey = decryptedData['public_key'] as String;
      _session = decryptedData['session'] as String;
      _isConnected = true;
      
      await _saveSession();
      notifyListeners();
      
      debugPrint('Successfully connected to REAL wallet: $_publicKey');
      return PhantomResponse.success('Connected successfully to $_publicKey');
    } catch (e) {
      debugPrint('Connection processing failed: $e');
      return PhantomResponse.error('Failed to process connection response: $e');
    }
  }
  
  /// Wrapper to handle string response data for compatibility
  Future<PhantomResponse<String>> handleConnectResponseData(String responseData) async {
    try {
      // Convert base64 response to parameters
      final decodedData = utf8.decode(base64Url.decode(responseData));
      final params = jsonDecode(decodedData) as Map<String, dynamic>;
      
      return handleConnectResponse(
        params.map((key, value) => MapEntry(key, value.toString()))
      );
    } catch (e) {
      return PhantomResponse.error('Failed to process connection response data: $e');
    }
  }
  
  /// Disconnect from Phantom wallet
  Future<PhantomResponse<String>> disconnect() async {
    try {
      if (!_isConnected || _session == null) {
        return PhantomResponse.error('Not connected to Phantom');
      }
      
      // Create payload with REAL session
      final payload = {
        'session': _session,
      };
      
      // Generate a nonce for this request
      final nonce = _generateNonce();
      
      // Use REAL NaCl encryption
      final encryptedPayload = await _createEncryptedPayload(payload, nonce, _phantomEncryptionPublicKey!);
      
      final queryParams = {
        'dapp_encryption_public_key': _dappEncryptionPublicKey!,
        'nonce': nonce,
        'redirect_link': 'phantomdemo://disconnected',
        'payload': encryptedPayload,
      };
      
      final url = _buildUrl('disconnect', queryParams);
      
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (launched) {
        _publicKey = null;
        _session = null;
        _phantomEncryptionPublicKey = null;
        _isConnected = false;
        
        await _saveSession();
        notifyListeners();
        
        return PhantomResponse.success('Disconnected successfully');
      } else {
        return PhantomResponse.error('Failed to launch Phantom app');
      }
    } catch (e) {
      return PhantomResponse.error('Disconnect failed: $e');
    }
  }
  
  /// Sign a transaction with REAL encryption (EXACT React Native format)
  Future<PhantomResponse<String>> signTransaction({
    String? transaction, // Make optional for testing
    String? message,
  }) async {
    try {
      if (!_isConnected || _session == null) {
        return PhantomResponse.error('Not connected to Phantom');
      }
      
      if (shouldReconnect) {
        debugPrint('⚠️  Session may be expired - recommend reconnecting');
        return PhantomResponse.error('Session may be expired. Try "Reconnect" for a fresh session.');
      }
      
      // Use provided transaction or create dummy for testing
      final txToSign = transaction ?? _createDummyTransaction();
      
      debugPrint('🔄 Using EXACT React Native signTransaction format');
      debugPrint('Transaction to sign: ${txToSign.substring(0, 50)}...');
      
      // EXACT React Native payload format
      final payload = {
        'session': _session,
        'transaction': txToSign, // Should be base58-encoded serialized Solana transaction
      };
      
      // Generate a nonce for this request
      final nonce = _generateNonce();
      
      // Use REAL NaCl encryption
      final encryptedPayload = await _createEncryptedPayload(payload, nonce, _phantomEncryptionPublicKey!);
      
      final queryParams = {
        'dapp_encryption_public_key': _dappEncryptionPublicKey!,
        'nonce': nonce,
        'redirect_link': 'phantomdemo://signed',
        'payload': encryptedPayload,
      };
      
      final url = _buildUrl('signTransaction', queryParams);
      
      debugPrint('Phantom sign transaction URL: $url');
      debugPrint('🔍 URL length: ${url.length} characters');
      
      // Check if URL is too long for iOS (limit ~2000-8000 chars depending on context)
      if (url.length > 2000) {
        debugPrint('⚠️  WARNING: URL is quite long (${url.length} chars) - might hit iOS limits');
      }
      
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        return PhantomResponse.error('Failed to launch Phantom app');
      }
      
      return PhantomResponse.success('Transaction signing request sent');
    } catch (e) {
      return PhantomResponse.error('Sign transaction failed: $e');
    }
  }
  
  /// Sign a message using EXACT React Native format (no display parameter!)
  Future<PhantomResponse<String>> signMessage({
    required String message,
    int approach = 1, // Keep for testing but simplify
  }) async {
    try {
      if (!_isConnected || _session == null) {
        return PhantomResponse.error('Not connected to Phantom');
      }
      
      if (shouldReconnect) {
        debugPrint('⚠️  Session may be expired - recommend reconnecting');
        return PhantomResponse.error('Session may be expired. Try "Reconnect" for a fresh session.');
      }
      
      debugPrint('🔄 Using EXACT React Native signMessage format');
      debugPrint('Using REAL session token for signing: ${_session?.substring(0, 50)}...');
      debugPrint('Full session token: $_session');
      debugPrint('Message being signed: $message');
      debugPrint('Phantom public key: $_phantomEncryptionPublicKey');
      
      // EXACT React Native format: bs58.encode(Buffer.from(message))
      final messageBytes = Uint8List.fromList(utf8.encode(message));
      final encodedMessage = _encodeBase58(messageBytes);
      
      debugPrint('Message UTF-8 bytes: $messageBytes');
      debugPrint('Message bytes length: ${messageBytes.length}');
      debugPrint('Base58 encoded message: $encodedMessage');
      debugPrint('Base58 encoded length: ${encodedMessage.length}');
      
      // EXACT React Native payload format - NO display parameter!
      final payload = {
        'session': _session,
        'message': encodedMessage,
      };
      
      debugPrint('🔍 Session token length: ${_session!.length}');
      debugPrint('🔍 Message length: ${encodedMessage.length}');
      
      // Generate a nonce for this request  
      final nonce = _generateNonce();
      
      debugPrint('Payload before encryption: ${jsonEncode(payload)}');
      
      // Use REAL NaCl encryption for the payload
      final encryptedPayload = await _createEncryptedPayload(payload, nonce, _phantomEncryptionPublicKey!);
      
      final queryParams = {
        'dapp_encryption_public_key': _dappEncryptionPublicKey!,
        'nonce': nonce,
        'redirect_link': 'phantomdemo://message-signed',
        'payload': encryptedPayload,
      };
      
      final url = _buildUrl('signMessage', queryParams);
      
      debugPrint('Phantom sign message URL: $url');
      debugPrint('🔍 URL length: ${url.length} characters');
      debugPrint('🔍 Expected React Native format: session + message (base58)');
      debugPrint('🔍 Our session length: ${_session!.length}');
      debugPrint('🔍 Our message: "$message" → base58: "$encodedMessage"');
      
      // Check if URL is too long for iOS (limit ~2000-8000 chars depending on context)
      if (url.length > 2000) {
        debugPrint('⚠️  WARNING: URL is quite long (${url.length} chars) - might hit iOS limits');
      }
      
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        return PhantomResponse.error('Failed to launch Phantom app');
      }
      
      return PhantomResponse.success('Message signing request sent');
    } catch (e) {
      return PhantomResponse.error('Sign message failed: $e');
    }
  }
  
  /// Sign multiple transactions (Phantom's new recommended approach)
  Future<PhantomResponse<String>> signAllTransactions({
    required List<String> transactions,
    String? message,
  }) async {
    try {
      if (!_isConnected || _session == null) {
        return PhantomResponse.error('Not connected to Phantom');
      }
      
      // Create payload with REAL session
      final payload = {
        'transactions': transactions, // Array of base58-encoded transactions
        'session': _session,
        if (message != null) 'message': message,
      };
      
      // Generate a nonce for this request
      final nonce = _generateNonce();
      
      // Use REAL NaCl encryption
      final encryptedPayload = await _createEncryptedPayload(payload, nonce, _phantomEncryptionPublicKey!);
      
      final queryParams = {
        'dapp_encryption_public_key': _dappEncryptionPublicKey!,
        'nonce': nonce,
        'redirect_link': 'phantomdemo://signed-all',
        'payload': encryptedPayload,
      };
      
      final url = _buildUrl('signAllTransactions', queryParams);
      
      debugPrint('Phantom sign all transactions URL: $url');
      debugPrint('🔍 URL length: ${url.length} characters');
      
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        return PhantomResponse.error('Failed to launch Phantom app');
      }
      
      return PhantomResponse.success('Multiple transaction signing request sent');
    } catch (e) {
      return PhantomResponse.error('Sign all transactions failed: $e');
    }
  }
  
  /// Handle signed transaction response from Phantom
  Future<PhantomResponse<String>> handleSignedTransactionResponse(Map<String, String> params) async {
    try {
      final nonce = params['nonce'];
      final data = params['data'];
      
      if (nonce == null || data == null) {
        return PhantomResponse.error('Missing response parameters from Phantom');
      }
      
      // Decrypt the signed transaction
      final decryptedData = await _decryptPayload(data, nonce, _phantomEncryptionPublicKey!);
      
      // Extract the signed transaction
      final signedTransaction = decryptedData['transaction'] as String;
      
      debugPrint('✅ Received signed transaction: ${signedTransaction.substring(0, 50)}...');
      
      return PhantomResponse.success(signedTransaction);
    } catch (e) {
      debugPrint('❌ Failed to process signed transaction: $e');
      return PhantomResponse.error('Failed to process signed transaction: $e');
    }
  }
  
  /// Handle signed all transactions response from Phantom
  Future<PhantomResponse<List<String>>> handleSignedAllTransactionsResponse(Map<String, String> params) async {
    try {
      final nonce = params['nonce'];
      final data = params['data'];
      
      if (nonce == null || data == null) {
        return PhantomResponse.error('Missing response parameters from Phantom');
      }
      
      // Decrypt the signed transactions
      final decryptedData = await _decryptPayload(data, nonce, _phantomEncryptionPublicKey!);
      
      // Extract the signed transactions
      final signedTransactions = (decryptedData['transactions'] as List<dynamic>)
          .cast<String>();
      
      debugPrint('✅ Received ${signedTransactions.length} signed transactions');
      
      return PhantomResponse.success(signedTransactions);
    } catch (e) {
      debugPrint('❌ Failed to process signed transactions: $e');
      return PhantomResponse.error('Failed to process signed transactions: $e');
    }
  }
  
  /// Broadcast signed transaction to Solana network
  Future<PhantomResponse<String>> broadcastTransaction({
    required String signedTransaction,
    String rpcUrl = 'https://api.mainnet-beta.solana.com',
  }) async {
    try {
      debugPrint('📡 Broadcasting transaction to Solana network...');
      
      final requestBody = {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'sendTransaction',
        'params': [
          signedTransaction,
          {
            'encoding': 'base58',
            'skipPreflight': false,
            'preflightCommitment': 'processed',
          }
        ],
      };
      
      final response = await http.post(
        Uri.parse(rpcUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData.containsKey('error')) {
          final error = responseData['error'];
          debugPrint('❌ RPC Error: ${error['message']}');
          return PhantomResponse.error('Transaction failed: ${error['message']}');
        }
        
        final txSignature = responseData['result'] as String;
        debugPrint('✅ Transaction broadcasted successfully!');
        debugPrint('🔗 Transaction signature: $txSignature');
        
        return PhantomResponse.success(txSignature);
      } else {
        return PhantomResponse.error('Failed to broadcast transaction: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Broadcast error: $e');
      return PhantomResponse.error('Failed to broadcast transaction: $e');
    }
  }
  
  /// Handle generic deeplink response
  Future<PhantomResponse<Map<String, dynamic>>> handleDeeplinkResponse(
    String responseData,
  ) async {
    try {
      final decodedData = utf8.decode(base64Url.decode(responseData));
      final response = jsonDecode(decodedData) as Map<String, dynamic>;
      
      if (response.containsKey('errorCode')) {
        return PhantomResponse.error(
          response['errorMessage'] ?? 'Unknown error occurred',
        );
      }
      
      return PhantomResponse.success(response);
    } catch (e) {
      return PhantomResponse.error('Failed to process response: $e');
    }
  }
  
  /// Set custom app URL scheme
  void setAppUrl(String appUrl) {
    _appUrl = appUrl;
  }
}