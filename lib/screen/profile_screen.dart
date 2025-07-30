import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNumberController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  User? _user;
  String _uniqueId = '';
  int _userPoints = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _user = FirebaseAuth.instance.currentUser;
      if (_user == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
     
      // Get user data from Firestore
      final userData = await UserService.getCurrentUserData();
      final uniqueId = await UserService.getUserUniqueId();
      final points = await UserService.getUserPoints();
      
      if (mounted) {
        setState(() {
          // Use Firestore data instead of Firebase Auth displayName
          _firstNameController.text = userData?['firstName'] ?? '';
          _lastNameController.text = userData?['lastName'] ?? '';
          _emailController.text = _user!.email ?? '';
          _contactNumberController.text = userData?['contactNumber'] ?? '';
          _uniqueId = uniqueId;
          _userPoints = points;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_user != null) {
        // Save to Firestore
        await UserService.updateUserProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          contactNumber: _contactNumberController.text.trim(),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF43EA7D), // Vibrant light green
              Color(0xFF4CAF50), // Main green
              Color(0xFF388E3C), // Medium green
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
              // Account Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Text(
                  'Account',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Main Content Card
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_firstNameController.text} ${_lastNameController.text}'.trim().isEmpty 
                                  ? 'User' 
                                  : '${_firstNameController.text} ${_lastNameController.text}'.trim(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  : const Text(
                                      'SAVE',
                                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // User Unique ID
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F8FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE3F2FD)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.fingerprint, color: Color(0xFF2196F3), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Unique ID',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF666666),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _uniqueId,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF2196F3),
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // User Points
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE8F5E9)),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/coins.png',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Points',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF666666),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _userPoints.toString(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFF4CAF50),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Error Message
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        // Profile Image Placeholder
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300, width: 2),
                                ),
                                child: const Icon(Icons.person, size: 60, color: Colors.black54),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Upload Image',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // First Name Field
                        _buildProfileInputField('First Name', _firstNameController, 'Enter your first name'),
                        const SizedBox(height: 20),
                        // Last Name Field
                        _buildProfileInputField('Last Name', _lastNameController, 'Enter your last name'),
                        const SizedBox(height: 20),
                        // Email Field (Read-only)
                        _buildProfileInputField('Email', _emailController, 'Enter your email', enabled: false),
                        const SizedBox(height: 20),
                        // Contact Number Field
                        _buildProfileInputField('Contact Number', _contactNumberController, 'Enter your contact number'),
                        const SizedBox(height: 40),
                        // Sign Out Button
                        Align(
                          alignment: Alignment.bottomRight,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _signOut,
                            child: const Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInputField(String label, TextEditingController controller, String hint, {bool obscureText = false, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black54),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }
}