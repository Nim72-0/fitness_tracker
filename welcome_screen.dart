// lib/screens/welcome_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart'; // For greeting and quotes
import '../services/auth_service.dart';
import '../services/shared_prefs_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _userName = '';
  String _userEmail = '';
  bool _isLoading = true;
  String _motivationalQuote = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadQuote();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('user_email');

      if (email != null && email.isNotEmpty) {
        _userEmail = email;

        final user = Provider.of<AuthService>(context, listen: false).currentUser;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            _userName = userDoc.data()?['name'] ?? 'Fitness Enthusiast';
          } else {
            _userName = prefs.getString('user_name') ?? 'Fitness Enthusiast';
          }
        } else {
          _userName = prefs.getString('user_name') ?? 'Fitness Enthusiast';
        }
      } else {
        _userName = prefs.getString('user_name') ?? 'Fitness Enthusiast';
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _userName = 'Fitness Enthusiast';
        _isLoading = false;
      });
    }
  }

  void _loadQuote() {
    _motivationalQuote = getDailyQuote();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  void _navigateToHome() async {
    final prefs = SharedPrefsService();
    await prefs.setFirstTime(false);
    await prefs.setShouldShowWelcome(false);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingScreen()
            : _buildWelcomeContent(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Preparing your journey...',
            style: AppText.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeContent() {
    final greeting = _getGreeting();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: _navigateToHome,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: Text(
                'Skip',
                style: AppText.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Center(
              child: Icon(
                Icons.emoji_emotions_outlined,
                size: 56,
                color: AppColors.white,
              ),
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Welcome,',
            style: AppText.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            _userName,
            style: AppText.displayMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          if (_userEmail.isNotEmpty)
            Text(
              _userEmail,
              style: AppText.body.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '"$_motivationalQuote"',
                  textAlign: TextAlign.center,
                  style: AppText.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your fitness journey starts now!',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Start Your Journey',
                    style: AppText.button,
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 22,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextButton(
            onPressed: _navigateToHome,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text(
              'Go to Dashboard',
              style: AppText.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              'Track your progress, achieve your goals',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}