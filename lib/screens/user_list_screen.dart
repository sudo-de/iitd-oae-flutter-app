import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../utils/color_utils.dart';

// Shimmer loading widget for better UX
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

// Optimized user card widget
class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.student:
        return const Color(0xFF4299e1);
      case UserRole.driver:
        return const Color(0xFF48bb78);
      case UserRole.admin:
        return const Color(0xFFf56565);
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.student:
        return Icons.school;
      case UserRole.driver:
        return Icons.drive_eta;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  String _getRoleTitle(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.driver:
        return 'Driver';
      case UserRole.admin:
        return 'Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // User Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: ColorUtils.withOpacity(_getRoleColor(user.role), 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: ColorUtils.withOpacity(
                      _getRoleColor(user.role),
                      0.3,
                    ),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getRoleIcon(user.role),
                  color: _getRoleColor(user.role),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A2075),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ColorUtils.withOpacity(
                          _getRoleColor(user.role),
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ColorUtils.withOpacity(
                            _getRoleColor(user.role),
                            0.3,
                          ),
                        ),
                      ),
                      child: Text(
                        _getRoleTitle(user.role),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getRoleColor(user.role),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onEdit();
                    },
                    icon: const Icon(Icons.edit, color: Color(0xFF2A2075)),
                    tooltip: 'Edit User',
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      onDelete();
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete User',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen>
    with TickerProviderStateMixin {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  UserRole? _selectedRole;
  String _searchQuery = '';
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _loadUsers();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usersStream = _authService.getAllUsers();
      await for (final users in usersStream) {
        if (mounted) {
          setState(() {
            _users = users;
            _filterUsers();
            _isLoading = false;
          });
          _fadeController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _filterUsers() {
    _filteredUsers = _users.where((user) {
      // Apply role filter
      if (_selectedRole != null && user.role != _selectedRole) {
        return false;
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            (user.studentId?.toLowerCase().contains(query) ?? false) ||
            (user.phoneNumber?.toLowerCase().contains(query) ?? false);
      }

      return true;
    }).toList();
  }

  void _onRoleFilterChanged(UserRole? role) {
    setState(() {
      _selectedRole = role;
      _filterUsers();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterUsers();
    });
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('User Details - ${user.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Email', user.email),
                _buildDetailRow('Status', 'Active'),
                if (user.phoneNumber != null)
                  _buildDetailRow('Phone', user.phoneNumber!),
                if (user.role == UserRole.student) ...[
                  if (user.studentId != null)
                    _buildDetailRow('Entry Number', user.studentId!),
                  _buildDetailRow(
                    'Start Date',
                    user.startDate != null
                        ? _formatDate(user.startDate!)
                        : 'Not set',
                  ),
                  _buildDetailRow(
                    'End Date',
                    user.endDate != null
                        ? _formatDate(user.endDate!)
                        : 'Not set',
                  ),
                ],
                if (user.role == UserRole.driver) ...[
                  _buildDetailRow(
                    'Joined',
                    user.joinedDate != null
                        ? _formatDate(user.joinedDate!)
                        : 'Not set',
                  ),
                  if (user.driverLicense != null)
                    _buildDetailRow('Bank Details', user.driverLicense!),
                ],
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
                _showEditUserDialog(user);
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2d3748),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF4a5568)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddStudentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final entryNumberController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    String? selectedImagePath;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Student'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Photo Upload Section
                    GestureDetector(
                      onTap: () => _showImageSourceDialog(context, (path) {
                        setState(() {
                          selectedImagePath = path;
                        });
                      }),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: selectedImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.file(
                                  File(selectedImagePath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to add photo',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // Name Field
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Entry Number Field
                    TextField(
                      controller: entryNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Entry Number *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Start Date
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() {
                            startDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date *',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          startDate != null
                              ? _formatDate(startDate!)
                              : 'Select Date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // End Date
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              endDate ??
                              DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() {
                            endDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date *',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          endDate != null
                              ? _formatDate(endDate!)
                              : 'Select Date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate required fields
                    if (nameController.text.trim().isEmpty ||
                        entryNumberController.text.trim().isEmpty ||
                        emailController.text.trim().isEmpty ||
                        passwordController.text.isEmpty ||
                        phoneController.text.trim().isEmpty ||
                        startDate == null ||
                        endDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Validate password length
                    if (passwordController.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Password must be at least 6 characters long',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).pop();

                    try {
                      if (kDebugMode) {
                        debugPrint(
                          'Creating student with profile photo path: $selectedImagePath',
                        );
                      }
                      final user = await _authService.createUser(
                        email: emailController.text.trim(),
                        password: passwordController.text,
                        name: nameController.text.trim(),
                        role: UserRole.student,
                        phoneNumber: phoneController.text.trim(),
                        studentId: entryNumberController.text.trim(),
                        profilePhotoPath: selectedImagePath,
                      );

                      if (user != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Student added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                        _loadUsers();
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to add student'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error adding student: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Add Student'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddDriverDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final bankNameController = TextEditingController();
    final bankAccountController = TextEditingController();
    final ifscCodeController = TextEditingController();

    String? selectedImagePath;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Driver'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Photo Upload Section
                    GestureDetector(
                      onTap: () => _showImageSourceDialog(context, (path) {
                        setState(() {
                          selectedImagePath = path;
                        });
                      }),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: selectedImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.file(
                                  File(selectedImagePath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to add photo',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // Name Field
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bank Details Section
                    const Text(
                      'Bank Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Bank Name
                    TextField(
                      controller: bankNameController,
                      decoration: const InputDecoration(
                        labelText: 'Bank Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bank Account
                    TextField(
                      controller: bankAccountController,
                      decoration: const InputDecoration(
                        labelText: 'Bank Account *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // IFSC Code
                    TextField(
                      controller: ifscCodeController,
                      decoration: const InputDecoration(
                        labelText: 'IFSC Code *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate required fields
                    if (nameController.text.trim().isEmpty ||
                        emailController.text.trim().isEmpty ||
                        passwordController.text.isEmpty ||
                        phoneController.text.trim().isEmpty ||
                        bankNameController.text.trim().isEmpty ||
                        bankAccountController.text.trim().isEmpty ||
                        ifscCodeController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Validate password length
                    if (passwordController.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Password must be at least 6 characters long',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).pop();

                    try {
                      if (kDebugMode) {
                        debugPrint(
                          'Creating driver with profile photo path: $selectedImagePath',
                        );
                      }
                      final user = await _authService.createUser(
                        email: emailController.text.trim(),
                        password: passwordController.text,
                        name: nameController.text.trim(),
                        role: UserRole.driver,
                        phoneNumber: phoneController.text.trim(),
                        driverLicense:
                            '${bankNameController.text.trim()}-${bankAccountController.text.trim()}-${ifscCodeController.text.trim()}',
                        profilePhotoPath: selectedImagePath,
                      );

                      if (user != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Driver added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                        _loadUsers();
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to add driver'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error adding driver: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Add Driver'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddAdminDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Admin/Staff'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name Field
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Email Field
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone *',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate required fields
                if (nameController.text.trim().isEmpty ||
                    emailController.text.trim().isEmpty ||
                    passwordController.text.isEmpty ||
                    phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Validate password length
                if (passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password must be at least 6 characters long',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();

                try {
                  final user = await _authService.createUser(
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    name: nameController.text.trim(),
                    role: UserRole.admin,
                    phoneNumber: phoneController.text.trim(),
                  );

                  if (user != null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Admin/Staff added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    _loadUsers();
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to add admin'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding admin: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add Admin'),
            ),
          ],
        );
      },
    );
  }

  void _showImageSourceDialog(
    BuildContext context,
    Function(String) onImageSelected,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final image = await _picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (image != null) {
                    if (kDebugMode) {
                      debugPrint('Camera image selected: ${image.path}');
                    }
                    onImageSelected(image.path);
                  } else {
                    if (kDebugMode) {
                      debugPrint('No camera image selected');
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final image = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    if (kDebugMode) {
                      debugPrint('Gallery image selected: ${image.path}');
                    }
                    onImageSelected(image.path);
                  } else {
                    if (kDebugMode) {
                      debugPrint('No gallery image selected');
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditUserDialog(UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');
    final studentIdController = TextEditingController(
      text: user.studentId ?? '',
    );
    final bankNameController = TextEditingController();
    final bankAccountController = TextEditingController();
    final ifscCodeController = TextEditingController();

    String? selectedImagePath;
    DateTime? startDate;
    DateTime? endDate;
    DateTime? joinedDate;

    // Parse existing bank details for drivers
    if (user.role == UserRole.driver && user.driverLicense != null) {
      final parts = user.driverLicense!.split('-');
      if (parts.length >= 3) {
        bankNameController.text = parts[0];
        bankAccountController.text = parts[1];
        ifscCodeController.text = parts[2];
      }
    }

    // Pre-populate existing dates
    startDate = user.startDate;
    endDate = user.endDate;
    joinedDate = user.joinedDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit User - ${user.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Photo Upload Section (Optional)
                    GestureDetector(
                      onTap: () => _showImageSourceDialog(context, (path) {
                        setState(() {
                          selectedImagePath = path;
                        });
                      }),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: selectedImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: Image.file(
                                  File(selectedImagePath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : user.profilePhoto != null &&
                                  user.profilePhoto!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: CachedNetworkImage(
                                  imageUrl: user.profilePhoto!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Colors.grey,
                                      ),
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                size: 30,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to change photo (Optional)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                    const SizedBox(height: 16),

                    // Name Field
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Student-specific fields
                    if (user.role == UserRole.student) ...[
                      TextField(
                        controller: studentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Entry Number *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Start Date
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() {
                              startDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date *',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            startDate != null
                                ? _formatDate(startDate!)
                                : 'Select Date',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // End Date
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                endDate ??
                                DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() {
                              endDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date *',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            endDate != null
                                ? _formatDate(endDate!)
                                : 'Select Date',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Driver-specific fields
                    if (user.role == UserRole.driver) ...[
                      // Joined Date
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: joinedDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() {
                              joinedDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Joined Date *',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            joinedDate != null
                                ? _formatDate(joinedDate!)
                                : 'Select Date',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bank Details Section
                      const Text(
                        'Bank Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Bank Name
                      TextField(
                        controller: bankNameController,
                        decoration: const InputDecoration(
                          labelText: 'Bank Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bank Account
                      TextField(
                        controller: bankAccountController,
                        decoration: const InputDecoration(
                          labelText: 'Bank Account *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // IFSC Code
                      TextField(
                        controller: ifscCodeController,
                        decoration: const InputDecoration(
                          labelText: 'IFSC Code *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate required fields
                    if (nameController.text.trim().isEmpty ||
                        phoneController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Validate student-specific fields
                    if (user.role == UserRole.student) {
                      if (studentIdController.text.trim().isEmpty ||
                          startDate == null ||
                          endDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please fill in all required student fields',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }

                    // Validate driver-specific fields
                    if (user.role == UserRole.driver) {
                      if (joinedDate == null ||
                          bankNameController.text.trim().isEmpty ||
                          bankAccountController.text.trim().isEmpty ||
                          ifscCodeController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please fill in all required driver fields',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }

                    Navigator.of(context).pop();
                    try {
                      Map<String, dynamic> updateData = {
                        'name': nameController.text.trim(),
                        'phoneNumber': phoneController.text.trim(),
                      };

                      if (user.role == UserRole.student) {
                        updateData['studentId'] = studentIdController.text
                            .trim();
                        updateData['startDate'] =
                            startDate!.millisecondsSinceEpoch;
                        updateData['endDate'] = endDate!.millisecondsSinceEpoch;
                      }

                      if (user.role == UserRole.driver) {
                        updateData['joinedDate'] =
                            joinedDate!.millisecondsSinceEpoch;
                        updateData['driverLicense'] =
                            '${bankNameController.text.trim()}-${bankAccountController.text.trim()}-${ifscCodeController.text.trim()}';
                      }

                      if (kDebugMode) {
                        debugPrint(
                          'Updating user with profile photo path: $selectedImagePath',
                        );
                      }
                      await _authService.updateUser(
                        user.id,
                        updateData,
                        profilePhotoPath: selectedImagePath,
                      );

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      _loadUsers();
                      // Refresh current user data if it's the same user
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      if (authProvider.currentUser?.id == user.id) {
                        await authProvider.refreshCurrentUser();
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to update user: ${e.toString()}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _canDeleteAdmin(UserModel user) {
    if (user.role != UserRole.admin) return true;

    // Count total admins in the system
    final adminCount = _users.where((u) => u.role == UserRole.admin).length;

    // Can delete admin only if there is more than one admin
    return adminCount > 1;
  }

  void _showDeleteConfirmation(UserModel user) {
    // Check if trying to delete an admin
    if (user.role == UserRole.admin && !_canDeleteAdmin(user)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Cannot Delete Admin'),
            content: const Text(
              'You cannot delete the last admin user. At least one admin must remain in the system.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: Text(
            'Are you sure you want to delete ${user.name}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  // Show loading indicator
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text('Deleting user...'),
                        ],
                      ),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 2),
                    ),
                  );

                  await _authService.deleteUser(user.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.name} deleted from app database'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  if (!context.mounted) return;
                  _showFirebaseAuthDeletionInstructions(user);
                  _loadUsers();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete user: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showFirebaseAuthDeletionInstructions(UserModel user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Manual Step Required',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User "${user.name}" has been deleted from the app database.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'To complete the deletion, you need to manually delete the user from Firebase Authentication:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
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
                      'Steps:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Go to Firebase Console'),
                    const Text('2. Navigate to Authentication > Users'),
                    Text('3. Find user: ${user.email}'),
                    const Text('4. Click the three dots (⋮) next to the user'),
                    const Text('5. Select "Delete user"'),
                    const Text('6. Confirm deletion'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, color: Colors.blue.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Firebase Console: https://console.firebase.google.com/project/iitd-oae-b9687/authentication/users',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final url = Uri.parse(
                  'https://console.firebase.google.com/project/iitd-oae-b9687/authentication/users',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open Firebase Console'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open Firebase Console'),
            ),
          ],
        );
      },
    );
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Add New User',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A2075),
            ),
          ),
          content: const Text('Select the type of user you want to add:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showAddStudentDialog(context);
              },
              child: const Text('Student'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showAddDriverDialog(context);
              },
              child: const Text('Driver'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showAddAdminDialog(context);
              },
              child: const Text('Admin'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Manager',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2A2075),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 24),
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadUsers();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: ColorUtils.withOpacity(Colors.black, 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF2A2075),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: ColorUtils.withOpacity(
                        const Color(0xFF2A2075),
                        0.05,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Role Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(null, 'All'),
                        const SizedBox(width: 8),
                        _buildFilterChip(UserRole.student, 'Students'),
                        const SizedBox(width: 8),
                        _buildFilterChip(UserRole.driver, 'Drivers'),
                        const SizedBox(width: 8),
                        _buildFilterChip(UserRole.admin, 'Admins'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // User Count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.people,
                    color: ColorUtils.withOpacity(const Color(0xFF2A2075), 0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_filteredUsers.length} users found',
                    style: TextStyle(
                      color: ColorUtils.withOpacity(
                        const Color(0xFF2A2075),
                        0.7,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Users List
            Expanded(
              child: _ShimmerLoading(
                isLoading: _isLoading,
                child: _filteredUsers.isEmpty && !_isLoading
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return _UserCard(
                            user: user,
                            onTap: () => _showUserDetails(user),
                            onEdit: () => _showEditUserDialog(user),
                            onDelete: () => _showDeleteConfirmation(user),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddUserDialog(context);
        },
        backgroundColor: const Color(0xFF2A2075),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
        elevation: 4,
      ),
    );
  }

  Widget _buildFilterChip(UserRole? role, String label) {
    final isSelected = _selectedRole == role;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF2A2075),
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        HapticFeedback.lightImpact();
        _onRoleFilterChanged(selected ? role : null);
      },
      backgroundColor: Colors.transparent,
      selectedColor: const Color(0xFF2A2075),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected
            ? const Color(0xFF2A2075)
            : ColorUtils.withOpacity(const Color(0xFF2A2075), 0.3),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: ColorUtils.withOpacity(const Color(0xFF2A2075), 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: ColorUtils.withOpacity(const Color(0xFF2A2075), 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(fontSize: 14, color: const Color(0xFF666666)),
          ),
        ],
      ),
    );
  }
}
