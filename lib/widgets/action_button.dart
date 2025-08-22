import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ActionButtonVariant {
  primary,
  secondary,
  ghost,
  danger,
}

class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ActionButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;

  const ActionButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.variant = ActionButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: _getButtonStyle(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getTextColor(isDisabled),
                    ),
                  ),
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 18,
                  color: _getTextColor(isDisabled),
                ),
              if ((isLoading || icon != null) && text.isNotEmpty)
                const SizedBox(width: 8),
              if (text.isNotEmpty)
                Text(
                  text,
                  style: TextStyle(
                    color: _getTextColor(isDisabled),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,

                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _getButtonStyle() {
    switch (variant) {
      case ActionButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.gray200,
          disabledForegroundColor: AppColors.gray400,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      
      case ActionButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.bgSurface,
          foregroundColor: AppColors.textDefault,
          disabledBackgroundColor: AppColors.gray100,
          disabledForegroundColor: AppColors.gray400,
          elevation: 0,
          side: BorderSide(color: AppColors.gray200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      
      case ActionButtonVariant.ghost:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textDefault,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: AppColors.gray400,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      
      case ActionButtonVariant.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.gray200,
          disabledForegroundColor: AppColors.gray400,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
    }
  }

  Color _getTextColor(bool isDisabled) {
    if (isDisabled) {
      return AppColors.gray400;
    }
    
    switch (variant) {
      case ActionButtonVariant.primary:
      case ActionButtonVariant.danger:
        return Colors.white;
      case ActionButtonVariant.secondary:
      case ActionButtonVariant.ghost:
        return AppColors.textDefault;
    }
  }
}
