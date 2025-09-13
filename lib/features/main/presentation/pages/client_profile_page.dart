import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/user/presentation/bloc/user_bloc.dart';
import 'package:myapp/features/user/presentation/bloc/user_state.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_event.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_state.dart';
import 'package:myapp/core/services/google_calendar_service.dart';
import 'package:myapp/core/config/firestore_collections.dart';
import 'package:myapp/core/config/google_config.dart';
import 'dart:html' as html;
import 'dart:convert';

class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({super.key});

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    // Load user bookings when page initializes
    final userState = context.read<UserBloc>().state;
    if (userState is UserLoaded) {
      context.read<BookingBloc>().add(LoadBookings(userId: userState.user.id));
      _loadUserData(userState.user.id);
      
      // Check for OAuth callback result
      _checkForOAuthResult(userState.user.id);
    }
  }

  /// Load additional user data from Firestore (including Google Calendar sync settings)
  Future<void> _loadUserData(String userId) async {
    try {
      final userDoc = await FirestoreCollections.user(userId).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  /// Check for OAuth callback result from localStorage
  Future<void> _checkForOAuthResult(String userId) async {
    try {
      print('🔍 Checking for OAuth result in localStorage...');
      
      final oauthResult = html.window.localStorage['oauth_result'];
      if (oauthResult != null) {
        print('🔍 Found OAuth result in localStorage: $oauthResult');
        
        final result = jsonDecode(oauthResult);
        final code = result['code'] as String?;
        final state = result['state'] as String?;
        final success = result['success'] as bool? ?? false;
        
        print('🔍 OAuth result details:');
        print('   Code: ${code?.substring(0, 10)}...');
        print('   State: $state');
        print('   Success: $success');
        
        // Clean up localStorage
        html.window.localStorage.remove('oauth_result');
        
        if (success && code != null && state != null) {
          print('✅ Processing OAuth success from callback');
          
          // Complete the OAuth flow
          await _completeOAuthFlow(code, state, userId);
        } else {
          print('❌ OAuth callback was not successful');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Google Calendar authorization failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print('🔍 No OAuth result found in localStorage');
      }
    } catch (e) {
      print('❌ Error checking OAuth result: $e');
    }
  }

  /// Complete OAuth flow with authorization code
  Future<void> _completeOAuthFlow(String code, String state, String userId) async {
    try {
      print('🔄 Completing OAuth flow with authorization code');
      
      // Exchange code for tokens
      final redirectUri = html.window.location.origin + '/oauth/callback';
      final clientId = GoogleConfig.clientId;
      
      final success = await GoogleCalendarService.instance.exchangeCodeForTokens(code, redirectUri, clientId);
      
      if (success) {
        // Update user profile with sync settings
        await FirestoreCollections.user(userId).update({
          'googleCalendarSync': {
            'enabled': true,
            'calendarId': 'primary',
            'connectedAt': DateTime.now().toIso8601String(),
          },
        });
        
        // Refresh user data
        await _loadUserData(userId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Google Calendar connected successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to complete Google Calendar connection'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error completing OAuth flow: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error completing Google Calendar connection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Handle Google Calendar sync toggle
  Future<void> _handleGoogleCalendarSync(bool enabled, String userId) async {
    try {
      if (enabled) {
        // Always trigger OAuth flow when enabling (even if already enabled)
        // This allows users to re-authenticate or connect for the first time
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            title: Text('Connecting to Google Calendar'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Please authorize access to your Google Calendar...'),
                SizedBox(height: 8),
                Text(
                  'A popup window will open for authorization.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );

        // Initialize Google Calendar service (this will trigger OAuth flow)
        final calendarService = GoogleCalendarService.instance;
        final initialized = await calendarService.initialize();

        Navigator.of(context).pop(); // Close loading dialog

        if (initialized) {
          // Save sync settings to user profile
          await FirestoreCollections.user(userId).update({
            'googleCalendarSync': {
              'enabled': true,
              'calendarId': 'primary',
              'connectedAt': DateTime.now().toIso8601String(),
            },
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Google Calendar sync connected successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh user data to update UI
          await _loadUserData(userId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to connect to Google Calendar. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Disable Google Calendar sync
        await FirestoreCollections.user(userId).update({
          'googleCalendarSync': {
            'enabled': false,
            'calendarId': null,
            'connectedAt': null,
          },
        });

        // Disconnect from Google Calendar service
        await GoogleCalendarService.instance.disconnect();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Calendar sync disabled'),
            backgroundColor: Colors.orange,
          ),
        );

        // Refresh user data to update UI
        await _loadUserData(userId);
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close any open dialogs
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating Google Calendar sync: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Test Google Calendar connection (triggers OAuth flow)
  Future<void> _testGoogleCalendarConnection(String userId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Testing Google Calendar Connection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Opening Google authorization...'),
              SizedBox(height: 8),
              Text(
                'Please complete the authorization in the popup window.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );

      // Force a fresh OAuth flow by disconnecting first
      await GoogleCalendarService.instance.disconnect();
      
      // Initialize Google Calendar service (this will trigger OAuth flow)
      final calendarService = GoogleCalendarService.instance;
      final initialized = await calendarService.initialize();

      Navigator.of(context).pop(); // Close loading dialog

      if (initialized) {
        // Update connection timestamp
        await FirestoreCollections.user(userId).update({
          'googleCalendarSync': {
            'enabled': true,
            'calendarId': 'primary',
            'connectedAt': DateTime.now().toIso8601String(),
          },
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Google Calendar connected successfully! Try creating a booking to test.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        // Refresh user data
        await _loadUserData(userId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to connect to Google Calendar. Check console for details.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close any open dialogs
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error testing Google Calendar connection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client/dashboard'),
        ),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEdit,
            ),
        ],
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, userState) {
          if (userState is UserLoaded) {
            _populateForm(userState.user);
            return _buildProfileContent(userState);
          } else if (userState is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return const Center(child: Text('Error loading profile'));
          }
        },
      ),
    );
  }

  Widget _buildProfileContent(userState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(userState.user),
          const SizedBox(height: 24),
          _buildPersonalInfoSection(),
          const SizedBox(height: 24),
          _buildBookingStatsSection(),
          const SizedBox(height: 24),
          _buildBookingHistorySection(),
          const SizedBox(height: 24),
          _buildPreferencesSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              child: Text(
                user.displayName.isNotEmpty 
                    ? user.displayName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName.isNotEmpty ? user.displayName : 'No Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? 'No Email',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Client',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
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

  Widget _buildPersonalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    enabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    enabled: false, // Email usually can't be changed
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Booking Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BlocBuilder<BookingBloc, BookingState>(
              builder: (context, bookingState) {
                if (bookingState is BookingLoaded) {
                  final bookings = bookingState.bookings;
                  final upcoming = bookings.where((b) => b.status == 'confirmed' && b.startTime.isAfter(DateTime.now())).length;
                  final completed = bookings.where((b) => b.status == 'completed').length;
                  final cancelled = bookings.where((b) => b.status == 'cancelled').length;

                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('Total', bookings.length.toString(), Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('Upcoming', upcoming.toString(), Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('Completed', completed.toString(), Colors.orange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('Cancelled', cancelled.toString(), Colors.red),
                      ),
                    ],
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingHistorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Recent Bookings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/client/bookings'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BlocBuilder<BookingBloc, BookingState>(
              builder: (context, bookingState) {
                if (bookingState is BookingLoaded) {
                  final recentBookings = bookingState.bookings.take(3).toList();
                  
                  if (recentBookings.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No bookings yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: recentBookings.map((booking) => _buildBookingItem(booking)).toList(),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingItem(booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(booking.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session ${booking.bookableSessionId.length > 8 ? booking.bookableSessionId.substring(0, 8) + '...' : booking.bookableSessionId}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(booking.startTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(booking.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              booking.status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _getStatusColor(booking.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive booking confirmations and reminders'),
              value: true, // This would come from user preferences
              onChanged: _isEditing ? (value) {
                // Handle notification preference change
              } : null,
            ),
            SwitchListTile(
              title: const Text('SMS Notifications'),
              subtitle: const Text('Receive text message updates'),
              value: false, // This would come from user preferences
              onChanged: _isEditing ? (value) {
                // Handle SMS preference change
              } : null,
            ),
            SwitchListTile(
              title: const Text('Auto-booking'),
              subtitle: const Text('Automatically book recurring sessions'),
              value: false, // This would come from user preferences
              onChanged: _isEditing ? (value) {
                // Handle auto-booking preference change
              } : null,
            ),
            BlocBuilder<UserBloc, UserState>(
              builder: (context, state) {
                if (state is! UserLoaded) return const SizedBox.shrink();
                
                final isCalendarSyncEnabled = GoogleCalendarService.isCalendarSyncEnabled(_userData);
                
                return Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Google Calendar Sync'),
                      subtitle: Text(
                        isCalendarSyncEnabled 
                          ? 'Bookings will sync to your Google Calendar'
                          : 'Enable to sync bookings to Google Calendar'
                      ),
                      value: isCalendarSyncEnabled,
                      onChanged: _isEditing ? (value) => _handleGoogleCalendarSync(value, state.user.id) : null,
                    ),
                    if (isCalendarSyncEnabled && _isEditing)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _testGoogleCalendarConnection(state.user.id),
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Connect to Google Calendar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _populateForm(user) {
    _nameController.text = user.displayName;
    _emailController.text = user.email;
    _phoneController.text = user.phone ?? '';
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement profile update logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _isEditing = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
