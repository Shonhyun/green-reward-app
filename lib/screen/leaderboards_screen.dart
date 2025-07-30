import 'package:flutter/material.dart';

class LeaderboardsScreen extends StatefulWidget {
  const LeaderboardsScreen({super.key});

  @override
  State<LeaderboardsScreen> createState() => _LeaderboardsScreenState();
}

class _LeaderboardsScreenState extends State<LeaderboardsScreen> {
  final List<Map<String, dynamic>> _leaderboardData = [
    {'name': 'Alonso', 'points': 54321, 'rank': 1},
    {'name': 'Teodora', 'points': 4321, 'rank': 2},
    {'name': 'Realonda', 'points': 321, 'rank': 3},
    {'name': 'Quintos', 'points': 21, 'rank': 4},
    {'name': 'Saturnina', 'points': 21, 'rank': 5},
    {'name': 'Hidalgo', 'points': 13, 'rank': 6},
    {'name': 'Paciano', 'points': 12, 'rank': 7},
    {'name': 'Jose', 'points': 11, 'rank': 8},
    {'name': 'Maria', 'points': 9, 'rank': 9},
    {'name': 'Pedro', 'points': 7, 'rank': 10},
  ];

  String _selectedFilter = 'month'; // 'year' or 'month'

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
                    const Icon(Icons.person_outline, color: Colors.white, size: 30),
                  ],
                ),
              ),
              
              // Leaderboards Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Text(
                  'Leaderboards',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                      prefixIcon: Icon(Icons.search, color: Colors.grey, size: 24),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                    ),
                  ),
                ),
              ),
              
              // Filter Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  children: [
                    _buildFilterButton('year'),
                    const SizedBox(width: 10),
                    _buildFilterButton('month'),
                  ],
                ),
              ),
              
              // Leaderboard List
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: _leaderboardData.map((data) {
                        return _buildLeaderboardItem(data);
                      }).toList(),
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

  Widget _buildFilterButton(String text) {
    final bool isSelected = _selectedFilter == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6A1B9A) : Colors.grey[300], // Purple for selected, light grey for unselected
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> data) {
    Color backgroundColor;
    Color textColor = Colors.black87;
    Color pointsColor = Colors.black87;

    switch (data['rank']) {
      case 1:
        backgroundColor = const Color(0xFFFFD700); // Gold
        pointsColor = Colors.black87;
        break;
      case 2:
        backgroundColor = const Color(0xFFADD8E6); // Light Blue
        pointsColor = Colors.black87;
        break;
      case 3:
        backgroundColor = const Color(0xFFFFA07A); // Light Salmon / Orange
        pointsColor = Colors.black87;
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Text(
            '${data['rank']}.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 18, color: Colors.black54),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              data['name'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          Text(
            '${data['points']} pts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: pointsColor,
            ),
          ),
        ],
      ),
    );
  }
}