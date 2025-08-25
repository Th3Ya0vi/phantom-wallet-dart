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
    
    debugPrint('Initializing DeeplinkHandler...');
    
    // Listen for incoming links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (err) {
        debugPrint('Deeplink error: $err');
      },
    );
    
    debugPrint('Link subscription set up');

    // Handle link when app is launched from a deeplink
    try {
      final initialLink = await _appLinks.getInitialAppLink();
      debugPrint('Initial link checked: ${initialLink?.toString() ?? "none"}');
      
      if (initialLink != null) {
        debugPrint('Processing initial link...');
        _handleIncomingLink(initialLink);
      }
      
      // Note: app_links package doesn't have getInitialLinks method
      // We'll just handle the single initial link provided by getInitialAppLink
    } catch (e) {
      debugPrint('Initial link error: $e');
    }
    
    debugPrint('DeeplinkHandler initialized successfully');
  }

  /// Handle incoming deeplink
  void _handleIncomingLink(Uri uri) {
    debugPrint('Received deeplink: $uri');
    debugPrint('Full URI components: scheme=${uri.scheme}, host=${uri.host}, path=${uri.path}, query=${uri.query}');
    debugPrint('Query parameters: ${uri.queryParameters}');
    
    if (_phantomService == null) {
      debugPrint('PhantomService not initialized');
      return;
    }

    try {
      final scheme = uri.scheme;
      final host = uri.host; // Use host instead of path for our deeplink structure
      final queryParams = uri.queryParameters;

      if (scheme != 'phantomdemo') {
        debugPrint('Unknown scheme: $scheme');
        return;
      }
      
      // Check for error response first - this can happen for any action
      if (queryParams.containsKey('errorCode') && queryParams.containsKey('errorMessage')) {
        debugPrint('Error from Phantom: Code ${queryParams['errorCode']}, Message: ${queryParams['errorMessage']}');
        // We could show an error dialog or handle it in another way
      }
      
      // Log all the incoming data for debugging
      debugPrint('Processing deeplink with host: $host and parameters: $queryParams');

      // Handle based on the host and path components
      if (host == 'wallet') {
        // New path structure with wallet/action format
        final path = uri.path.toLowerCase();
        
        debugPrint('Processing wallet path: $path');
        
        if (path == '/connect') {
          _handleConnectResponse(queryParams);
        } else if (path == '/disconnected') {
          _handleDisconnectResponse(queryParams);
        } else if (path == '/signed') {
          _handleSignTransactionResponse(queryParams);
        } else if (path == '/signed-all') {
          _handleSignAllTransactionsResponse(queryParams);
        } else if (path == '/message-signed') {
          _handleSignMessageResponse(queryParams);
        } else if (path == '/sent') {
          _handleSendTransactionResponse(queryParams);
        } else {
          debugPrint('Unknown wallet path: $path');
        }
      } else {
        // Fallback to legacy host-based routing
        switch (host) {
          case 'connect':
            _handleConnectResponse(queryParams);
            break;
          case 'connected':
            _handleConnectResponse(queryParams);
            break;
          case 'disconnected':
            _handleDisconnectResponse(queryParams);
            break;
          case 'signed':
            _handleSignTransactionResponse(queryParams);
            break;
          case 'signed-all':
            _handleSignAllTransactionsResponse(queryParams);
            break;
          case 'message-signed':
            _handleSignMessageResponse(queryParams);
            break;
          case 'sent':
            _handleSendTransactionResponse(queryParams);
            break;
          default:
            debugPrint('Unknown deeplink host: $host');
        }
      }
    } catch (e) {
      debugPrint('Error handling deeplink: $e');
    }
  }

  /// Handle connection response following the React Native demo
  void _handleConnectResponse(Map<String, String> queryParams) {
    try {
      debugPrint('Received connection response: $queryParams');
      
      // Check for error response first
      if (queryParams.containsKey('errorCode')) {
        final errorCode = queryParams['errorCode'];
        final errorMessage = queryParams['errorMessage'] ?? 'Connection failed';
        debugPrint('Connection error: $errorCode - $errorMessage');
        
        // Display error to user (we could add a callback or use a dialog here)
        if (errorCode == '-32603') {
          debugPrint('Received an "Unexpected error" from Phantom wallet.');
          debugPrint('This could be due to invalid parameters, encryption issues, or internal wallet problems.');
          debugPrint('Check that the Phantom wallet app is up to date and properly installed.');
        }
        return;
      }
      
      // Now use the handleConnectResponse method directly - passing the full queryParams
      // This matches the React Native approach more closely
      if (queryParams.containsKey('phantom_encryption_public_key') && 
          queryParams.containsKey('nonce') &&
          queryParams.containsKey('data')) {
          
        debugPrint('Found proper encrypted response from Phantom with all required fields');
        
        // Pass the full query parameters to the service
        _phantomService!.handleConnectResponse(queryParams)
          .then((response) {
            if (response.isSuccess) {
              debugPrint('Successfully processed connection: ${response.data}');
            } else {
              debugPrint('Failed to process connection: ${response.error}');
            }
          });
      } 
      // Fallback for direct public key in parameters (legacy support)
      else if (queryParams.containsKey('public_key')) {
        debugPrint('Found legacy public_key parameter (direct response)');
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
          
          _phantomService!.handleConnectResponseData(encodedData)
            .then((response) {
              if (response.isSuccess) {
                debugPrint('Successfully processed legacy connection: ${response.data}');
              } else {
                debugPrint('Failed to process legacy connection: ${response.error}');
              }
            });
        }
      } else {
        debugPrint('No recognized connection data in response: $queryParams');
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

  /// Handle sign transaction response (new architecture)
  void _handleSignTransactionResponse(Map<String, String> queryParams) {
    try {
      if (queryParams.containsKey('errorCode')) {
        final errorCode = queryParams['errorCode'];
        final errorMessage = queryParams['errorMessage'] ?? 'Transaction signing failed';
        debugPrint('Sign transaction error: $errorCode - $errorMessage');
        return;
      }

      // Check for encrypted response (new architecture)
      if (queryParams.containsKey('nonce') && queryParams.containsKey('data')) {
        debugPrint('📦 Received encrypted signed transaction from Phantom');
        
        // Decrypt and get signed transaction
        _phantomService!.handleSignedTransactionResponse(queryParams)
          .then((response) async {
            if (response.isSuccess) {
              final signedTransaction = response.data!;
              debugPrint('✅ Successfully decrypted signed transaction');
              
              // Now broadcast the signed transaction
              debugPrint('📡 Broadcasting transaction to Solana network...');
              final broadcastResponse = await _phantomService!.broadcastTransaction(
                signedTransaction: signedTransaction,
              );
              
              if (broadcastResponse.isSuccess) {
                final txSignature = broadcastResponse.data!;
                debugPrint('🎉 Transaction completed successfully!');
                debugPrint('🔗 Explorer: https://solscan.io/tx/$txSignature');
              } else {
                debugPrint('❌ Failed to broadcast: ${broadcastResponse.error}');
              }
            } else {
              debugPrint('❌ Failed to decrypt signed transaction: ${response.error}');
            }
          });
      }
      // Fallback for legacy signature response
      else if (queryParams.containsKey('signature')) {
        final signature = queryParams['signature'];
        debugPrint('Transaction signed (legacy): $signature');
      } else {
        debugPrint('⚠️  No recognized transaction data in response');
      }
    } catch (e) {
      debugPrint('Error handling sign transaction response: $e');
    }
  }

  /// Handle sign all transactions response (new architecture)
  void _handleSignAllTransactionsResponse(Map<String, String> queryParams) {
    try {
      if (queryParams.containsKey('errorCode')) {
        final errorCode = queryParams['errorCode'];
        final errorMessage = queryParams['errorMessage'] ?? 'Transaction signing failed';
        debugPrint('Sign all transactions error: $errorCode - $errorMessage');
        return;
      }

      // Check for encrypted response (new architecture)
      if (queryParams.containsKey('nonce') && queryParams.containsKey('data')) {
        debugPrint('📦 Received encrypted signed transactions from Phantom');
        
        // Decrypt and get signed transactions
        _phantomService!.handleSignedAllTransactionsResponse(queryParams)
          .then((response) async {
            if (response.isSuccess) {
              final signedTransactions = response.data!;
              debugPrint('✅ Successfully decrypted ${signedTransactions.length} signed transactions');
              
              // Broadcast each transaction
              final results = <String>[];
              for (int i = 0; i < signedTransactions.length; i++) {
                final signedTx = signedTransactions[i];
                debugPrint('📡 Broadcasting transaction ${i + 1}/${signedTransactions.length}...');
                
                final broadcastResponse = await _phantomService!.broadcastTransaction(
                  signedTransaction: signedTx,
                );
                
                if (broadcastResponse.isSuccess) {
                  final txSignature = broadcastResponse.data!;
                  results.add(txSignature);
                  debugPrint('✅ Transaction ${i + 1} completed: $txSignature');
                } else {
                  debugPrint('❌ Transaction ${i + 1} failed: ${broadcastResponse.error}');
                }
              }
              
              debugPrint('🎉 All transactions processed! Successful: ${results.length}/${signedTransactions.length}');
              for (final sig in results) {
                debugPrint('🔗 Explorer: https://solscan.io/tx/$sig');
              }
            } else {
              debugPrint('❌ Failed to decrypt signed transactions: ${response.error}');
            }
          });
      } else {
        debugPrint('⚠️  No recognized transaction data in response');
      }
    } catch (e) {
      debugPrint('Error handling sign all transactions response: $e');
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
