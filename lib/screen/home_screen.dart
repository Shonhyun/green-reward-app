import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userUsername;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh username when screen becomes active
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get username from Firestore
      final username = await UserService.getUserUsername();
      
      setState(() {
        _userUsername = username.isNotEmpty ? username : 'User';
        _isLoading = false;
      });
    } else {
      setState(() {
        _userUsername = 'User';
        _isLoading = false;
      });
    }
  }

  // Get real-time points stream
  Stream<int> _getPointsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return data['points'] ?? 0;
      }
      return 0;
    });
  }

  // Format points with commas for better readability
  String _formatPoints(int points) {
    return points.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
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
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        child: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
              // Welcome and Point Balance (Modern Card)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.30),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white.withValues(alpha: 0.22),
                                child: const Icon(Icons.eco, color: Color(0xFF4CAF50), size: 32),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome, ${_userUsername ?? 'User'}!',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Let\'s make a greener world!',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/coins.png',
                                  width: 30,
                                  height: 30,
                                ),
                                const SizedBox(width: 10),
                                StreamBuilder<int>(
                                  stream: _getPointsStream(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
                                      return const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF388E3C)),
                                        ),
                                      );
                                    }
                                    
                                    final points = snapshot.data ?? 0;
                                    return Text(
                                      _formatPoints(points),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF388E3C),
                                        letterSpacing: 0.5,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'points',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF388E3C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Main Content Grid
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchUserData,
                  color: const Color(0xFF4CAF50),
                child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Column(
                    children: [
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 18.0,
                        mainAxisSpacing: 18.0,
                        // Make tiles slightly taller on compact screens to avoid vertical overflow
                        childAspectRatio: _calculateChildAspectRatio(context),
                        children: [
                          _buildFeatureCard(context, 'Rewards', null, '/rewards', customIcon: 'assets/organic.png'),
                          _buildFeatureCard(context, 'Report Forum', Icons.chat_bubble_outline, '/report-forum'),
                          _buildFeatureCard(context, 'Leaderboards', null, '/leaderboards', customIcon: 'assets/podium.png'),
                          _buildFeatureCard(context, 'Transactions', null, '/transactions', customIcon: 'assets/transaction.png'),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, IconData? icon, String? routeName, {String? customIcon}) {
    return GestureDetector(
      onTap: routeName != null ? () => Navigator.pushNamed(context, routeName) : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth;
          // Scale values based on available width to keep the layout responsive
          final double verticalPadding = (cardWidth * 0.10).clamp(12.0, 20.0);
          final double iconSize = (cardWidth * 0.28).clamp(36.0, 56.0);
          final double gap = (cardWidth * 0.08).clamp(10.0, 18.0);
          final double fontSize = (cardWidth * 0.16).clamp(14.0, 20.0);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 18.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.80),
                  const Color(0xFFE8F5E9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4CAF50).withValues(alpha: 0.13),
                        const Color(0xFF2E7D32).withValues(alpha: 0.10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: EdgeInsets.all(iconSize * 0.32),
                  child: customIcon != null
                      ? Image.asset(customIcon, width: iconSize, height: iconSize)
                      : Icon(icon, size: iconSize, color: const Color(0xFF4CAF50)),
                ),
                SizedBox(height: gap),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF222222),
                      letterSpacing: 0.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Dynamically compute an aspect ratio that gives a bit more height on compact screens
  double _calculateChildAspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const crossAxisSpacing = 18.0;
    const horizontalPadding = 20.0 * 2; // from SingleChildScrollView padding
    const crossAxisCount = 2;

    final usableWidth = size.width - horizontalPadding - crossAxisSpacing;
    final itemWidth = usableWidth / crossAxisCount;

    // Make height slightly larger than width to comfortably fit icon + text
    final itemHeight = itemWidth * 1.15;
    final ratio = itemWidth / itemHeight; // width / height

    // Clamp to reasonable bounds to keep consistent on tablets/landscape
    return ratio.clamp(0.78, 1.0);
  }
}