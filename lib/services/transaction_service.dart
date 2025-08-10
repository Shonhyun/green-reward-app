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

    try {
      await _firestore.collection('transactions').add(transactionData);
      print('✅ Transaction created successfully: ${transactionData['transactionId']}');
    } catch (e) {
      print('❌ Error creating transaction: $e');
      rethrow;
    }
  }

  // Generate unique transaction ID
  static String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'TXN${timestamp.toString().substring(timestamp.toString().length - 8)}$random';
  }

  // Get user's transaction history with enhanced debugging
  static Stream<QuerySnapshot> getUserTransactions() {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ User not authenticated for transactions');
      return Stream.empty();
    }

    print('🔍 Fetching transactions for user: ${user.uid}');
    
    try {
      // First, let's test the connection and get a count
      _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .count()
          .get()
          .then((countSnapshot) {
        print('✅ Total transactions for user: ${countSnapshot.count}');
      }).catchError((error) {
        print('❌ Error getting transaction count: $error');
      });

      final query = _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true);
      
      print('📊 Query setup complete. Listening for transactions...');
      
      return query.snapshots().handleError((error) {
        print('❌ Error in transaction stream: $error');
        print('🔧 Error details: ${error.toString()}');
        return Stream.empty();
      }).map((snapshot) {
        print('📈 Received ${snapshot.docs.length} transactions');
        // Print each transaction for debugging
        for (var doc in snapshot.docs) {
          final data = doc.data();
          print('📋 Transaction: ${data['transactionId']} - ${data['rewardName']} - ${data['createdAt']}');
        }
        return snapshot;
      });
    } catch (e) {
      print('❌ Error setting up transaction stream: $e');
      return Stream.empty();
    }
  }

  // Alternative method to get transactions as a Future (for testing)
  static Future<List<Map<String, dynamic>>> getUserTransactionsAsList() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ User not authenticated for transactions');
      return [];
    }

    print('🔍 Fetching transactions as list for user: ${user.uid}');
    
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();
      
      final transactions = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['documentId'] = doc.id; // Add document ID for reference
        return data;
      }).toList();
      
      print('📈 Retrieved ${transactions.length} transactions as list');
      for (var transaction in transactions) {
        print('📋 Transaction: ${transaction['transactionId']} - ${transaction['rewardName']} - ${transaction['createdAt']}');
      }
      
      return transactions;
    } catch (e) {
      print('❌ Error getting transactions as list: $e');
      return [];
    }
  }

  // Test connection to Firestore
  static Future<bool> testFirestoreConnection() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user for connection test');
        return false;
      }

      print('🔍 Testing Firestore connection for user: ${user.uid}');
      
      // Test basic read access
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        print('✅ User document access successful');
      } else {
        print('⚠️ User document does not exist');
      }

      // Test transaction collection access
      final transactionQuery = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      
      print('✅ Transaction collection access successful. Found ${transactionQuery.docs.length} transactions');
      
      return true;
    } catch (e) {
      print('❌ Firestore connection test failed: $e');
      return false;
    }
  }

  // Get transaction by ID
  static Future<Map<String, dynamic>?> getTransactionById(String transactionId) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('transactionId', isEqualTo: transactionId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print('Error getting transaction by ID: $e');
      return null;
    }
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
    
    try {
      // Check if user has enough points
      final currentPoints = await UserService.getUserPoints();
      if (currentPoints < totalCost) {
        return {'success': false, 'message': 'Insufficient points'};
      }

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

  // Get transaction count for user
  static Future<int> getUserTransactionCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .count()
          .get();
      
      return querySnapshot.count ?? 0;
    } catch (e) {
      print('Error getting transaction count: $e');
      return 0;
    }
  }
} 