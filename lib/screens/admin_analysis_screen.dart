import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/ride.dart';
import '../models/user_model.dart';
import '../services/ride_service.dart';

class AdminAnalysisScreen extends StatefulWidget {
  const AdminAnalysisScreen({super.key});

  @override
  State<AdminAnalysisScreen> createState() => _AdminAnalysisScreenState();
}

class _AdminAnalysisScreenState extends State<AdminAnalysisScreen> {
  List<Ride> _rides = [];
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _selectedTimeFilter = 'All';
  String _searchQuery = '';
  DateTime? _selectedDate;
  final List<String> _filterOptions = [
    'All',
    'Completed',
    'Confirmed',
    'Cancelled',
  ];
  final List<String> _timeFilterOptions = [
    'All',
    'Today',
    'Yesterday',
    'This Week',
    'This Month',
    'This Year',
    'Date Select',
  ];

  @override
  void initState() {
    super.initState();
    // Add a small delay to ensure the widget is fully mounted
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all rides using one-time fetch for better reliability
      final rides = await RideService.getAllRidesOnce();
      if (mounted) {
        setState(() {
          _rides = rides;
        });
        print('Loaded ${rides.length} rides');
      }

      // Load all users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final users = usersSnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
        print('Loaded ${users.length} users');
      }
    } catch (e) {
      print('Error in _loadData: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'Error loading data';
        if (e.toString().contains('PERMISSION_DENIED')) {
          errorMessage =
              'Permission denied. Please check if you have admin privileges.';
        } else if (e.toString().contains('network')) {
          errorMessage =
              'Network error. Please check your internet connection.';
        } else {
          errorMessage = 'Error loading data: $e';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  List<Ride> get _filteredRides {
    List<Ride> filtered = _rides;

    // Apply status filter
    if (_selectedFilter != 'All') {
      final status = RideStatus.values.firstWhere(
        (e) => e.displayName == _selectedFilter,
        orElse: () => RideStatus.confirmed,
      );
      filtered = filtered.where((ride) => ride.status == status).toList();
    }

    // Apply time filter
    if (_selectedTimeFilter != 'All') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      switch (_selectedTimeFilter) {
        case 'Today':
          filtered = filtered.where((ride) {
            final rideDate = DateTime(
              ride.createdAt.year,
              ride.createdAt.month,
              ride.createdAt.day,
            );
            return rideDate.isAtSameMomentAs(today);
          }).toList();
          break;

        case 'Yesterday':
          final yesterday = today.subtract(const Duration(days: 1));
          filtered = filtered.where((ride) {
            final rideDate = DateTime(
              ride.createdAt.year,
              ride.createdAt.month,
              ride.createdAt.day,
            );
            return rideDate.isAtSameMomentAs(yesterday);
          }).toList();
          break;

        case 'This Week':
          final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
          filtered = filtered.where((ride) {
            return ride.createdAt.isAfter(
              startOfWeek.subtract(const Duration(days: 1)),
            );
          }).toList();
          break;

        case 'This Month':
          final startOfMonth = DateTime(now.year, now.month, 1);
          filtered = filtered.where((ride) {
            return ride.createdAt.isAfter(
              startOfMonth.subtract(const Duration(days: 1)),
            );
          }).toList();
          break;

        case 'This Year':
          final startOfYear = DateTime(now.year, 1, 1);
          filtered = filtered.where((ride) {
            return ride.createdAt.isAfter(
              startOfYear.subtract(const Duration(days: 1)),
            );
          }).toList();
          break;
        case 'Date Select':
          if (_selectedDate != null) {
            final selectedDate = DateTime(
              _selectedDate!.year,
              _selectedDate!.month,
              _selectedDate!.day,
            );
            filtered = filtered.where((ride) {
              final rideDate = DateTime(
                ride.createdAt.year,
                ride.createdAt.month,
                ride.createdAt.day,
              );
              return rideDate.isAtSameMomentAs(selectedDate);
            }).toList();
          }
          break;
      }
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((ride) {
        final student = _getUserById(ride.userId);
        final driver = ride.driverId != null
            ? _getUserById(ride.driverId!)
            : null;

        return ride.fromLocation.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            ride.toLocation.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (student?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                false) ||
            (driver?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                false) ||
            ride.id.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  UserModel? _getUserById(String userId) {
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  double _calculateEstimatedFare(Ride ride) {
    // Simple fare calculation based on location distance
    const baseFare = 20.0;
    const perKmRate = 5.0;

    // Mock distance calculation (in real app, use actual coordinates)
    final locations = [ride.fromLocation, ride.toLocation];
    double estimatedDistance = 2.0; // Default 2km

    // Adjust distance based on location types
    if (locations.any((loc) => loc.contains('Gate'))) {
      estimatedDistance = 3.0; // Gate to campus locations
    } else if (locations.any((loc) => loc.contains('Hospital'))) {
      estimatedDistance = 1.5; // Hospital is closer
    } else if (locations.any((loc) => loc.contains('LHC'))) {
      estimatedDistance = 1.0; // LHC is central
    }

    return baseFare + (estimatedDistance * perKmRate);
  }

  double _calculateTotalFare() {
    double total = 0.0;
    for (final ride in _filteredRides) {
      total += ride.actualFare ?? _calculateEstimatedFare(ride);
    }
    return total;
  }

  Future<void> _downloadCSV() async {
    try {
      // Request storage permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      bool hasPermission =
          statuses[Permission.storage]?.isGranted == true ||
          statuses[Permission.manageExternalStorage]?.isGranted == true;

      if (!hasPermission) {
        _showSnackBar(
          'Storage permission required to download CSV',
          Colors.red,
        );
        return;
      }

      // Get downloads directory
      Directory? directory;
      try {
        directory = await getExternalStorageDirectory();
      } catch (e) {
        print('Error getting external storage: $e');
      }

      if (directory == null) {
        // Fallback to app documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      // Create CSV content
      final csvContent = _generateCSVContent();

      // Create filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'ride_analysis_$timestamp.csv';
      final file = File('${directory.path}/$filename');

      // Write CSV to file
      await file.writeAsString(csvContent);

      _showSnackBar(
        'CSV downloaded to: ${directory.path}/$filename',
        Colors.green,
      );
    } catch (e) {
      print('Error downloading CSV: $e');
      _showSnackBar('Error downloading CSV: $e', Colors.red);
    }
  }

  String _generateCSVContent() {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln(
      'Ride ID,Student Name,Driver Name,From Location,To Location,Date,Time,Fare,Status',
    );

    // CSV Data
    for (final ride in _filteredRides) {
      final student = _getUserById(ride.userId);
      final driver = ride.driverId != null
          ? _getUserById(ride.driverId!)
          : null;

      final rideId = ride.id.substring(0, 8);
      final studentName = student?.name ?? 'Unknown';
      final driverName = driver?.name ?? 'Not Assigned';
      final fromLocation = ride.fromLocation;
      final toLocation = ride.toLocation;
      final date =
          '${ride.createdAt.day}/${ride.createdAt.month}/${ride.createdAt.year}';
      final time =
          '${ride.createdAt.hour}:${ride.createdAt.minute.toString().padLeft(2, '0')}';
      final fare = ride.actualFare != null
          ? ride.actualFare!.toStringAsFixed(2)
          : _calculateEstimatedFare(ride).toStringAsFixed(2);
      final status = ride.status.displayName;

      buffer.writeln(
        '$rideId,$studentName,$driverName,$fromLocation,$toLocation,$date,$time,$fare,$status',
      );
    }

    return buffer.toString();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeFilter = 'Date Select';
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.completed:
        return Colors.green;
      case RideStatus.confirmed:
        return Colors.orange;
      case RideStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(RideStatus status) {
    switch (status) {
      case RideStatus.completed:
        return Icons.check_circle;
      case RideStatus.confirmed:
        return Icons.schedule;
      case RideStatus.cancelled:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Analysis'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadCSV,
            tooltip: 'Download CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'Info',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFff9a9e), Color(0xFFfecfef), Color(0xFFfecfef)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Statistics Header
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 12),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFfff5f7)],
                    ),
                  ),
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.analytics,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ride Analysis',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2d3748),
                              ),
                            ),
                            Text(
                              '${_filteredRides.length} rides • ₹${_calculateTotalFare().toStringAsFixed(0)} total',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Active filters display
                      if (_selectedFilter != 'All' ||
                          _selectedTimeFilter != 'All')
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (_selectedFilter != 'All')
                              _buildFilterChip(
                                'Status: $_selectedFilter',
                                Colors.orange,
                              ),
                            if (_selectedTimeFilter != 'All')
                              _buildFilterChip(
                                'Time: $_selectedTimeFilter',
                                Colors.blue,
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Rides List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredRides.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: EdgeInsets.all(isTablet ? 20 : 12),
                        itemCount: _filteredRides.length,
                        itemBuilder: (context, index) {
                          final ride = _filteredRides[index];
                          final student = _getUserById(ride.userId);
                          final driver = ride.driverId != null
                              ? _getUserById(ride.driverId!)
                              : null;

                          return _buildRideCard(
                            ride,
                            student,
                            driver,
                            isTablet,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Bar
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search rides, locations, or users...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Navigation
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        'Status',
                        _filterOptions,
                        _selectedFilter,
                        (value) => setState(() => _selectedFilter = value),
                        Icons.filter_list,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterDropdown(
                        'Time',
                        _timeFilterOptions,
                        _selectedTimeFilter,
                        (value) => setState(() => _selectedTimeFilter = value),
                        Icons.access_time,
                        Colors.blue,
                      ),
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

  Widget _buildFilterChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.inbox,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No rides found' : 'No rides available',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : _selectedTimeFilter != 'All' || _selectedFilter != 'All'
                ? 'Try adjusting your filters'
                : 'Total rides loaded: ${_rides.length}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(
    Ride ride,
    UserModel? student,
    UserModel? driver,
    bool isTablet,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 6,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                _getStatusColor(ride.status).withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status and ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(ride.status),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(
                              ride.status,
                            ).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(ride.status),
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ride.status.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${ride.id.substring(0, 6)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Compact ride details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      // Users row
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactDetailRow(
                              'Student',
                              student?.name ?? 'Unknown',
                              Icons.person,
                              Colors.blue,
                            ),
                          ),
                          if (driver != null) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildCompactDetailRow(
                                'Driver',
                                driver.name,
                                Icons.drive_eta,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Locations row
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactDetailRow(
                              'From',
                              ride.fromLocation,
                              Icons.location_on,
                              Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCompactDetailRow(
                              'To',
                              ride.toLocation,
                              Icons.location_on,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Time and fare row
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactDetailRow(
                              'Time',
                              _formatDateTime(ride.createdAt),
                              Icons.access_time,
                              Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCompactDetailRow(
                              'Fare',
                              ride.actualFare != null
                                  ? '₹${ride.actualFare!.toStringAsFixed(0)}'
                                  : '₹${_calculateEstimatedFare(ride).toStringAsFixed(0)} (Est.)',
                              Icons.attach_money,
                              ride.actualFare != null
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
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
  }

  Widget _buildCompactDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2d3748),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    String label,
    List<String> options,
    String selected,
    Function(String) onChanged,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'Date Select') {
            _selectDate();
          } else {
            onChanged(value);
          }
        },
        itemBuilder: (context) => options.map((option) {
          return PopupMenuItem<String>(
            value: option,
            child: Row(
              children: [
                Icon(
                  selected == option
                      ? Icons.check
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: selected == option ? color : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  option,
                  style: TextStyle(
                    fontWeight: selected == option
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selected == option ? color : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selected == 'Date Select' && _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : selected,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selected == 'All' ? Colors.grey.shade600 : color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ride Analysis',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This screen provides comprehensive analysis of all rides in the system.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Features:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• View all ride details\n• Filter by status\n• Real-time data updates\n• Student and driver information\n• Fare and timing details',
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
          ],
        );
      },
    );
  }
}
