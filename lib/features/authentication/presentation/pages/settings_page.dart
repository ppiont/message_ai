import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/core/providers/database_provider.dart';
import 'package:message_ai/features/authentication/presentation/providers/auth_providers.dart';
import 'package:message_ai/features/authentication/presentation/providers/user_lookup_provider.dart';
import 'package:message_ai/features/authentication/presentation/providers/user_providers.dart';

/// Settings page where users can manage their profile and preferences
/// Uses offline-first approach: updates local Drift database, syncs to Firestore in background
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _displayNameController;
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  static const Map<String, String> supportedLanguages = {
    'en': '🇺🇸 English',
    'es': '🇪🇸 Español',
    'fr': '🇫🇷 Français',
    'de': '🇩🇪 Deutsch',
    'it': '🇮🇹 Italiano',
    'pt': '🇵🇹 Português',
    'ru': '🇷🇺 Русский',
    'ja': '🇯🇵 日本語',
    'zh': '🇨🇳 中文',
    'ar': '🇸🇦 العربية',
  };

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(currentUserProvider);
    _displayNameController = TextEditingController(
      text: currentUser?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'User not found';
          _isSaving = false;
        });
        return;
      }

      final displayName = _displayNameController.text.trim();

      if (displayName.isEmpty) {
        setState(() {
          _errorMessage = 'Display name cannot be empty';
          _isSaving = false;
        });
        return;
      }

      if (displayName.length < 2) {
        setState(() {
          _errorMessage = 'Display name must be at least 2 characters';
          _isSaving = false;
        });
        return;
      }

      // Only update if changed
      if (displayName != currentUser.displayName) {
        final db = ref.read(databaseProvider);
        final writeQueue = ref.read(driftWriteQueueProvider);

        // Update Drift first (offline-first) via write queue
        // The queue ensures no database lock conflicts
        await writeQueue.enqueue(
          () => db.userDao.updateUser(
            currentUser.uid,
            UsersCompanion(name: Value(displayName)),
          ),
          debugLabel: 'Update display name: $displayName',
        );
        debugPrint('✅ Drift updated: displayName=$displayName');

        // Sync to Firebase Auth AND Firestore in background
        // Display name changes propagate via UserLookupProvider cache invalidation
        final updateUseCase = ref.read(updateUserProfileUseCaseProvider);
        final userRepository = ref.read(userRepositoryProvider);

        // Update both Firebase Auth and Firestore
        Future.wait([
          updateUseCase(displayName: displayName).then((result) {
            result.fold(
              (failure) => debugPrint('❌ Auth update failed: ${failure.message}'),
              (_) => debugPrint('✅ Firebase Auth updated'),
            );
          }),
          userRepository
              .updateUser(currentUser.copyWith(displayName: displayName))
              .then((result) {
                result.fold(
                  (failure) =>
                      debugPrint('❌ Firestore update failed: ${failure.message}'),
                  (_) => debugPrint('✅ Firestore updated'),
                );
              }),
        ]).then((_) {
          // Invalidate UserLookupProvider cache so UI fetches new name
          ref
              .read(userLookupCacheProvider.notifier)
              .invalidate(currentUser.uid);
          debugPrint('✅ UserLookup cache invalidated - new name will load');
        }).ignore();
      }

      if (mounted) {
        setState(() {
          _successMessage = 'Profile updated successfully!';
          _selectedImage = null;
          _isSaving = false;
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error saving changes: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save changes: $e';
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _changePreferredLanguage(String languageCode) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      return;
    }

    try {
      debugPrint('🌐 Changing language to: $languageCode');

      final db = ref.read(databaseProvider);
      final writeQueue = ref.read(driftWriteQueueProvider);

      // Update Drift database (offline-first) via write queue
      // The queue ensures no database lock conflicts
      await writeQueue.enqueue(
        () => db.userDao.updatePreferredLanguage(
          uid: currentUser.uid,
          languageCode: languageCode,
        ),
        debugLabel: 'Update preferred language: $languageCode',
      );
      debugPrint('✅ Drift updated: language=$languageCode');

      // Sync to Firestore in background
      final userRepository = ref.read(userRepositoryProvider);
      final updatedUser = currentUser.copyWith(preferredLanguage: languageCode);
      userRepository.updateUser(updatedUser).ignore();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Language preference updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error changing language: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getUserName(Object? user) {
    if (user == null) {
      return '';
    }
    // Handle both UserEntity (name) and Firebase User (displayName)
    if (user is UserEntity) {
      return user.name;
    } else if (user is firebase_auth.User) {
      return user.displayName ?? '';
    }
    return '';
  }

  String? _getUserPhoto(Object? user) {
    if (user == null) {
      return null;
    }
    // Handle both UserEntity (imageUrl) and Firebase User (photoURL)
    if (user is UserEntity) {
      return user.imageUrl;
    } else if (user is firebase_auth.User) {
      return user.photoURL;
    }
    return null;
  }

  String _getPreferredLanguage(Object? user) {
    if (user == null) {
      return 'en';
    }
    // Only UserEntity has preferredLanguage
    if (user is UserEntity) {
      return user.preferredLanguage;
    }
    return 'en';
  }

  String _getUserEmail(Object? user) {
    if (user == null) {
      return 'N/A';
    }
    if (user is UserEntity) {
      return user.email ?? 'N/A';
    } else if (user is firebase_auth.User) {
      return user.email ?? 'N/A';
    }
    return 'N/A';
  }

  String _getUserUID(Object? user) {
    if (user == null) {
      return '';
    }
    if (user is UserEntity) {
      return user.uid;
    } else if (user is firebase_auth.User) {
      return user.uid;
    }
    return '';
  }

  DateTime _getUserCreatedAt(Object? user) {
    if (user == null) {
      return DateTime.now();
    }
    if (user is UserEntity) {
      return user.createdAt;
    } else if (user is firebase_auth.User) {
      // Firebase User doesn't have createdAt, use metadata
      return user.metadata.creationTime ?? DateTime.now();
    }
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings'), elevation: 0),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Please sign in to access settings'),
          ),
        ),
      );
    }

    // Watch local Drift database for offline-first updates
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: StreamBuilder<UserEntity?>(
        stream: db.userDao.watchUser(currentUser.uid),
        builder: (context, snapshot) {
          // Handle connection states
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('❌ Stream error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Use local user from Drift if available, fallback to auth user
          // Drift UserEntity has properties like name, imageUrl, preferredLanguage, etc.
          final localUser = snapshot.data;
          final user = localUser ?? currentUser;

          // Update controller when stream emits new data
          final userName = _getUserName(user);
          if (_displayNameController.text != userName) {
            _displayNameController.text = userName;
          }

          // DEBUG: Log stream updates
          if (localUser != null) {
            debugPrint(
              '📱 SettingsPage StreamBuilder updated: preferredLanguage=${_getPreferredLanguage(user)}',
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Success message
                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: TextStyle(color: Colors.green.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Profile section
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Profile picture
                  Center(
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            child: _getUserPhoto(user) != null
                                ? ClipOval(
                                    child: Image.network(
                                      _getUserPhoto(user)!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.person,
                                                size: 60,
                                              ),
                                    ),
                                  )
                                : const Icon(Icons.person, size: 60),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Display name
                  TextField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      hintText: 'Enter your name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Preferences section
                  Text(
                    'Preferences',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Language dropdown
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferred Language for Translations',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Current: ${supportedLanguages[_getPreferredLanguage(user)] ?? _getPreferredLanguage(user)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _getPreferredLanguage(user),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: supportedLanguages.entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                              )
                              .toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _changePreferredLanguage(newValue);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account info
                  Text(
                    'Account Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoTile('Email', _getUserEmail(user)),
                  _buildInfoTile(
                    'User ID',
                    '${_getUserUID(user).substring(0, 8)}...',
                  ),
                  _buildInfoTile(
                    'Member Since',
                    _getUserCreatedAt(user).toLocal().toString().split(' ')[0],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(color: Colors.grey[600])),
      ],
    ),
  );
}
