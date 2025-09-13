// lib/widgets/sync_button.dart
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class SyncButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String? customText;

  const SyncButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
    this.customText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Icon(Icons.sync),
        label: Text(customText ?? (isLoading ? 'Syncing...' : 'Sync Data')),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          backgroundColor: isLoading ? Colors.grey : AppTheme.primaryColor,
        ),
      ),
    );
  }
}