// lib/screens/profile_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart'; 

import '../providers/profile_provider.dart';
import '../utils/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  String? _selectedGender;
  String? _selectedGoal;

  @override
  void initState() {
    super.initState();
    final profileProvider = context.read<ProfileProvider>();
    _nameController = TextEditingController(text: profileProvider.name);
    _ageController = TextEditingController(text: profileProvider.age.toString());
    _heightController = TextEditingController(text: profileProvider.height.toString());
    _weightController = TextEditingController(text: profileProvider.weight.toString());
    _selectedGender = profileProvider.gender;
    _selectedGoal = profileProvider.goal;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!kIsWeb) {
      var cameraStatus = await Permission.camera.request();
      var photosStatus = await Permission.photos.request();
      
      if (!cameraStatus.isGranted && !photosStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Camera and gallery permissions are required'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null && mounted) {
      final profileProvider = context.read<ProfileProvider>();
      await profileProvider.updateProfileImage(pickedFile);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final profileProvider = context.read<ProfileProvider>();
      
      FocusScope.of(context).unfocus();

      final errorMsg = await profileProvider.updateProfile(
        name: _nameController.text,
        age: int.parse(_ageController.text),
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        gender: _selectedGender!,
        goal: _selectedGoal!,
      );

      if (mounted) {
        if (errorMsg == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Your Profile',
          style: AppText.headlineMedium.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.appBarBackground,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 3),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.surfaceVariant,
                            backgroundImage: provider.profileImageUrl != null
                                ? NetworkImage(provider.profileImageUrl!)
                                : (provider.profileImage != null && !kIsWeb)
                                    ? FileImage(File(provider.profileImage!.path)) as ImageProvider
                                    : null,
                            child: provider.profileImageUrl == null && provider.profileImage == null
                                ? Icon(Icons.person, size: 60, color: AppColors.textMuted)
                                : (provider.profileImage != null && kIsWeb)
                                    ? ClipOval(
                                        child: Image.network(
                                          provider.profileImage!.path,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(Icons.person, size: 60, color: AppColors.textMuted),
                                        ),
                                      )
                                    : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.white, width: 2),
                                boxShadow: AppTheme.smallShadow,
                              ),
                              child: Icon(Icons.camera_alt, color: AppColors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'Personal Information',
                    style: AppText.headlineSmall.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: AppTheme.cardShadow,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            style: AppText.body.copyWith(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              labelStyle: AppText.label.copyWith(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
                            ),
                            validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _ageController,
                                  style: AppText.body.copyWith(color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    labelText: 'Age',
                                    labelStyle: AppText.label.copyWith(color: AppColors.textSecondary),
                                    prefixIcon: Icon(Icons.calendar_today, color: AppColors.textSecondary),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surfaceVariant,
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value!.isEmpty) return 'Required';
                                    final num = int.tryParse(value);
                                    return num == null || num <= 0 ? 'Invalid' : null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedGender,
                                  dropdownColor: AppColors.surface,
                                  style: AppText.body.copyWith(color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    labelText: 'Gender',
                                    labelStyle: AppText.label.copyWith(color: AppColors.textSecondary),
                                    prefixIcon: Icon(Icons.people_outline, color: AppColors.textSecondary),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surfaceVariant,
                                  ),
                                  items: ['Male', 'Female', 'Other']
                                      .map((label) => DropdownMenuItem(
                                            value: label,
                                            child: Text(label, style: AppText.body),
                                          ))
                                      .toList(),
                                  onChanged: (value) => setState(() => _selectedGender = value),
                                  validator: (value) => value == null ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Body Statistics',
                    style: AppText.headlineSmall.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: AppTheme.cardShadow,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              style: AppText.body.copyWith(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Height (cm)',
                                labelStyle: AppText.label.copyWith(color: AppColors.textSecondary),
                                prefixIcon: Icon(Icons.height, color: AppColors.textSecondary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value!.isEmpty) return 'Required';
                                final num = double.tryParse(value);
                                return num == null || num <= 0 ? 'Invalid' : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              style: AppText.body.copyWith(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Weight (kg)',
                                labelStyle: AppText.label.copyWith(color: AppColors.textSecondary),
                                prefixIcon: Icon(Icons.monitor_weight_outlined, color: AppColors.textSecondary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value!.isEmpty) return 'Required';
                                final num = double.tryParse(value);
                                return num == null || num <= 0 ? 'Invalid' : null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Your Goal',
                    style: AppText.headlineSmall.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: AppTheme.cardShadow,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: ['weight_loss', 'weight_gain', 'maintenance', 'muscle_gain'].contains(_selectedGoal) 
                            ? _selectedGoal 
                            : 'maintenance',
                        dropdownColor: AppColors.surface,
                        style: AppText.body.copyWith(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Select Fitness Goal',
                          labelStyle: AppText.label.copyWith(color: AppColors.textSecondary),
                          prefixIcon: Icon(Icons.flag_outlined, color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'weight_loss',
                            child: Text('Weight Loss', style: AppText.body),
                          ),
                          DropdownMenuItem(
                            value: 'weight_gain',
                            child: Text('Weight Gain', style: AppText.body),
                          ),
                          DropdownMenuItem(
                            value: 'maintenance',
                            child: Text('Maintenance', style: AppText.body),
                          ),
                          DropdownMenuItem(
                            value: 'muscle_gain',
                            child: Text('Muscle Gain', style: AppText.body),
                          ),
                        ],
                        onChanged: (value) => setState(() => _selectedGoal = value),
                        validator: (value) => value == null ? 'Please select a goal' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        elevation: 4,
                      ),
                      child: provider.isSaving
                          ? SizedBox(
                              height: 24, 
                              width: 24, 
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Save Profile',
                              style: AppText.button,
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}