import 'package:flutter/material.dart';
import '../utils/network_utils.dart';

class ConnectionErrorWidget extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;
  final String? customMessage;
  final bool showDetails;

  const ConnectionErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.customMessage,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final errorDetails = NetworkUtils.getErrorDetails(error);
    final isSSL = errorDetails['isSSL'] as bool;
    final isFirestore = errorDetails['isFirestore'] as bool;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSSL ? Icons.security : Icons.cloud_off,
              color: Colors.red.shade700,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),

          // Error Title
          Text(
            _getErrorTitle(isSSL, isFirestore),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Error Message
          Text(
            customMessage ?? NetworkUtils.getErrorMessage(error),
            style: TextStyle(fontSize: 14, color: Colors.red.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Error Details (if enabled)
          if (showDetails) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Error Details:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    error.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Troubleshooting Tips
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Troubleshooting Tips:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTroubleshootingTips(isSSL, isFirestore),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAdvancedTroubleshooting(context),
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Help'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getErrorTitle(bool isSSL, bool isFirestore) {
    if (isSSL) {
      return 'SSL Connection Error';
    } else if (isFirestore) {
      return 'Database Connection Issue';
    } else {
      return 'Network Error';
    }
  }

  Widget _buildTroubleshootingTips(bool isSSL, bool isFirestore) {
    final tips = <String>[];

    if (isSSL) {
      tips.addAll([
        '• Check your device\'s date and time settings',
        '• Try switching between WiFi and mobile data',
        '• Restart your device',
        '• Check if your network has firewall restrictions',
      ]);
    } else if (isFirestore) {
      tips.addAll([
        '• Check your internet connection',
        '• Try switching networks',
        '• Restart the app',
        '• Contact support if the issue persists',
      ]);
    } else {
      tips.addAll([
        '• Check your internet connection',
        '• Try switching between WiFi and mobile data',
        '• Restart the app',
        '• Check your device\'s network settings',
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tips
          .map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(tip, style: const TextStyle(fontSize: 11)),
            ),
          )
          .toList(),
    );
  }

  void _showAdvancedTroubleshooting(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('Advanced Troubleshooting'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'If the basic troubleshooting doesn\'t work, try these advanced steps:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildAdvancedStep(
                '1. Clear App Cache',
                'Go to your device settings > Apps > Find this app > Storage > Clear Cache',
                Icons.cleaning_services,
              ),
              const SizedBox(height: 12),
              _buildAdvancedStep(
                '2. Check Network Settings',
                'Ensure your device allows this app to access the internet',
                Icons.settings,
              ),
              const SizedBox(height: 12),
              _buildAdvancedStep(
                '3. Update App',
                'Make sure you have the latest version of the app installed',
                Icons.system_update,
              ),
              const SizedBox(height: 12),
              _buildAdvancedStep(
                '4. Contact Support',
                'If the issue persists, contact our support team with the error details',
                Icons.support_agent,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry?.call();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedStep(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
