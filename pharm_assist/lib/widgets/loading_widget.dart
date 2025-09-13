// lib/widgets/loading_widget.dart
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class LoadingWidget extends StatelessWidget {
  final String message;
  final double size;

  const LoadingWidget({
    Key? key,
    this.message = 'Loading...',
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}