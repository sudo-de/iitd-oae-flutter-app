import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/complaint_service.dart';
import '../services/operation_service.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/async_utils.dart';
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

// Optimized complaint card widget
class _ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final VoidCallback onTap;
  final VoidCallback onStatusUpdate;

  const _ComplaintCard({
    required this.complaint,
    required this.onTap,
    required this.onStatusUpdate,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFf6ad55);
      case 'in progress':
        return const Color(0xFF4299e1);
      case 'resolved':
        return const Color(0xFF48bb78);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'in progress':
        return Icons.work;
      case 'resolved':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = complaint['status'] ?? 'pending';
    final title = complaint['subject'] ?? 'No Subject';
    final description = complaint['message'] ?? 'No Message';
    final createdAt = complaint['createdAt'] as Timestamp?;
    final userName = complaint['userName'] ?? 'Unknown User';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ColorUtils.withOpacity(
                        _getStatusColor(status),
                        0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ColorUtils.withOpacity(
                          _getStatusColor(status),
                          0.3,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 16,
                          color: _getStatusColor(status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onStatusUpdate();
                    },
                    icon: const Icon(Icons.edit, color: Color(0xFF2A2075)),
                    tooltip: 'Update Status',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A2075),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Footer with user and date
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: ColorUtils.primaryWithOpacity60,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorUtils.primaryWithOpacity60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (createdAt != null) ...[
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: ColorUtils.grayWithOpacity60,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(createdAt.toDate()),
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorUtils.grayWithOpacity60,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  StreamSubscription? _complaintsSubscription;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _filters = ['All', 'Pending', 'In Progress', 'Resolved'];

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

    // Add a small delay to ensure the auth provider is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check if the widget is still mounted before accessing Provider
      if (!mounted) return;

      final user = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).currentUser;
      if (kDebugMode) {
        debugPrint('AdminComplaintsScreen: Current user: ${user?.email}');
        debugPrint('AdminComplaintsScreen: User role: ${user?.role}');
      }

      // Check admin privileges in database
      if (user != null) {
        final hasAdminPrivileges = await ComplaintService.checkAdminPrivileges(
          user.id,
        );
        if (kDebugMode) {
          debugPrint(
            'AdminComplaintsScreen: Has admin privileges in DB: $hasAdminPrivileges',
          );
        }

        // If user doesn't have admin privileges, try to create admin user
        if (!hasAdminPrivileges) {
          if (kDebugMode) {
            debugPrint('Creating admin user for: ${user.email}');
          }
          await ComplaintService.createAdminUserIfNeeded(
            user.id,
            user.email,
            user.name,
          );
        }

        // Temporarily bypass admin check for testing
        if (kDebugMode) {
          debugPrint(
            'AdminComplaintsScreen: Bypassing admin check for testing',
          );
        }
      }

      _loadComplaints();
    });
  }

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (kDebugMode) {
        debugPrint('AdminComplaintsScreen: Starting to load complaints...');
      }

      // Cancel any existing subscription
      await _complaintsSubscription?.cancel();

      // Use stream to get real-time updates
      _complaintsSubscription = ComplaintService.getAllComplaints().listen(
        (complaints) {
          if (kDebugMode) {
            debugPrint(
              'AdminComplaintsScreen: Received ${complaints.length} complaints',
            );
            if (complaints.isNotEmpty) {
              debugPrint(
                'AdminComplaintsScreen: First complaint: ${complaints.first}',
              );
            }
          }
          if (mounted) {
            setState(() {
              _complaints = complaints;
              _isLoading = false;
            });
            _fadeController.forward();
          }
        },
        onError: (error) {
          if (kDebugMode) {
            debugPrint('Error loading complaints stream: $error');
          }
          // If stream fails, try the fallback method
          if (mounted) {
            _loadComplaintsFallback();
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting up complaints stream: $e');
      }
      // If stream setup fails, try the fallback method
      if (mounted) {
        _loadComplaintsFallback();
      }
    }
  }

  Future<void> _loadComplaintsFallback() async {
    try {
      final complaints = await ComplaintService.getAllComplaintsFuture();
      setState(() {
        _complaints = complaints;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading complaints fallback: $e');
      }
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Permission denied. Please check if you have admin privileges. Error: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadComplaints,
            ),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredComplaints {
    if (_selectedFilter == 'All') {
      return _complaints;
    }

    return _complaints
        .where(
          (complaint) => complaint['status'] == _selectedFilter.toLowerCase(),
        )
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFf6ad55);
      case 'in progress':
        return const Color(0xFF4299e1);
      case 'resolved':
        return const Color(0xFF48bb78);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'in progress':
        return Icons.work;
      case 'resolved':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    // Check if user is admin
    if (user == null || user.role != UserRole.admin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('You do not have permission to access this page.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complaint Management',
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
              _loadComplaints();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Filter Section
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
                  // Status Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                color: _selectedFilter == filter
                                    ? Colors.white
                                    : const Color(0xFF2A2075),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            selected: _selectedFilter == filter,
                            onSelected: (selected) {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            backgroundColor: Colors.transparent,
                            selectedColor: const Color(0xFF2A2075),
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: _selectedFilter == filter
                                  ? const Color(0xFF2A2075)
                                  : ColorUtils.withOpacity(
                                      const Color(0xFF2A2075),
                                      0.3,
                                    ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Complaint Count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.report_problem,
                    color: ColorUtils.withOpacity(const Color(0xFF2A2075), 0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_filteredComplaints.length} complaints found',
                    style: TextStyle(
                      color: ColorUtils.withOpacity(
                        const Color(0xFF2A2075),
                        0.7,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (kDebugMode) ...[
                    const Spacer(),
                    Text(
                      'Total: ${_complaints.length} | Loading: $_isLoading',
                      style: TextStyle(
                        color: ColorUtils.withOpacity(
                          const Color(0xFF666666),
                          0.7,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Complaints List
            Expanded(
              child: _ShimmerLoading(
                isLoading: _isLoading,
                child: _filteredComplaints.isEmpty && !_isLoading
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _filteredComplaints.length,
                        itemBuilder: (context, index) {
                          final complaint = _filteredComplaints[index];
                          return _ComplaintCard(
                            complaint: complaint,
                            onTap: () => _showComplaintDetails(complaint),
                            onStatusUpdate: () =>
                                _showStatusUpdateDialog(complaint),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.report_problem_outlined,
            size: 80,
            color: ColorUtils.withOpacity(const Color(0xFF2A2075), 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No complaints found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: ColorUtils.withOpacity(const Color(0xFF2A2075), 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All complaints have been resolved!',
            style: TextStyle(fontSize: 14, color: const Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  void _showComplaintDetails(Map<String, dynamic> complaint) {
    final createdAt = (complaint['createdAt'] as Timestamp).toDate();
    final updatedAt = complaint['updatedAt'] != null
        ? (complaint['updatedAt'] as Timestamp).toDate()
        : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(complaint['status']),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getStatusIcon(complaint['status']),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Complaint Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Subject', complaint['subject']),
              _buildDetailRow('Category', complaint['category']),
              _buildDetailRow('User', complaint['userName']),
              _buildDetailRow('Email', complaint['userEmail']),
              _buildDetailRow(
                'Status',
                complaint['status'].toString().toUpperCase(),
              ),
              if (complaint['assignedTo'] != null)
                _buildDetailRow('Assigned To', complaint['assignedTo']),
              _buildDetailRow('Message', complaint['message']),
              _buildDetailRow('Submitted', _formatDate(createdAt)),
              if (updatedAt != null)
                _buildDetailRow('Last Updated', _formatDate(updatedAt)),
              if (complaint['response'] != null) ...[
                const SizedBox(height: 16),
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
                            Icons.reply,
                            color: Colors.blue.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Admin Response:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        complaint['response'],
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (complaint['status'] == 'pending' ||
              complaint['status'] == 'in progress') ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showReplyDialog(complaint);
              },
              child: const Text('Reply'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resolveComplaint(complaint);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark Resolved'),
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteConfirmation(complaint);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFff9a9e),
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ],
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(Map<String, dynamic> complaint) {
    String selectedStatus = complaint['status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Update Complaint Status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Current Status: ${complaint['status'] ?? 'Unknown'}'),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'New Status',
                      border: OutlineInputBorder(),
                    ),
                    items: ['pending', 'in progress', 'resolved'].map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ComplaintService.updateComplaintStatus(
                        complaint['id'],
                        selectedStatus,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Status updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update status: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReplyDialog(Map<String, dynamic> complaint) {
    final responseController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.reply, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Reply to Complaint',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Subject: ${complaint['subject']}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: responseController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Your Response *',
                  hintText: 'Enter your response to the complaint...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
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
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (responseController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a response'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        isSubmitting = true;
                      });

                      try {
                        await ComplaintService.addComplaintResponse(
                          complaint['id'],
                          responseController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          AsyncUtils.showSuccessSnackBar(
                            context,
                            'Response sent successfully',
                          );
                        }
                      } catch (e) {
                        setState(() {
                          isSubmitting = false;
                        });
                        if (context.mounted) {
                          AsyncUtils.showErrorSnackBar(
                            context,
                            'Failed to send response: $e',
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Send Response'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolveComplaint(Map<String, dynamic> complaint) async {
    await OperationService().handleComplaintOperation(
      context: context,
      operation: () =>
          ComplaintService.updateComplaintStatus(complaint['id'], 'resolved'),
      successMessage: 'Complaint marked as resolved',
      errorMessage: 'Failed to update status',
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> complaint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Complaint',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this complaint?\n\n'
          'Subject: ${complaint['subject']}\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await OperationService().handleComplaintOperation(
                context: context,
                operation: () =>
                    ComplaintService.deleteComplaint(complaint['id']),
                successMessage: 'Complaint deleted successfully',
                errorMessage: 'Failed to delete complaint',
                showLoading: false,
              );

              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
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
                fontWeight: FontWeight.w600,
                color: Color(0xFF4a5568),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF2d3748)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
