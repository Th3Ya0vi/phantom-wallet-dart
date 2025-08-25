import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/phantom_service.dart';
import '../theme/app_colors.dart';
import '../widgets/wallet_card.dart';
import '../widgets/action_button.dart';
import '../widgets/status_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Pre-fill with exact React Native message for testing
  final _messageController = TextEditingController(
    text: 'To avoid digital dognappers, sign below to authenticate with CryptoCorgis.'
  );
  final _transactionController = TextEditingController();
  String? _lastResponse;

  @override
  void dispose() {
    _messageController.dispose();
    _transactionController.dispose();
    super.dispose();
  }

  void _showResponse(String title, String message, bool isError) {
    setState(() {
      _lastResponse = message;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(
            color: isError ? AppColors.error : AppColors.success,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectWallet() async {
    final phantomService = context.read<PhantomService>();
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Using direct phantom:// protocol...'))
    );
    
    // Use direct protocol approach
    final response = await phantomService.connect();

    // Clear the snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (response.isSuccess) {
      _showResponse('Direct Protocol Used', 'Using phantom:// protocol which should stay within the app without opening a browser.', false);
      
      // Add debugging info to last response
      setState(() {
        _lastResponse = "Connection request sent using phantom:// protocol directly.\n\n"
                      + "This should prevent the web browser from opening and keep the flow within the Phantom app.";
      });
    } else {
      _showResponse('Connection Error', 
        '${response.error!}\n\nMake sure Phantom app can handle phantom:// protocol links.', 
        true);
    }
  }

  Future<void> _disconnectWallet() async {
    final phantomService = context.read<PhantomService>();
    final response = await phantomService.disconnect();

    if (response.isSuccess) {
      _showResponse('Success', response.data!, false);
    } else {
      _showResponse('Error', response.error!, true);
    }
  }

  Future<void> _reconnectWallet() async {
    final phantomService = context.read<PhantomService>();
    
    // First disconnect
    await phantomService.disconnect();
    
    // Small delay to ensure clean disconnect
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Then reconnect
    await _connectWallet();
  }

  Future<void> _signMessage() async {
    if (_messageController.text.isEmpty) {
      _showResponse('Error', 'Please enter a message to sign', true);
      return;
    }

    final phantomService = context.read<PhantomService>();
    final response = await phantomService.signMessage(
      message: _messageController.text,
    );

    if (response.isSuccess) {
      _showResponse('Success', response.data!, false);
    } else {
      _showResponse('Error', response.error!, true);
    }
  }

  Future<void> _signTransaction() async {
    final phantomService = context.read<PhantomService>();
    
    // Use provided transaction or let service create dummy transaction for testing
    final transaction = _transactionController.text.isEmpty ? null : _transactionController.text;
    
    final response = await phantomService.signTransaction(
      transaction: transaction, // null = use dummy transaction for testing
    );

    if (response.isSuccess) {
      _showResponse('Success', response.data!, false);
    } else {
      _showResponse('Error', response.error!, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phantom Deeplink Demo (Unofficial)'),
        centerTitle: true,
      ),
      body: Consumer<PhantomService>(
        builder: (context, phantomService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status section
                WalletCard(
                  title: 'Wallet Status',
                  child: Column(
                    children: [
                      StatusIndicator(
                        isConnected: phantomService.isConnected,
                        publicKey: phantomService.publicKey,
                      ),
                      const SizedBox(height: 16),
                      if (!phantomService.isConnected)
                        ActionButton(
                          text: 'Connect Phantom Wallet',
                          onPressed: _connectWallet,
                          icon: Icons.account_balance_wallet,
                          variant: ActionButtonVariant.primary,
                        )
                      else ...[
                        Row(
                          children: [
                            Expanded(
                              child: ActionButton(
                                text: 'Reconnect',
                                onPressed: _reconnectWallet,
                                icon: Icons.refresh,
                                variant: ActionButtonVariant.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ActionButton(
                                text: 'Disconnect',
                                onPressed: _disconnectWallet,
                                icon: Icons.logout,
                                variant: ActionButtonVariant.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: phantomService.shouldReconnect 
                              ? AppColors.orange.withValues(alpha: 0.3)
                              : AppColors.yellow.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            phantomService.shouldReconnect
                              ? '⚠️ Session may be expired - Reconnect recommended!'
                              : '💡 Try "Reconnect" if signing fails - gets fresh session',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Message signing section
                WalletCard(
                  title: 'Sign Message',
                  child: Column(
                    children: [
                      TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Message to sign',
                          hintText: 'Try: To avoid digital dognappers, sign below to authenticate with CryptoCorgis.',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                                      ActionButton(
                  text: 'Sign Message (React Native Format)',
                  onPressed: phantomService.isConnected ? _signMessage : null,
                  icon: Icons.edit_note,
                  variant: ActionButtonVariant.primary,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '✅ Now using EXACT React Native payload format',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Transaction signing section (New Architecture)
                WalletCard(
                  title: 'Sign & Broadcast Transaction',
                  child: Column(
                    children: [
                      TextField(
                        controller: _transactionController,
                        decoration: const InputDecoration(
                          labelText: 'Transaction data (optional)',
                          hintText: 'Leave empty to use dummy transaction for testing...',
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lavender.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '🔄 New Flow: Phantom signs → App broadcasts',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ActionButton(
                        text: 'Sign & Broadcast',
                        onPressed: phantomService.isConnected ? _signTransaction : null,
                        icon: Icons.receipt_long,
                        variant: ActionButtonVariant.primary,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Last response section
                if (_lastResponse != null)
                  WalletCard(
                    title: 'Last Response',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _lastResponse!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Instructions
                WalletCard(
                  title: 'Instructions',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInstruction(
                        '1.',
                        'Tap "Connect Phantom Wallet" to initiate connection',
                      ),
                      _buildInstruction(
                        '2.',
                        'Phantom app will open for approval',
                      ),
                      _buildInstruction(
                        '3.',
                        'After approval, return to this app',
                      ),
                      _buildInstruction(
                        '4.',
                        'Use "Sign Message" or "Sign & Broadcast Transaction" features',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.vanilla.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.yellow),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Make sure you have Phantom wallet installed on your device. This is an unofficial integration example.',
                                style: TextStyle(
                                  color: AppColors.textDefault,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textDefault,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

