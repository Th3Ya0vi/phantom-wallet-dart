import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class StatusIndicator extends StatelessWidget {
  final bool isConnected;
  final String? publicKey;

  const StatusIndicator({
    super.key,
    required this.isConnected,
    this.publicKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected 
            ? AppColors.successLight 
            : AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected 
              ? AppColors.success 
              : AppColors.gray200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isConnected 
                      ? AppColors.success 
                      : AppColors.gray400,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isConnected ? 'Connected to Phantom' : 'Not Connected',
                  style: TextStyle(
                    color: AppColors.textDefault,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isConnected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
            ],
          ),
          
          if (isConnected && publicKey != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lavender.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lavender),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_box,
                        color: AppColors.brand,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Public Key',
                        style: TextStyle(
                          color: AppColors.textDefault,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _copyToClipboard(context, publicKey!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brand.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy,
                                color: AppColors.brand,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: TextStyle(
                                  color: AppColors.brand,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatPublicKey(publicKey!),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.textDefault,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatPublicKey(String publicKey) {
    if (publicKey.length <= 16) return publicKey;
    return '${publicKey.substring(0, 8)}...${publicKey.substring(publicKey.length - 8)}';
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 16,
            ),
            const SizedBox(width: 8),
            const Text('Public key copied to clipboard'),
          ],
        ),
        backgroundColor: AppColors.successLight,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

