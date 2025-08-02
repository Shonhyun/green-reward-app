import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Generate a unique user ID
  static String generateUniqueId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  // Create or get user document
  static Future<Map<String, dynamic>> createOrGetUser(User firebaseUser, {String? username}) async {
    final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
    final userSnapshot = await userDoc.get();

    if (!userSnapshot.exists) {
      // Create new user with unique ID and initial points
      final userData = {
        'uniqueId': generateUniqueId(),
        'email': firebaseUser.email,
        'displayName': firebaseUser.displayName ?? '',
        'username': username ?? '',
        'points': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'contactNumber': '',
        'firstName': '',
        'lastName': '',
      };

      await userDoc.set(userData);
      return userData;
    } else {
      // Update last login time for existing user
      await userDoc.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      return userSnapshot.data()!;
    }
  }

  // Get current user data
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.data();
  }

  // Update user points
  static Future<void> updateUserPoints(int points) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'points': points,
    });
  }

  // Update user profile
  static Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? contactNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updateData = <String, dynamic>{};
    if (firstName != null) updateData['firstName'] = firstName;
    if (lastName != null) updateData['lastName'] = lastName;
    if (contactNumber != null) updateData['contactNumber'] = contactNumber;

    if (updateData.isNotEmpty) {
      await _firestore.collection('users').doc(user.uid).update(updateData);
    }
  }

  // Get user points
  static Future<int> getUserPoints() async {
    final userData = await getCurrentUserData();
    return userData?['points'] ?? 0;
  }

  // Get user unique ID
  static Future<String> getUserUniqueId() async {
    final userData = await getCurrentUserData();
    return userData?['uniqueId'] ?? '';
  }

  // Get user username
  static Future<String> getUserUsername() async {
    final userData = await getCurrentUserData();
    return userData?['username'] ?? '';
  }

  // Deduct points for reward purchase
  static Future<bool> purchaseReward(int pointsCost, int quantity) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final userDoc = _firestore.collection('users').doc(user.uid);
    
    return await _firestore.runTransaction<bool>((transaction) async {
      final userSnapshot = await transaction.get(userDoc);
      final currentPoints = userSnapshot.data()?['points'] ?? 0;
      final totalCost = pointsCost * quantity;

      if (currentPoints >= totalCost) {
        transaction.update(userDoc, {
          'points': currentPoints - totalCost,
        });
        return true;
      }
      return false;
    });
  }

  // Test method to verify Firestore connection
  static Future<bool> testFirestoreConnection() async {
    try {
      debugPrint('Testing Firestore connection...');
      
      // Try to get a single document to test connection
      final testDoc = await _firestore.collection('users').limit(1).get();
      debugPrint('Firestore connection test successful. Found ${testDoc.docs.length} documents');
      return true;
    } catch (e) {
      debugPrint('Firestore connection test failed: $e');
      return false;
    }
  }

  // Get leaderboard data - top users by points
  static Future<List<Map<String, dynamic>>> getLeaderboardData({int limit = 50}) async {
    try {
      debugPrint('Fetching leaderboard data with limit: $limit');
      
      // Check if user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        return [];
      }
      
      debugPrint('User authenticated: ${user.uid}');
      
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('points', descending: true)
          .limit(limit)
          .get();

      debugPrint('Query returned ${querySnapshot.docs.length} documents');

      final List<Map<String, dynamic>> leaderboardData = [];
      int rank = 1;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        debugPrint('Document ${doc.id}: ${data.toString()}');
        
        // Better display name logic - prioritize username, then firstName, then displayName
        String displayName = 'Anonymous';
        if (data['username'] != null && data['username'].toString().isNotEmpty) {
          displayName = data['username'];
        } else if (data['firstName'] != null && data['firstName'].toString().isNotEmpty) {
          displayName = data['firstName'];
        } else if (data['displayName'] != null && data['displayName'].toString().isNotEmpty) {
          displayName = data['displayName'];
        }
        
        leaderboardData.add({
          'userId': doc.id,
          'name': displayName,
          'points': data['points'] ?? 0,
          'rank': rank,
          'username': data['username'] ?? '',
          'uniqueId': data['uniqueId'] ?? '',
        });
        rank++;
      }

      debugPrint('Processed ${leaderboardData.length} users for leaderboard');
      return leaderboardData;
    } catch (e) {
      debugPrint('Error fetching leaderboard data: $e');
      return [];
    }
  }

  // Get current user's rank
  static Future<int> getCurrentUserRank() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return -1;

      final userData = await getCurrentUserData();
      if (userData == null) return -1;

      final userPoints = userData['points'] ?? 0;

      // Count how many users have more points than current user
      final querySnapshot = await _firestore
          .collection('users')
          .where('points', isGreaterThan: userPoints)
          .get();

      return querySnapshot.docs.length + 1;
    } catch (e) {
      debugPrint('Error getting user rank: $e');
      return -1;
    }
  }
} 