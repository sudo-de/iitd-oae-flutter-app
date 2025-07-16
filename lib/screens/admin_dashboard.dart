import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'user_list_screen.dart';
import 'admin_complaints_screen.dart';
import 'admin_analysis_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF0055FF),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 24),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _authService.signOut();
              if (mounted) {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
            child: Column(
              children: [
                // Professional Welcome Card
                _buildWelcomeCard(user, isTablet),
                SizedBox(height: isTablet ? 24 : 20),

                // Admin Features Grid
                _buildFeaturesGrid(isTablet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(UserModel user, bool isTablet) {
    return Card(
      elevation: 16,
      shadowColor: const Color(0xFF0055FF).withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0055FF), Color(0xFF0000FF)],
          ),
        ),
        padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
        child: Column(
          children: [
            // Professional Admin Avatar
            Container(
              width: isTablet ? 120 : 100,
              height: isTablet ? 120 : 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(isTablet ? 60 : 50),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                size: 50,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isTablet ? 24 : 20),

            // Welcome Text
            Text(
              'Welcome back,',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.name,
              style: TextStyle(
                fontSize: isTablet ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: isTablet ? 24 : 20),

            // Professional Role Badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 20,
                vertical: isTablet ? 12 : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Administrator',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid(bool isTablet) {
    final features = [
      {
        'title': 'User Management',
        'subtitle': 'Manage students & drivers',
        'icon': Icons.people_alt,
        'onTap': () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const UserListScreen())),
      },
      {
        'title': 'Complaints',
        'subtitle': 'Handle user complaints',
        'icon': Icons.report_problem,
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AdminComplaintsScreen(),
          ),
        ),
      },
      {
        'title': 'Ride Analysis',
        'subtitle': 'Analytics & reports',
        'icon': Icons.analytics,
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AdminAnalysisScreen()),
        ),
      },
      {
        'title': 'System Settings',
        'subtitle': 'Configure system',
        'icon': Icons.settings,
        'onTap': () => _showFeatureDialog(
          context,
          'System Settings',
          'Configure system settings and preferences',
        ),
      },
      {
        'title': 'Security',
        'subtitle': 'Firebase Auth info',
        'icon': Icons.security,
        'onTap': () => _showFirebaseAuthInfo(context),
      },
      {
        'title': 'Reports',
        'subtitle': 'Generate reports',
        'icon': Icons.assessment,
        'onTap': () => _showFeatureDialog(
          context,
          'Reports',
          'Generate detailed system reports',
        ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0055FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.dashboard,
                color: Color(0xFF0055FF),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Admin Tools',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0055FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 3 : 2,
            crossAxisSpacing: isTablet ? 20 : 16,
            mainAxisSpacing: isTablet ? 20 : 16,
            childAspectRatio: isTablet ? 1.1 : 1.0,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return _buildFeatureCard(
              context,
              feature['title'] as String,
              feature['subtitle'] as String,
              feature['icon'] as IconData,
              feature['onTap'] as VoidCallback,
              isTablet,
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    bool isTablet,
  ) {
    return Card(
      elevation: 12,
      shadowColor: const Color(0xFF0055FF).withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                width: isTablet ? 70 : 60,
                height: isTablet ? 70 : 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0055FF), Color(0xFF0000FF)],
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 35 : 30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0055FF).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: isTablet ? 32 : 28,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isTablet ? 16 : 12),

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0055FF),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isTablet ? 12 : 10,
                  color: const Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeatureDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0055FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF0055FF),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF0055FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFirebaseAuthInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0055FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.security,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Firebase Authentication',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF0055FF),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Important Information:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0055FF),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '• When you delete users from the app, they are only removed from the database\n'
                '• Users remain in Firebase Authentication and need manual deletion\n'
                '• This is required because Cloud Functions are not available on the free plan\n'
                '• You will receive instructions after each user deletion',
                style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0055FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF0055FF).withValues(alpha: 0.2),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Access:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0055FF),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Firebase Console > Authentication > Users',
                      style: TextStyle(color: Color(0xFF333333)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Got it',
                style: TextStyle(
                  color: Color(0xFF0055FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
