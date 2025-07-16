import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../services/ride_service.dart';
import '../services/auth_service.dart';
import '../models/ride.dart';
import '../models/user_model.dart';

class BookRideScreen extends StatefulWidget {
  const BookRideScreen({super.key});

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  final TextEditingController _fromLocationController = TextEditingController();
  final TextEditingController _toLocationController = TextEditingController();
  final AuthService _authService = AuthService();
  String? selectedFromLocation;
  String? selectedToLocation;
  DateTime? selectedDateTime;
  final bool _isScheduled = false;
  bool _isLoading = false;
  bool _isLoadingDrivers = false;
  List<UserModel> _availableDrivers = [];
  UserModel? _selectedDriver;

  // IIT Delhi locations
  final List<String> locations = [
    'LHC',
    'IIT Hospital',
    'Aravali',
    'Girnar',
    'Himadri',
    'Jwalamukhi',
    'Kailash',
    'Karakoram',
    'Kumaon',
    'Nilgiri',
    'Satpura',
    'Shivalik',
    'Udaigiri',
    'Vindhyachal',
    'Zanskar',
    'Gate No 1(Main Gate)',
    'Gate No 2 (Hostel Gate)',
    'Gate No 3( JNU Gate)',
    'Gate No 4(Mehrauli Gate)',
    'Gate No 5 (Adhchini Gate)',
    'Gate No 6(Jia Sarai Gate)',
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailableDrivers();
  }

  @override
  void dispose() {
    _fromLocationController.dispose();
    _toLocationController.dispose();
    super.dispose();
  }

