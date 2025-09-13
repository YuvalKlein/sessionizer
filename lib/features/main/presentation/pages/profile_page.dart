import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_event.dart';
import 'package:myapp/features/user/presentation/bloc/user_bloc.dart';
import 'package:myapp/features/user/presentation/bloc/user_state.dart';
import 'package:myapp/core/services/google_calendar_service.dart';
import 'package:myapp/core/config/firestore_collections.dart';
import 'package:myapp/core/config/google_config.dart';
import 'dart:html' as html;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    // Load user data when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserData();
        
        // Check for OAuth callback result
        final userState = context.read<UserBloc>().state;
        if (userState is UserLoaded) {
          _checkForOAuthResult(userState.user.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    // Load user data from Firestore for Google Calendar sync settings
    final userState = context.read<UserBloc>().state;
    if (userState is UserLoaded) {
      _loadUserDataFromFirestore(userState.user.id);
    }
  }

  /// Load additional user data from Firestore (including Google Calendar sync settings)
  Future<void> _loadUserDataFromFirestore(String userId) async {
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
      print('🔍 [Instructor] Checking for OAuth result in localStorage...');
      
      final oauthResult = html.window.localStorage['oauth_result'];
      if (oauthResult != null) {
        print('🔍 [Instructor] Found OAuth result in localStorage: $oauthResult');
        
        final result = jsonDecode(oauthResult);
        final code = result['code'] as String?;
        final state = result['state'] as String?;
        final success = result['success'] as bool? ?? false;
        
        print('🔍 [Instructor] OAuth result details:');
        print('   Code: ${code?.substring(0, 10)}...');
        print('   State: $state');
        print('   Success: $success');
        
        // Clean up localStorage
        html.window.localStorage.remove('oauth_result');
        
        if (success && code != null && state != null) {
          print('✅ [Instructor] Processing OAuth success from callback');
          
          // Complete the OAuth flow
          await _completeOAuthFlow(code, state, userId);
        } else {
          print('❌ [Instructor] OAuth callback was not successful');
          
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
        print('🔍 [Instructor] No OAuth result found in localStorage');
      }
    } catch (e) {
      print('❌ [Instructor] Error checking OAuth result: $e');
    }
  }

  /// Complete OAuth flow with authorization code
  Future<void> _completeOAuthFlow(String code, String state, String userId) async {
    try {
      print('🔄 [Instructor] Completing OAuth flow with authorization code');
      
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
        await _loadUserDataFromFirestore(userId);
        
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
      print('❌ [Instructor] Error completing OAuth flow: $e');
      
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
                'Please complete the authorization and you\'ll be redirected back.',
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
        await _loadUserDataFromFirestore(userId);
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
                  'You will be redirected to Google for authorization.',
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
          await _loadUserDataFromFirestore(userId);
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
        await _loadUserDataFromFirestore(userId);
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        if (userState is UserLoaded) {
          // Populate controllers with user data
          if (!_isEditing) {
            _nameController.text = userState.user.displayName;
            _emailController.text = userState.user.email;
            _phoneController.text = userState.user.phone ?? '';
          }

          return _buildProfileContent(userState.user);
        } else if (userState is UserLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (userState is UserError) {
          return _buildErrorState(userState.message);
        }
        return const Scaffold(
          body: Center(child: Text('Unknown user state')),
        );
      },
    );
  }

  Widget _buildProfileContent(dynamic user) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 24),
            _buildProfileForm(user),
            const SizedBox(height: 24),
            _buildAccountSettings(),
            const SizedBox(height: 24),
            _buildDangerZone(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.purple.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Text(
              user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isInstructor ? Colors.green : Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isInstructor ? 'Instructor' : 'Client',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(dynamic user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                      if (!_isEditing) {
                        // Reset form when canceling edit
                        _nameController.text = user.displayName;
                        _emailController.text = user.email;
                        _phoneController.text = user.phone ?? '';
                      }
                    });
                  },
                  icon: Icon(_isEditing ? Icons.close : Icons.edit),
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
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
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
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    enabled: false, // Email cannot be changed
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                // Reset form
                                _nameController.text = user.displayName;
                                _emailController.text = user.email;
                                _phoneController.text = user.phone ?? '';
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            child: const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Manage your notification preferences',
              onTap: () => _showNotificationSettings(),
            ),
            _buildSettingTile(
              icon: Icons.security,
              title: 'Privacy & Security',
              subtitle: 'Manage your privacy settings',
              onTap: () => _showPrivacySettings(),
            ),
            // Google Calendar Sync Setting
            BlocBuilder<UserBloc, UserState>(
              builder: (context, state) {
                if (state is! UserLoaded) return const SizedBox.shrink();
                
                final isCalendarSyncEnabled = GoogleCalendarService.isCalendarSyncEnabled(_userData);
                
                return Column(
                  children: [
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.blue),
                      title: const Text('Google Calendar Sync'),
                      subtitle: Text(
                        isCalendarSyncEnabled 
                          ? 'Bookings will sync to your Google Calendar'
                          : 'Enable to sync bookings to Google Calendar'
                      ),
                      trailing: Switch(
                        value: isCalendarSyncEnabled,
                        onChanged: _isEditing ? (value) => _handleGoogleCalendarSync(value, state.user.id) : null,
                      ),
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
            _buildSettingTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              onTap: () => _showHelpDialog(),
            ),
            _buildSettingTile(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'App version and information',
              onTap: () => _showAboutDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDangerTile(
              icon: Icons.logout,
              title: 'Sign Out',
              subtitle: 'Sign out of your account',
              onTap: () => _showSignOutDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade600),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.red.shade600),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildErrorState(String message) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _loadUserData(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement profile update logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Text('Notification settings will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const Text('Privacy settings will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'Need help? Here are some common actions:\n\n'
          '• Update your profile information\n'
          '• Manage your bookings\n'
          '• Browse available sessions\n'
          '• Contact support for assistance\n\n'
          'For more help, contact support.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: const Text(
          'Sessionizer App\n'
          'Version 1.0.0\n\n'
          'A platform for managing and booking sessions.\n\n'
          'Built with Flutter and Firebase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(SignOutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

}
