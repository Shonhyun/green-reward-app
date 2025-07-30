import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  static Future<Map<String, dynamic>> createOrGetUser(User firebaseUser) async {
    final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
    final userSnapshot = await userDoc.get();

    if (!userSnapshot.exists) {
      // Create new user with unique ID and initial points
      final userData = {
        'uniqueId': generateUniqueId(),
        'email': firebaseUser.email,
        'displayName': firebaseUser.displayName ?? '',
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
} 