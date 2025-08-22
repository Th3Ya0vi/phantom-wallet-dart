import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'phantom_service.dart';
import '../models/phantom_models.dart';

class DeeplinkHandler {
  static final DeeplinkHandler _instance = DeeplinkHandler._internal();
  factory DeeplinkHandler() => _instance;
  DeeplinkHandler._internal();

  final AppLinks _appLinks = AppLinks();
  late StreamSubscription<Uri> _linkSubscription;
  PhantomService? _phantomService;

  /// Initialize deeplink handling
  Future<void> initialize(PhantomService phantomService) async {
    _phantomService = phantomService;
    
    // Listen for incoming links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (err) {
        debugPrint('Deeplink error: $err');
      },
    );

    // Handle link when app is launched from a deeplink
    try {
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        _handleIncomingLink(initialLink);
      }
    } catch (e) {
      debugPrint('Initial link error: $e');
    }
  }

  /// Handle incoming deeplink
  void _handleIncomingLink(Uri uri) {
    debugPrint('Received deeplink: $uri');
    
    if (_phantomService == null) {
      debugPrint('PhantomService not initialized');
      return;
    }

    try {
      final scheme = uri.scheme;
      final path = uri.path;
      final queryParams = uri.queryParameters;

      if (scheme != 'phantomdemo') {
        debugPrint('Unknown scheme: $scheme');
        return;
      }

      switch (path) {
        case '/connected':
          _handleConnectResponse(queryParams);
          break;
        case '/disconnected':
          _handleDisconnectResponse(queryParams);
          break;
        case '/signed':
          _handleSignTransactionResponse(queryParams);
          break;
        case '/message-signed':
          _handleSignMessageResponse(queryParams);
          break;
        case '/sent':
          _handleSendTransactionResponse(queryParams);
          break;
        default:
          debugPrint('Unknown deeplink path: $path');
      }
    } catch (e) {
      debugPrint('Error handling deeplink: $e');
    }
  }

  /// Handle connection response
  void _handleConnectResponse(Map<String, String> queryParams) {
    try {
      if (queryParams.containsKey('errorCode')) {
        final errorCode = queryParams['errorCode'];
        final errorMessage = queryParams['errorMessage'] ?? 'Connection failed';
        debugPrint('Connection error: $errorCode - $errorMessage');
        return;
      }

      if (queryParams.containsKey('phantom_encryption_public_key') &&
          queryParams.containsKey('nonce')) {
        // Handle encrypted response
        final encryptionKey = queryParams['phantom_encryption_public_key'];
        final nonce = queryParams['nonce'];
        final data = queryParams['data'];

        if (data != null) {
          _phantomService!.handleConnectResponse(data);
        }
      } else if (queryParams.containsKey('public_key')) {
        // Handle direct response
        final publicKey = queryParams['public_key'];
        final session = queryParams['session'] ?? '';
        
        if (publicKey != null) {
          final responseData = {
            'public_key': publicKey,
            'session': session,
          };
          
          final encodedData = base64Url.encode(
            utf8.encode(jsonEncode(responseData)),
          );
          
          _phantomService!.handleConnectResponse(encodedData);
        }
      }
    } catch (e) {
      debugPrint('Error handling connect response: $e');
    }
  }

  /// Handle disconnect response
  void _handleDisconnectResponse(Map<String, String> queryParams) {
    try {
      if (queryParams.containsKey('errorCode')) {
        final errorCode = queryParams['errorCode'];
        final errorMessage = queryParams['errorMessage'] ?? 'Disconnect failed';
        debugPrint('Disconnect error: $errorCode - $errorMessage');
        return;
      }

      debugPrint('Wallet disconnected successfully');
    } catch (e) {
      debugPrint('Error handling disconnect response: $e');
    }
  }

  /// Handle sign transaction response
  void _handleSignTransactionResponse(Map<String, String> queryParams) {
    try {
      if (queryParams.containsKey('errorCode')) {
        final errorCode = queryParams['errorCode'];
        final errorMessage = queryParams['errorMessage'] ?? 'Transaction signing failed';
        debugPrint('Sign transaction error: $errorCode - $errorMessage');
        return;
      }

      final signature = queryParams['signature'];
      if (signature != null) {
        debugPrint('Transaction signed: $signature');
        // You could emit an event or call a callback here
      }
    } catch (e) {
      debugPrint('Error handling sign transaction response: $e');
    }
  }

  /// Handle sign message response
  void _handleSignMessageResponse(Map<String, String> queryParams) {
    try {
      if (queryParams.containsKey('errorCode')) {
        final errorCode = queryParams['errorCode'];
        final errorMessage = queryParams['errorMessage'] ?? 'Message signing failed';
        debugPrint('Sign message error: $errorCode - $errorMessage');
        return;
      }

      final signature = queryParams['signature'];
      if (signature != null) {
        debugPrint('Message signed: $signature');
        // You could emit an event or call a callback here
      }
    } catch (e) {
      debugPrint('Error handling sign message response: $e');
    }
  }

  /// Handle send transaction response
  void _handleSendTransactionResponse(Map<String, String> queryParams) {
    try {
      if (queryParams.containsKey('errorCode')) {
        final errorCode = queryParams['errorCode'];
        final errorMessage = queryParams['errorMessage'] ?? 'Transaction send failed';
        debugPrint('Send transaction error: $errorCode - $errorMessage');
        return;
      }

      final signature = queryParams['signature'];
      if (signature != null) {
        debugPrint('Transaction sent: $signature');
        // You could emit an event or call a callback here
      }
    } catch (e) {
      debugPrint('Error handling send transaction response: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription.cancel();
  }
}
