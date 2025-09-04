import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/user_service.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/widgets/user_avatar.dart';
import 'package:myapp/services/avatar_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final UserService _userService = UserService();
  bool _isUpdating = false;
  UserModel? _currentUser;

  Future<void> _changeAvatar(UserModel user) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      // Generate a new random avatar
      final newAvatarURL = AvatarService.generateAvatarUrl(user.displayName, user.email);
      
      await _userService.updateUserProfile(
        user.id,
        photoURL: newAvatarURL,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update avatar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userService = context.read<UserService>();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('No user logged in'))
          : StreamProvider<UserModel?>.value(
              initialData: null,
              value: userService.getUserStream(user.uid),
              child: Consumer<UserModel?>(
                builder: (context, userModel, child) {
                  if (userModel == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  // Update controllers only when user data changes
                  if (_currentUser != userModel) {
                    _currentUser = userModel;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _nameController.text = userModel.displayName;
                        _emailController.text = userModel.email;
                      }
                    });
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Avatar Section
                          Center(
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    UserAvatar(
                                      user: userModel,
                                      size: 100,
                                      showBorder: true,
                                      borderColor: Theme.of(context).primaryColor,
                                      borderWidth: 3,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: _isUpdating
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                          onPressed: _isUpdating ? null : () => _changeAvatar(userModel),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tap the camera icon to change your avatar',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Please enter a name' : null,
                          ),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            enabled: false,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                try {
                                  await _userService.updateUserProfile(
                                    user.uid,
                                    displayName: _nameController.text,
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Profile updated successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to update profile: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            child: const Text('Save'),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              authService.signOut();
                            },
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