  Widget _buildDriverProfileImage(String imageData) {
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
              debugPrint('Error loading base64 image in driver list: $error');
            }
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF48bb78), Color(0xFF38a169)],
                ),
              ),
              child: const Icon(Icons.drive_eta, size: 25, color: Colors.white),
            );
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
              debugPrint('Driver list loading placeholder for: $url');
            }
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF48bb78), Color(0xFF38a169)],
                ),
              ),
              child: const Icon(Icons.drive_eta, size: 25, color: Colors.white),
            );
          },
          errorWidget: (context, url, error) {
            if (kDebugMode) {
              debugPrint(
                'Driver list error loading image: $url, error: $error',
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
              child: const Icon(Icons.drive_eta, size: 25, color: Colors.white),
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
        child: const Icon(Icons.drive_eta, size: 25, color: Colors.white),
      );
    }
  }

  Future<void> _loadAvailableDrivers() async {
    setState(() {
      _isLoadingDrivers = true;
    });

    try {
      final drivers = await _authService.getUsersByRole(UserRole.driver).first;
      final availableDrivers = drivers;

      if (kDebugMode) {
        debugPrint('Loaded ${availableDrivers.length} available drivers');
        for (var driver in availableDrivers) {
          debugPrint(
            'Driver: ${driver.name}, Photo: ${driver.profilePhoto != null ? 'Yes' : 'No'}',
          );
        }
      }

      setState(() {
        _availableDrivers = availableDrivers;
        _isLoadingDrivers = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading drivers: $e');
      }
      setState(() {
        _isLoadingDrivers = false;
      });
    }
  }

  void _bookRide() async {
    if (selectedFromLocation == null || selectedToLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both pickup and destination locations'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedFromLocation == selectedToLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup and destination locations cannot be the same'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) {
        throw Exception('User not found');
      }
      Ride ride;

      if (_selectedDriver != null) {
        // Create ride and assign selected driver
        ride = await RideService.createRide(
          userId: user.id,
          fromLocation: selectedFromLocation!,
          toLocation: selectedToLocation!,
          scheduledTime: _isScheduled ? selectedDateTime : null,
        );

        // Try to assign the selected driver to the ride
        try {
          await RideService.assignDriver(ride.id, _selectedDriver!.id);
          if (kDebugMode) {
            debugPrint(
              'Assigned driver ${_selectedDriver!.name} to ride ${ride.id}',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Failed to assign driver: $e');
          }
          // Continue without driver assignment
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ride booked successfully, but driver assignment failed: ${e.toString()}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        // Create ride without driver assignment (will be assigned later)
        ride = await RideService.createRide(
          userId: user.id,
          fromLocation: selectedFromLocation!,
          toLocation: selectedToLocation!,
          scheduledTime: _isScheduled ? selectedDateTime : null,
        );

        if (kDebugMode) {
          debugPrint('Created ride ${ride.id} without driver assignment');
        }
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showBookingConfirmation(ride);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book ride: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBookingConfirmation(Ride ride) {
    final estimatedFare = RideService.calculateEstimatedFare(
      ride.fromLocation,
      ride.toLocation,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfirmationRow('Ride ID', ride.id),
              _buildConfirmationRow('From', ride.fromLocation),
              _buildConfirmationRow('To', ride.toLocation),
              if (_selectedDriver != null)
                _buildConfirmationRow('Driver', _selectedDriver!.name),
              _buildConfirmationRow('Status', ride.status.displayName),
              _buildConfirmationRow(
                'Estimated Fare',
                '₹${estimatedFare.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.green.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedDriver != null
                            ? 'Your ride has been booked successfully! Driver ${_selectedDriver!.name} has been assigned to your ride.'
                            : 'Your ride has been booked successfully! A driver will be assigned shortly.',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Book Ride',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                _buildHeaderCard(context),
                const SizedBox(height: 24),

                // From Location
                _buildLocationCard(
                  'From',
                  Icons.location_on,
                  const Color(0xFF4299e1),
                  selectedFromLocation,
                  (location) {
                    setState(() {
                      selectedFromLocation = location;
                      _fromLocationController.text = location;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // To Location
                _buildLocationCard(
                  'To',
                  Icons.location_searching,
                  const Color(0xFFed8936),
                  selectedToLocation,
                  (location) {
                    setState(() {
                      selectedToLocation = location;
                      _toLocationController.text = location;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Driver Selection
                _buildDriverSelectionCard(),
                const SizedBox(height: 24),

                // Book Ride Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        (selectedFromLocation != null &&
                            selectedToLocation != null &&
                            !_isLoading)
                        ? _bookRide
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF48bb78),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: const Color(
                        0xFF48bb78,
                      ).withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Book Ride',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFf8f9ff)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF48bb78), Color(0xFF38a169)],
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF48bb78).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_car,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Book Your E-Rickshaw',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2d3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your pickup and destination locations',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF718096)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDriverSelectionCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF48bb78).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF48bb78),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.drive_eta,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Select Driver',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              _showDriverSelectionDialog();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedDriver != null
                      ? const Color(0xFF48bb78)
                      : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _selectedDriver != null
                    ? const Color(0xFF48bb78).withValues(alpha: 0.05)
                    : Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedDriver != null
                        ? Icons.check_circle
                        : Icons.arrow_drop_down,
                    color: _selectedDriver != null
                        ? const Color(0xFF48bb78)
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _selectedDriver != null
                        ? Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child:
                                    _selectedDriver!.profilePhoto != null &&
                                        _selectedDriver!
                                            .profilePhoto!
                                            .isNotEmpty
                                    ? _buildDriverProfileImage(
                                        _selectedDriver!.profilePhoto!,
                                      )
                                    : Container(
                                        width: 40,
                                        height: 40,
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
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedDriver!.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2d3748),
                                      ),
                                    ),
                                    Text(
                                      'Selected Driver',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Choose a driver (optional)',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(
    String title,
    IconData icon,
    Color color,
    String? selectedLocation,
    Function(String) onLocationSelected,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              _showLocationPicker(context, title, onLocationSelected);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selectedLocation != null
                      ? color
                      : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: selectedLocation != null
                    ? color.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  Icon(
                    selectedLocation != null
                        ? Icons.check_circle
                        : Icons.arrow_drop_down,
                    color: selectedLocation != null
                        ? color
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedLocation ?? 'Select $title location',
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedLocation != null
                            ? const Color(0xFF2d3748)
                            : Colors.grey.shade600,
                        fontWeight: selectedLocation != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDriverSelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.drive_eta, color: Color(0xFF48bb78)),
                    const SizedBox(width: 12),
                    const Text(
                      'Select Driver',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2d3748),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Driver List
              Expanded(
                child: _isLoadingDrivers
                    ? const Center(child: CircularProgressIndicator())
                    : _availableDrivers.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.drive_eta_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No drivers available',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount:
                            _availableDrivers.length +
                            1, // +1 for "Any Driver" option
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // "Any Driver" option
                            return ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF667eea,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: const Icon(
                                  Icons.shuffle,
                                  color: Color(0xFF667eea),
                                  size: 25,
                                ),
                              ),
                              title: const Text(
                                'Any Available Driver',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2d3748),
                                ),
                              ),
                              subtitle: Text(
                                'Let us assign the best driver',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: _selectedDriver == null
                                  ? const Icon(
                                      Icons.check,
                                      color: Color(0xFF48bb78),
                                    )
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedDriver = null;
                                });
                                Navigator.of(context).pop();
                              },
                            );
                          }

                          final driver = _availableDrivers[index - 1];
                          final isSelected = _selectedDriver?.id == driver.id;

                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child:
                                  driver.profilePhoto != null &&
                                      driver.profilePhoto!.isNotEmpty
                                  ? _buildDriverProfileImage(
                                      driver.profilePhoto!,
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
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
                                        size: 25,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                            title: Text(
                              driver.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2d3748),
                              ),
                            ),
                            subtitle: Text(
                              'Professional Driver',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Color(0xFF48bb78),
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedDriver = driver;
                              });
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLocationPicker(
    BuildContext context,
    String title,
    Function(String) onLocationSelected,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      title == 'From'
                          ? Icons.location_on
                          : Icons.location_searching,
                      color: title == 'From'
                          ? const Color(0xFF4299e1)
                          : const Color(0xFFed8936),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Select $title Location',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2d3748),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Location List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final location = locations[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF667eea).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFF667eea),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2d3748),
                        ),
                      ),
                      subtitle: Text(
                        'IIT Delhi Campus',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      onTap: () {
                        onLocationSelected(location);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
