import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/phantom_models.dart';

class PhantomService extends ChangeNotifier {
  static const String _baseUrl = 'https://phantom.app/ul/v1';
  static const String _customProtocol = 'phantom://v1';
  
  String? _publicKey;
  String? _session;
  bool _isConnected = false;
  String _appUrl = 'phantomdemo://';
  String? _redirectLink;
  
  // Getters
  String? get publicKey => _publicKey;
  String? get session => _session;
  bool get isConnected => _isConnected;
  String? get redirectLink => _redirectLink;
  
  PhantomService() {
    _loadSession();
  }
  
  /// Load saved session from local storage
  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _session = prefs.getString('phantom_session');
      _publicKey = prefs.getString('phantom_public_key');
      _isConnected = _session != null && _publicKey != null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading session: $e');
    }
  }
  
  /// Save session to local storage
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_session != null && _publicKey != null) {
        await prefs.setString('phantom_session', _session!);
        await prefs.setString('phantom_public_key', _publicKey!);
      } else {
        await prefs.remove('phantom_session');
        await prefs.remove('phantom_public_key');
      }
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }
  
  /// Generate a random nonce for security
  String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }
  
  /// Create encrypted payload for secure communication
  String _createEncryptedPayload(Map<String, dynamic> data) {
    // In a production app, you would implement proper encryption here
    // For demo purposes, we'll use base64 encoding
    final jsonString = jsonEncode(data);
    return base64Url.encode(utf8.encode(jsonString));
  }
  
  /// Connect to Phantom wallet
  Future<PhantomResponse<String>> connect({
    String? appUrl,
    String? cluster,
  }) async {
    try {
      _appUrl = appUrl ?? _appUrl;
      
      // Create minimal required parameters for Phantom
      final params = {
        'app_url': _appUrl,
        'cluster': cluster ?? 'devnet', // Use devnet for testing
        'redirect_link': '${_appUrl}connected',
      };
      
      // Encode parameters as JSON then base64
      final jsonParams = jsonEncode(params);
      final encodedParams = base64Url.encode(utf8.encode(jsonParams));
      
      // Try custom protocol first (phantom://), then universal link
      final customUrl = '$_customProtocol/connect?params=$encodedParams';
      final universalUrl = '$_baseUrl/connect?params=$encodedParams';
      
      _redirectLink = '${_appUrl}connected';
      
      debugPrint('Trying Phantom custom protocol: $customUrl');
      debugPrint('Parameters: $jsonParams');
      
      // Try custom protocol first
      var uri = Uri.parse(customUrl);
      var launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      // If custom protocol fails, try universal link
      if (!launched) {
        debugPrint('Custom protocol failed, trying universal link: $universalUrl');
        uri = Uri.parse(universalUrl);
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
      
      if (!launched) {
        return PhantomResponse.error('Failed to launch Phantom app');
      }
      
      return PhantomResponse.success('Connection request sent');
    } catch (e) {
      return PhantomResponse.error('Connection failed: $e');
    }
  }
  
  /// Handle connection response from Phantom
  Future<PhantomResponse<String>> handleConnectResponse(String responseData) async {
    try {
      final decodedData = utf8.decode(base64Url.decode(responseData));
      final response = jsonDecode(decodedData) as Map<String, dynamic>;
      
      if (response.containsKey('public_key')) {
        _publicKey = response['public_key'] as String;
        _session = response['session'] ?? _generateNonce();
        _isConnected = true;
        
        await _saveSession();
        notifyListeners();
        
        return PhantomResponse.success('Connected successfully');
      } else {
        return PhantomResponse.error('Invalid connection response');
      }
    } catch (e) {
      return PhantomResponse.error('Failed to process connection response: $e');
    }
  }
  
  /// Disconnect from Phantom wallet
  Future<PhantomResponse<String>> disconnect() async {
    try {
      if (!_isConnected || _session == null) {
        return PhantomResponse.error('Not connected to Phantom');
      }
      
      final params = {
        'session': _session,
        'redirect_link': '${_appUrl}disconnected',
      };
      
      final encodedParams = Uri.encodeQueryComponent(jsonEncode(params));
      final url = '$_baseUrl/disconnect?params=$encodedParams';
      
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (launched) {
        _publicKey = null;
        _session = null;
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
  
  /// Sign a transaction
  Future<PhantomResponse<String>> signTransaction({
    required String transaction,
    String? message,
  }) async {
    try {
      if (!_isConnected || _session == null) {
        return PhantomResponse.error('Not connected to Phantom');
      }
      
      final params = {
        'session': _session,
        'transaction': transaction,
        if (message != null) 'message': message,
        'redirect_link': '${_appUrl}signed',
      };
      
      // Encode parameters as JSON then base64
      final jsonParams = jsonEncode(params);
      final encodedParams = base64Url.encode(utf8.encode(jsonParams));
      final url = '$_baseUrl/signTransaction?params=$encodedParams';
      
      debugPrint('Phantom sign transaction URL: $url');
      
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
  
  /// Sign a message
  Future<PhantomResponse<String>> signMessage({
    required String message,
    bool display = true,
  }) async {
    try {
      if (!_isConnected || _session == null) {
        return PhantomResponse.error('Not connected to Phantom');
      }
      
      final params = {
        'session': _session,
        'message': base64Url.encode(utf8.encode(message)),
        'display': display ? 'utf8' : 'hex',
        'redirect_link': '${_appUrl}message-signed',
      };
      
      // Encode parameters as JSON then base64
      final jsonParams = jsonEncode(params);
      final encodedParams = base64Url.encode(utf8.encode(jsonParams));
      final url = '$_baseUrl/signMessage?params=$encodedParams';
      
      debugPrint('Phantom sign message URL: $url');
      
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
  
  /// Sign and send a transaction
  Future<PhantomResponse<String>> signAndSendTransaction({
    required String transaction,
    String? message,
  }) async {
    try {
      if (!_isConnected || _session == null) {
        return PhantomResponse.error('Not connected to Phantom');
      }
      
      final params = {
        'session': _session,
        'transaction': transaction,
        if (message != null) 'message': message,
        'redirect_link': '${_appUrl}sent',
      };
      
      final encodedParams = Uri.encodeQueryComponent(jsonEncode(params));
      final url = '$_baseUrl/signAndSendTransaction?params=$encodedParams';
      
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        return PhantomResponse.error('Failed to launch Phantom app');
      }
      
      return PhantomResponse.success('Transaction send request sent');
    } catch (e) {
      return PhantomResponse.error('Sign and send transaction failed: $e');
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
