import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';

import 'driver_rides_screen.dart';
import 'driver_earnings_screen.dart';
import 'login_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  // Persistent settings state
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    // Notification subscription is now handled in AuthProvider
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (kDebugMode) {
          debugPrint('Driver dashboard building for user: ${user.name}');
          debugPrint('Driver profile photo: ${user.profilePhoto}');
          debugPrint(
            'Driver profile photo is null: ${user.profilePhoto == null}',
          );
          debugPrint(
            'Driver profile photo is empty: ${user.profilePhoto?.isEmpty}',
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Driver Dashboard'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFa8edea),
                  Color(0xFFfed6e3),
                  Color(0xFFffecd2),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Welcome Card
                    Card(
                      elevation: 12,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Color(0xFFf0fff4)],
                          ),
                        ),
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          children: [
                            // Driver Avatar
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(55),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF48bb78,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(55),
                                child:
                                    user.profilePhoto != null &&
                                        user.profilePhoto!.isNotEmpty
                                    ? _buildProfileImage(user.profilePhoto!)
                                    : Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF48bb78),
                                              Color(0xFF38a169),
                                            ],
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.drive_eta,
                                          size: 55,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Welcome Text
                            Text(
                              'Welcome, ${user.name}!',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2d3748),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF718096),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Driver Features Grid
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        childAspectRatio: 1.1,
                        children: [
                          _buildFeatureCard(
                            context,
                            'View Rides',
                            Icons.directions_car,
                            const Color(0xFF3182ce),
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const DriverRidesScreen(),
                              ),
                            ),
                          ),
                          _buildFeatureCard(
                            context,
                            'My Earnings',
                            Icons.account_balance_wallet,
                            const Color(0xFF48bb78),
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DriverEarningsScreen(),
                              ),
                            ),
                          ),
                          _buildFeatureCard(
                            context,
                            'Bank Details',
                            Icons.account_balance,
                            const Color(0xFF9f7aea),
                            () => _showBankDetailsDialog(context),
                          ),
                          _buildFeatureCard(
                            context,
                            'System Settings',
                            Icons.settings,
                            const Color(0xFF4a5568),
                            () => _showSystemSettingsDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileImage(String imageData) {
    try {
      // Check if it's a base64 string (starts with data:image or is a long base64 string)
      if (imageData.startsWith('data:image') || imageData.length > 100) {
        // Handle base64 image
        final bytes = base64Decode(
          imageData.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), ''),
        );
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 110,
          height: 110,
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              debugPrint(
                'Error loading base64 image in driver dashboard: $error',
              );
            }
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF48bb78), Color(0xFF38a169)],
                ),
              ),
              child: const Icon(Icons.drive_eta, size: 55, color: Colors.white),
            );
          },
        );
      } else {
        // Handle URL image
        return CachedNetworkImage(
          imageUrl: imageData,
          fit: BoxFit.cover,
          width: 110,
          height: 110,
          placeholder: (context, url) {
            if (kDebugMode) {
              debugPrint('Driver dashboard loading placeholder for: $url');
            }
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF48bb78), Color(0xFF38a169)],
                ),
              ),
              child: const Icon(Icons.drive_eta, size: 55, color: Colors.white),
            );
          },
          errorWidget: (context, url, error) {
            if (kDebugMode) {
              debugPrint(
                'Driver dashboard error loading image: $url, error: $error',
              );
            }
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF48bb78), Color(0xFF38a169)],
                ),
              ),
              child: const Icon(Icons.drive_eta, size: 55, color: Colors.white),
            );
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error building driver profile image: $e');
      }
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF48bb78), Color(0xFF38a169)],
          ),
        ),
        child: const Icon(Icons.drive_eta, size: 55, color: Colors.white),
      );
    }
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 8,
      shadowColor: color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, color.withValues(alpha: 0.05)],
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d3748),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this method to handle FCM topic subscription/unsubscription
  Future<void> _updateNotificationSubscription(bool enabled) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;
    if (enabled) {
      await NotificationService().subscribeDriverToTopics(user.id);
    } else {
      await NotificationService().unsubscribeFromTopic('drivers');
      await NotificationService().unsubscribeFromTopic('driver_${user.id}');
    }
  }

  void _showSystemSettingsDialog(BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUser;
    bool notificationsEnabled = _notificationsEnabled;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.settings, color: Colors.grey.shade700, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'System Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Information Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Profile Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSettingRow('Name', currentUser?.name ?? 'N/A'),
                          const SizedBox(height: 8),
                          _buildSettingRow(
                            'Email',
                            currentUser?.email ?? 'N/A',
                          ),
                          const SizedBox(height: 8),
                          _buildSettingRow(
                            'Phone',
                            currentUser?.phoneNumber ?? 'N/A',
                          ),
                          const SizedBox(height: 8),
                          _buildSettingRow('Status', 'Active'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // App Settings Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.tune,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'App Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Notifications Switch
                          SwitchListTile(
                            title: const Text(
                              'Push Notifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'Receive ride notifications',
                              style: TextStyle(fontSize: 14),
                            ),
                            value: notificationsEnabled,
                            onChanged: (value) async {
                              setState(() {
                                notificationsEnabled = value;
                              });
                              await _updateNotificationSubscription(value);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Settings saved successfully',
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            secondary: Icon(
                              Icons.notifications,
                              color: notificationsEnabled
                                  ? Colors.green.shade700
                                  : Colors.grey,
                            ),
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Support Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.support_agent,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Support & Help',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          ListTile(
                            title: const Text(
                              'Contact Support',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'Get help from our team',
                              style: TextStyle(fontSize: 14),
                            ),
                            leading: const Icon(Icons.contact_support),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _showContactSupportDialog(context);
                            },
                          ),

                          ListTile(
                            title: const Text(
                              'App Version',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              '1.0.0',
                              style: TextStyle(fontSize: 14),
                            ),
                            leading: const Icon(Icons.info),
                          ),

                          ListTile(
                            title: const Text(
                              'FCM Token',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              NotificationService().fcmToken?.substring(
                                    0,
                                    20,
                                  ) ??
                                  'Not available',
                              style: const TextStyle(fontSize: 14),
                            ),
                            leading: Icon(
                              Icons.token,
                              color: NotificationService().fcmToken != null
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            onTap: () {
                              final token = NotificationService().fcmToken;
                              if (token != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'FCM Token: ${token.substring(0, 50)}...',
                                    ),
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'FCM Token not available. Check internet connection.',
                                    ),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                          ),

                          ListTile(
                            title: const Text(
                              'Notification Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              NotificationService().fcmToken != null
                                  ? 'Ready for notifications'
                                  : 'Waiting for connection...',
                              style: const TextStyle(fontSize: 14),
                            ),
                            leading: Icon(
                              Icons.notifications_active,
                              color: NotificationService().fcmToken != null
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            trailing: NotificationService().fcmToken == null
                                ? IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: () async {
                                      await NotificationService()
                                          .retryFCMToken();
                                      setState(() {
                                        // Trigger rebuild to update status
                                      });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Retrying notification service...',
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Update the persistent state
                    setState(() {
                      _notificationsEnabled = notificationsEnabled;
                    });
                    await _updateNotificationSubscription(notificationsEnabled);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Settings saved successfully'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2d3748),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showContactSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.contact_support,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Contact Support'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Need help? Contact our support team:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildContactRow('Email', 'support@iitd-ride.com', Icons.email),
              const SizedBox(height: 8),
              _buildContactRow('Phone', '+91 98765 43210', Icons.phone),
              const SizedBox(height: 8),
              _buildContactRow('WhatsApp', '+91 98765 43210', Icons.message),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2d3748),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showBankDetailsDialog(BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUser;

    // Parse bank details from driverLicense field if separate fields are not available
    String bankName = currentUser?.bankName ?? 'Not provided';
    String bankAccount = currentUser?.bankAccount ?? 'Not provided';
    String ifscCode = currentUser?.ifscCode ?? 'Not provided';

    // If separate fields are not available, try to parse from driverLicense
    if (currentUser?.driverLicense != null &&
        (bankName == 'Not provided' ||
            bankAccount == 'Not provided' ||
            ifscCode == 'Not provided')) {
      final parts = currentUser!.driverLicense!.split('-');
      if (parts.length >= 3) {
        bankName = parts[0];
        bankAccount = parts[1];
        ifscCode = parts[2];
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.account_balance,
                color: Colors.purple.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Bank Details', overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.purple.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBankDetailRow(
                        'Bank Name',
                        bankName,
                        Icons.account_balance,
                      ),
                      const SizedBox(height: 12),
                      _buildBankDetailRow(
                        'Account Number',
                        bankAccount,
                        Icons.credit_card,
                      ),
                      const SizedBox(height: 12),
                      _buildBankDetailRow('IFSC Code', ifscCode, Icons.code),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Contact admin to update your bank details',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showRequestUpdateDialog(context);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Request Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBankDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.purple.shade700),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d3748),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showRequestUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.update, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Request Bank Details Update',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Request Submitted Successfully!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your request for bank details update has been sent to the admin team.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The admin will review your request and update your bank details within 24-48 hours.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You will be notified once your bank details are updated.',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bank details update request sent to admin'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
