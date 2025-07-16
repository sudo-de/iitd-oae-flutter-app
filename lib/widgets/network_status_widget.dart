import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/network_utils.dart';

class NetworkStatusWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRetry;
  final bool showDetailedErrors;

  const NetworkStatusWidget({
    super.key,
    required this.child,
    this.onRetry,
    this.showDetailedErrors = false,
  });

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  bool _hasConnection = true;
  bool _hasFirestoreConnection = true;
  bool _isChecking = false;
  String? _lastError;
  Timer? _periodicCheckTimer;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    _periodicCheckTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicCheck() {
    // Check connection every 30 seconds
    _periodicCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnection(),
    );
  }

  Future<void> _checkConnection() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      // Check basic internet connectivity
      final hasInternet = await NetworkUtils.isConnected();

      // For now, assume Firestore is available if internet is available
      // The actual Firestore connectivity will be tested when the user tries to access data
      bool hasFirestore = hasInternet;

      if (mounted) {
        setState(() {
          _hasConnection = hasInternet;
          _hasFirestoreConnection = hasFirestore;
          _isChecking = false;
          _lastError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasConnection = false;
          _hasFirestoreConnection = false;
          _isChecking = false;
          _lastError = e.toString();
        });
      }
    }
  }

  void _showErrorDetails() {
    if (_lastError == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Error Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $_lastError'),
              const SizedBox(height: 16),
              const Text(
                'This may be due to:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Poor internet connection'),
              const Text('• SSL certificate issues'),
              const Text('• Firestore service disruption'),
              const Text('• Network firewall blocking'),
              const SizedBox(height: 16),
              const Text('Try:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('• Switching between WiFi and mobile data'),
              const Text('• Checking your internet connection'),
              const Text('• Restarting the app'),
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
              _checkConnection();
              widget.onRetry?.call();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return widget.child;
    }

    // Show error banner if there are connection issues
    if (!_hasConnection || !_hasFirestoreConnection) {
      return Stack(
        alignment: Alignment.topCenter,
        children: [
          widget.child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade600, Colors.red.shade700],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _hasConnection ? Icons.cloud_off : Icons.wifi_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _hasConnection
                              ? 'Database connection issue'
                              : 'No internet connection',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.showDetailedErrors && _lastError != null)
                          Text(
                            _lastError!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showDetailedErrors && _lastError != null)
                        IconButton(
                          onPressed: _showErrorDetails,
                          icon: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                        ),
                      TextButton(
                        onPressed: () {
                          _checkConnection();
                          widget.onRetry?.call();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 24),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return widget.child;
  }
}
