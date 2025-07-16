import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/auth_service.dart';

import '../providers/auth_provider.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  UserRole? _selectedRole;
  String _searchQuery = '';
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUsers();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Manager'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 4,
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
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFf7fafc),
                  ),
                ),
                const SizedBox(height: 12),

                // User Type Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddStudentDialog(context),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Student'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4299e1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddDriverDialog(context),
                        icon: const Icon(Icons.drive_eta),
                        label: const Text('Add Driver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF48bb78),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddAdminDialog(context),
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Add Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFf56565),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedRole == null,
                        onSelected: (selected) {
                          if (selected) _onRoleFilterChanged(null);
                        },
                        selectedColor: const Color(
                          0xFF667eea,
                        ).withValues(alpha: 0.2),
                        checkmarkColor: const Color(0xFF667eea),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Students'),
                        selected: _selectedRole == UserRole.student,
                        onSelected: (selected) {
                          if (selected) {
                            _onRoleFilterChanged(UserRole.student);
                          }
                        },
                        selectedColor: const Color(
                          0xFF667eea,
                        ).withValues(alpha: 0.2),
                        checkmarkColor: const Color(0xFF667eea),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Drivers'),
                        selected: _selectedRole == UserRole.driver,
                        onSelected: (selected) {
                          if (selected) {
                            _onRoleFilterChanged(UserRole.driver);
                          }
                        },
                        selectedColor: const Color(
                          0xFF667eea,
                        ).withValues(alpha: 0.2),
                        checkmarkColor: const Color(0xFF667eea),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Admins'),
                        selected: _selectedRole == UserRole.admin,
                        onSelected: (selected) {
                          if (selected) {
                            _onRoleFilterChanged(UserRole.admin);
                          }
                        },
                        selectedColor: const Color(
                          0xFF667eea,
                        ).withValues(alpha: 0.2),
                        checkmarkColor: const Color(0xFF667eea),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Total Users: ${_filteredUsers.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d3748),
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        if (kDebugMode) {
                          debugPrint(
                            'Building user list item for: ${user.name}',
                          );
                          debugPrint('Profile photo: ${user.profilePhoto}');
                        }
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: _getRoleColor(user.role),
                              child:
                                  user.profilePhoto != null &&
                                      user.profilePhoto!.isNotEmpty
                                  ? ClipOval(
                                      child: _buildUserProfileImage(
                                        user.profilePhoto!,
                                        user.role,
                                      ),
                                    )
                                  : Icon(
                                      _getRoleIcon(user.role),
                                      color: Colors.white,
                                    ),
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.email),
                                Row(
                                  children: [
                                    Text(
                                      'Role: ${_getRoleTitle(user.role)}',
                                      style: TextStyle(
                                        color: _getRoleColor(user.role),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Active',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (user.phoneNumber != null)
                                  Text('Phone: ${user.phoneNumber}'),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'view':
                                    _showUserDetails(user);
                                    break;
                                  case 'edit':
                                    _showEditUserDialog(user);
                                    break;
                                  case 'delete':
                                    _showDeleteConfirmation(user);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Text('View Details'),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                if (user.role != UserRole.admin ||
                                    _canDeleteAdmin(user))
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileImage(String imageData, UserRole role) {
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
          width: 50,
          height: 50,
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              debugPrint('Error loading base64 image in user list: $error');
            }
            return Icon(_getRoleIcon(role), color: Colors.white);
          },
        );
      } else {
        // Handle URL image
        return CachedNetworkImage(
          imageUrl: imageData,
          fit: BoxFit.cover,
          width: 50,
          height: 50,
          placeholder: (context, url) {
            if (kDebugMode) {
              debugPrint('User list loading placeholder for: $url');
            }
            return Icon(_getRoleIcon(role), color: Colors.white);
          },
          errorWidget: (context, url, error) {
            if (kDebugMode) {
              debugPrint('User list error loading image: $url, error: $error');
            }
            return Icon(_getRoleIcon(role), color: Colors.white);
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error building user profile image: $e');
      }
      return Icon(_getRoleIcon(role), color: Colors.white);
    }
  }
}
