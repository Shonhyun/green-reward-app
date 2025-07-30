import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class TransactionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new transaction record
  static Future<void> createTransaction({
    required String rewardName,
    required int pointsCost,
    required int quantity,
    required String rewardImage,
    required String rewardDescription,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final transactionData = {
      'userId': user.uid,
      'rewardName': rewardName,
      'pointsCost': pointsCost,
      'quantity': quantity,
      'totalCost': pointsCost * quantity,
      'rewardImage': rewardImage,
      'rewardDescription': rewardDescription,
      'transactionType': 'purchase',
      'status': 'completed',
      'createdAt': FieldValue.serverTimestamp(),
      'transactionId': _generateTransactionId(),
    };

    await _firestore.collection('transactions').add(transactionData);
  }

  // Generate unique transaction ID
  static String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'TXN${timestamp.toString().substring(timestamp.toString().length - 8)}$random';
  }

  // Get user's transaction history
  static Stream<QuerySnapshot> getUserTransactions() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get transaction by ID
  static Future<Map<String, dynamic>?> getTransactionById(String transactionId) async {
    final querySnapshot = await _firestore
        .collection('transactions')
        .where('transactionId', isEqualTo: transactionId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    }
    return null;
  }

  // Purchase reward with transaction recording
  static Future<Map<String, dynamic>> purchaseReward({
    required String rewardName,
    required int pointsCost,
    required int quantity,
    required String rewardImage,
    required String rewardDescription,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return {'success': false, 'message': 'User not authenticated'};
    }

    final totalCost = pointsCost * quantity;
    
    // Check if user has enough points
    final currentPoints = await UserService.getUserPoints();
    if (currentPoints < totalCost) {
      return {'success': false, 'message': 'Insufficient points'};
    }

    try {
      // Deduct points from user account
      final success = await UserService.purchaseReward(pointsCost, quantity);
      
      if (success) {
        try {
          // Create transaction record
          await createTransaction(
            rewardName: rewardName,
            pointsCost: pointsCost,
            quantity: quantity,
            rewardImage: rewardImage,
            rewardDescription: rewardDescription,
          );

          return {
            'success': true,
            'message': 'Purchase successful',
            'transactionId': _generateTransactionId(),
            'totalCost': totalCost,
            'newBalance': currentPoints - totalCost,
          };
        } catch (transactionError) {
          // If transaction recording fails, we should still consider the purchase successful
          // since points were already deducted
          print('Transaction recording failed: $transactionError');
          
          return {
            'success': true,
            'message': 'Purchase successful (transaction record failed)',
            'transactionId': _generateTransactionId(),
            'totalCost': totalCost,
            'newBalance': currentPoints - totalCost,
          };
        }
      } else {
        return {'success': false, 'message': 'Purchase failed'};
      }
    } catch (e) {
      print('Purchase error: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
} 