import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/user.dart';
import '../../../services/image_upload_service.dart';
import '../../../state/auth_provider.dart';
import '../../../state/providers.dart';
import '../../theme/spacing.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  Gender _selectedGender = Gender.preferNotToSay;
  final _homeAddressController = TextEditingController();
  final _workAddressController = TextEditingController();
  bool _preferFemaleOnly = false;
  bool _isSocialLogin = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    print('🔵 ProfileSetupScreen: initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final firebaseUser = ref
          .read(firebaseAuthServiceProvider)
          .currentFirebaseUser;

      print('🔵 ProfileSetupScreen: Firebase user: ${firebaseUser?.email}');

      if (firebaseUser != null) {
        // Pre-populate email
        if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
          _emailController.text = firebaseUser.email!;
          _isSocialLogin = true;
          print(
            '🔵 ProfileSetupScreen: Email pre-populated: ${firebaseUser.email}',
          );
        }

        // Pre-populate name from Google Sign-In
        if (firebaseUser.displayName != null &&
            firebaseUser.displayName!.isNotEmpty) {
          _nameController.text = firebaseUser.displayName!;
          print(
            '🔵 ProfileSetupScreen: Name pre-populated: ${firebaseUser.displayName}',
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _homeAddressController.dispose();
    _workAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () async {
            if (_currentStep < 1) {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  _currentStep++;
                });
              }
            } else {
              if (!_formKey.currentState!.validate()) return;

              // Complete setup and login
              final authService = ref.read(firebaseAuthServiceProvider);
              final firestoreService = ref.read(firestoreServiceProvider);
              final firebaseUser = authService.currentFirebaseUser;

              if (firebaseUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: No authenticated user found'),
                  ),
                );
                return;
              }

              try {
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                // Upload profile image if selected
                String? profileImageUrl;
                if (_selectedImage != null) {
                  print('📤 Uploading profile image...');
                  final imageUploadService = ImageUploadService();
                  profileImageUrl = await imageUploadService.uploadProfileImage(
                    _selectedImage!,
                    firebaseUser.uid,
                  );
                  print('✅ Profile image uploaded: $profileImageUrl');
                }

                // Create a fresh user object - NO MOCK DATA INHERITANCE
                final newUser = User(
                  id: firebaseUser.uid,
                  name: _nameController.text.trim(),
                  email: _emailController.text.trim(),
                  phone: firebaseUser.phoneNumber ?? '',
                  gender: _selectedGender,
                  homeAddress: _homeAddressController.text.trim(),
                  workAddress: _workAddressController.text.trim(),
                  preferFemaleOnlyRides: _preferFemaleOnly,
                  phoneVerified: firebaseUser.phoneNumber != null,
                  emailVerified: firebaseUser.emailVerified,
                  role: UserRole.both, // Default to both for flexibility
                  rating: 5.0, // Start new users with 5 stars
                  totalRides: 0,
                  totalRidesAsDriver: 0,
                  verificationStatus: VerificationStatus.none,
                  verificationLevel: VerificationLevel.none,
                  profileImageUrl: profileImageUrl, // Add uploaded image
                  avatarUrl:
                      profileImageUrl, // Also set avatarUrl for compatibility
                );

                // Save to Firestore
                await firestoreService.createDocument(
                  collection: 'users',
                  docId: newUser.id,
                  data: newUser.toMap(),
                );

                // Close loading
                if (mounted) Navigator.pop(context);

                // Update local auth state
                ref.read(authProvider.notifier).login(newUser);

                if (mounted) {
                  context.go('/home');
                }
              } catch (e) {
                // Close loading if open
                if (mounted) Navigator.pop(context);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving profile: $e')),
                  );
                }
              }
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep--;
              });
            }
          },
          steps: [
            Step(
              title: const Text('Basic Info'),
              isActive: _currentStep >= 0,
              content: Column(
                children: [
                  // Profile photo placeholder
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : null,
                          child: _selectedImage == null
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: Spacing.md),

                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      _selectedImage == null ? 'Add Photo' : 'Change Photo',
                    ),
                  ),

                  const SizedBox(height: Spacing.xl),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: Spacing.lg),

                  TextFormField(
                    controller: _emailController,
                    enabled: !_isSocialLogin,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: Spacing.lg),

                  DropdownButtonFormField<Gender>(
                    initialValue: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.people_outline),
                    ),
                    items: const [
                      DropdownMenuItem(value: Gender.male, child: Text('Male')),
                      DropdownMenuItem(
                        value: Gender.female,
                        child: Text('Female'),
                      ),
                      DropdownMenuItem(
                        value: Gender.preferNotToSay,
                        child: Text('Prefer not to say'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Commute Preferences'),
              isActive: _currentStep >= 1,
              content: Column(
                children: [
                  TextFormField(
                    controller: _homeAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Home Address',
                      hintText: 'Where do you live?',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),

                  const SizedBox(height: Spacing.lg),

                  TextFormField(
                    controller: _workAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Work/College Address',
                      hintText: 'Where do you go?',
                      prefixIcon: Icon(Icons.work_outline),
                    ),
                  ),

                  const SizedBox(height: Spacing.lg),

                  if (_selectedGender == Gender.female)
                    SwitchListTile(
                      title: const Text('Prefer female-only rides'),
                      subtitle: const Text('Show female-only rides by default'),
                      value: _preferFemaleOnly,
                      onChanged: (value) {
                        setState(() {
                          _preferFemaleOnly = value;
                        });
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to pick image from gallery or camera
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Profile Photo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Spacing.lg),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 85,
                );
                if (pickedFile != null) {
                  setState(() {
                    _selectedImage = File(pickedFile.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 85,
                );
                if (pickedFile != null) {
                  setState(() {
                    _selectedImage = File(pickedFile.path);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
