import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'user_list_screen.dart';
import 'admin_complaints_screen.dart';
import 'admin_analysis_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import '../utils/color_utils.dart';

// Optimized animated card with better performance
class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final String semanticsLabel;

  const _AnimatedCard({
    required this.child,
    required this.onTap,
    required this.semanticsLabel,
  });

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails d) {
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _onTapUp(TapUpDetails d) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) =>
              Transform.scale(scale: _scaleAnim.value, child: child),
          child: RepaintBoundary(child: widget.child),
        ),
      ),
    );
  }
}

// Optimized animated indicator with better performance
class _AnimatedIndicator extends StatefulWidget {
  final Color color;

  const _AnimatedIndicator({required this.color});

  @override
  State<_AnimatedIndicator> createState() => _AnimatedIndicatorState();
}

class _AnimatedIndicatorState extends State<_AnimatedIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _widthAnim = Tween<double>(begin: 8, end: 20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _opacityAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        width: _widthAnim.value,
        height: 2.5,
        decoration: BoxDecoration(
          color: ColorUtils.withOpacity(widget.color, _opacityAnim.value),
          borderRadius: BorderRadius.circular(1.5),
        ),
      ),
    );
  }
}

// Shimmer loading effect for better UX
class _ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const _ShimmerLoading({required this.child, required this.isLoading});

  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _controller.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                Colors.transparent,
                Colors.white,
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _fadeController.forward();
      _slideController.forward();
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A2075)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF2A2075),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 24),
            onPressed: () => _showLogoutConfirmation(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ListView(
                padding: EdgeInsets.all(isTablet ? 20.0 : 12.0),
                children: [
                  _ShimmerLoading(
                    isLoading: _isLoading,
                    child: _buildWelcomeCard(user, isTablet),
                  ),
                  SizedBox(height: isTablet ? 24 : 16),
                  _ShimmerLoading(
                    isLoading: _isLoading,
                    child: _buildFeaturesGrid(isTablet),
                  ),
                  SizedBox(height: isTablet ? 24 : 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(UserModel user, bool isTablet) {
    return Card(
      elevation: 8,
      shadowColor: const Color(0xFF2A2075).withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2075), Color(0xFF2A2075)],
          ),
        ),
        padding: EdgeInsets.all(isTablet ? 28.0 : 20.0),
        child: Column(
          children: [
            // Professional Admin Avatar with animation
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Container(
                    width: isTablet ? 100 : 80,
                    height: isTablet ? 100 : 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(isTablet ? 50 : 40),
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
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: isTablet ? 45 : 35,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: isTablet ? 20 : 16),

            // Welcome Text with better typography
            Text(
              'Welcome back,',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              user.name,
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              user.email,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 20 : 16),

            // Professional Role Badge with improved styling
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                      fontSize: isTablet ? 14 : 12,
                      letterSpacing: 0.3,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with improved styling
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 12,
            vertical: isTablet ? 12 : 8,
          ),
          decoration: BoxDecoration(
            color: ColorUtils.withOpacity(const Color(0xFF2A2075), 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ColorUtils.withOpacity(const Color(0xFF2A2075), 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorUtils.withOpacity(const Color(0xFF2A2075), 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.dashboard,
                  color: Color(0xFF2A2075),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Tools',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A2075),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage your application efficiently',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: const Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isTablet ? 24 : 20),

        // Features grid with optimized performance
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 3 : 2,
            crossAxisSpacing: isTablet ? 16 : 12,
            mainAxisSpacing: isTablet ? 16 : 12,
            childAspectRatio: isTablet ? 1.8 : 1.7,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return _staggeredAnimatedCard(
              index: index,
              child: _buildFeatureCardByIndex(context, index, isTablet),
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
    const mainColor = Color(0xFF2A2075);

    return _AnimatedCard(
      onTap: onTap,
      semanticsLabel: title,
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white,
            border: Border.all(
              color: ColorUtils.withOpacity(mainColor, 0.07),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: ColorUtils.withOpacity(mainColor, 0.13),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(isTablet ? 14.0 : 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                width: isTablet ? 45 : 40,
                height: isTablet ? 45 : 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [mainColor, Color(0xFF4B3FE4)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ColorUtils.withOpacity(mainColor, 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: isTablet ? 24 : 20,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w700,
                  color: mainColor,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isTablet ? 9 : 8,
                  color: const Color(0xFF666666),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Animated indicator
              const SizedBox(height: 6),
              _AnimatedIndicator(color: mainColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCardByIndex(
    BuildContext context,
    int index,
    bool isTablet,
  ) {
    const features = [
      {
        'title': 'User Manager',
        'subtitle': 'Manage students & drivers',
        'icon': Icons.people_alt,
      },
      {
        'title': 'Complaint Management',
        'subtitle': 'Handle user complaints',
        'icon': Icons.report_problem,
      },
      {
        'title': 'Ride Analysis',
        'subtitle': 'Analytics & reports',
        'icon': Icons.analytics,
      },
      {
        'title': 'System Settings',
        'subtitle': 'Configure system',
        'icon': Icons.settings,
      },
      {
        'title': 'Security',
        'subtitle': 'Firebase Auth info',
        'icon': Icons.security,
      },
      {
        'title': 'Reports',
        'subtitle': 'Generate reports',
        'icon': Icons.assessment,
      },
    ];

    final feature = features[index];
    VoidCallback onTap;

    switch (index) {
      case 0:
        onTap = () => _navigateWithAnimation(const UserListScreen());
        break;
      case 1:
        onTap = () => _navigateWithAnimation(const AdminComplaintsScreen());
        break;
      case 2:
        onTap = () => _navigateWithAnimation(const AdminAnalysisScreen());
        break;
      case 3:
        onTap = () => _showFeatureDialog(
          context,
          'System Settings',
          'Configure system settings and preferences',
        );
        break;
      case 4:
        onTap = () => _showFirebaseAuthInfo(context);
        break;
      case 5:
        onTap = () => _showFeatureDialog(
          context,
          'Reports',
          'Generate detailed system reports',
        );
        break;
      default:
        onTap = () {};
    }

    return _buildFeatureCard(
      context,
      feature['title'] as String,
      feature['subtitle'] as String,
      feature['icon'] as IconData,
      onTap,
      isTablet,
    );
  }

  // Optimized staggered animation widget
  static Widget _staggeredAnimatedCard({
    required int index,
    required Widget child,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }

  // Navigation methods
  void _navigateWithAnimation(Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0055FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Confirm Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF0055FF),
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout? You will need to sign in again to access the admin dashboard.',
            style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final navigator = Navigator.of(context);
                await _authService.signOut();
                if (mounted) {
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2075),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFeatureDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0055FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF0055FF),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2075),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0055FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.security,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Firebase Authentication',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF0055FF),
                  ),
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
                  fontSize: 18,
                  color: Color(0xFF0055FF),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0055FF).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0055FF).withValues(alpha: 0.1),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• When you delete users from the app, they are only removed from the database\n'
                      '• Users remain in Firebase Authentication and need manual deletion\n'
                      '• This is required because Cloud Functions are not available on the free plan\n'
                      '• You will receive instructions after each user deletion',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF333333),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2075).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2A2075).withValues(alpha: 0.2),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Access:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A2075),
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Firebase Console > Authentication > Users',
                      style: TextStyle(color: Color(0xFF333333), fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2075),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }
}
