import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/complaint_service.dart';
import '../services/operation_service.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/async_utils.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  StreamSubscription? _complaintsSubscription;

  final List<String> _filters = ['All', 'Pending', 'In Progress', 'Resolved'];

  @override
  void initState() {
    super.initState();
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
      }

      _loadComplaints();
    });
  }

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cancel any existing subscription
      await _complaintsSubscription?.cancel();

      // Use stream to get real-time updates
      _complaintsSubscription = ComplaintService.getAllComplaints().listen(
        (complaints) {
          if (mounted) {
            setState(() {
              _complaints = complaints;
              _isLoading = false;
            });
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You need admin privileges to access this page.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complaints Management',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: const Color(0xFFff9a9e),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 24),
            onPressed: _loadComplaints,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFff9a9e), Color(0xFFfecfef)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Filter Section
              _buildFilterSection(),

              // Complaints List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _filteredComplaints.isEmpty
                    ? _buildEmptyState()
                    : _buildComplaintsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFff9a9e),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.filter_list,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Filter Complaints',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return FilterChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF4a5568),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: const Color(0xFFff9a9e),
                  checkmarkColor: Colors.white,
                  elevation: isSelected ? 4 : 0,
                  shadowColor: isSelected
                      ? const Color(0xFFff9a9e).withValues(alpha: 0.3)
                      : Colors.transparent,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(Icons.inbox, size: 40, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'No complaints found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All complaints have been resolved',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintsList() {
    return RefreshIndicator(
      onRefresh: _loadComplaints,
      color: const Color(0xFFff9a9e),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredComplaints.length,
        itemBuilder: (context, index) {
          final complaint = _filteredComplaints[index];
          return _buildComplaintCard(complaint);
        },
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final statusColor = _getStatusColor(complaint['status']);
    final statusIcon = _getStatusIcon(complaint['status']);
    final createdAt = (complaint['createdAt'] as Timestamp).toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showComplaintDetails(complaint),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with User Info and Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint['subject'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2d3748),
                            ),
                          ),
                          Text(
                            'By: ${complaint['userName']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            complaint['status'].toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        complaint['category'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Message preview
                Text(
                  complaint['message'],
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Date and Action Buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Submitted on ${_formatDate(createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Action Buttons
                    if (complaint['status'] == 'pending' ||
                        complaint['status'] == 'in progress')
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildActionButton(
                            'Reply',
                            Icons.reply,
                            Colors.blue,
                            () => _showReplyDialog(complaint),
                          ),
                          _buildActionButton(
                            'Assign',
                            Icons.person_add,
                            Colors.purple,
                            () => _showAssignDialog(complaint),
                          ),
                          _buildActionButton(
                            'Solve',
                            Icons.check_circle,
                            Colors.green,
                            () => _resolveComplaint(complaint),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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

  void _showAssignDialog(Map<String, dynamic> complaint) {
    String selectedAdmin = 'Admin Team';
    bool isSubmitting = false;

    final List<String> adminOptions = [
      'Admin Team',
      'Technical Support',
      'Customer Service',
      'Safety Team',
      'Payment Team',
    ];

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
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Assign Complaint',
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
              DropdownButtonFormField<String>(
                value: selectedAdmin,
                decoration: InputDecoration(
                  labelText: 'Assign to *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.purple),
                  ),
                ),
                items: adminOptions.map((admin) {
                  return DropdownMenuItem(value: admin, child: Text(admin));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAdmin = value!;
                  });
                },
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
                      setState(() {
                        isSubmitting = true;
                      });

                      final success = await OperationService()
                          .handleComplaintOperation(
                            context: context,
                            operation: () => ComplaintService.assignComplaint(
                              complaint['id'],
                              selectedAdmin,
                            ),
                            successMessage:
                                'Complaint assigned to $selectedAdmin',
                            errorMessage: 'Failed to assign complaint',
                            showLoading: false,
                          );
                      if (context.mounted) {
                        if (success) {
                          Navigator.of(context).pop();
                        } else {
                          setState(() {
                            isSubmitting = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
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
                  : const Text('Assign'),
            ),
          ],
        ),
      ),
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
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
