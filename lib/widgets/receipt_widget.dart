import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class ReceiptWidget extends StatelessWidget {
  final Map<String, dynamic> transactionData;
  final VoidCallback onClose;

  const ReceiptWidget({
    super.key,
    required this.transactionData,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = transactionData['rewardImage'] ?? '';
    final rewardName = transactionData['rewardName'] ?? 'Unknown Reward';
    final quantity = transactionData['quantity'] ?? 1;
    final pointsCost = transactionData['pointsCost'] ?? 0;
    final totalCost = transactionData['totalCost'] ?? 0;
    final transactionId = transactionData['transactionId'] ?? '';
    final createdAt = transactionData['createdAt'] as Timestamp?;
    final date = createdAt?.toDate() ?? DateTime.now();
    
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.width < 350;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          // Modern Header with Success Animation
          Container(
            padding: EdgeInsets.all(isSmallScreen ? (isVerySmallScreen ? 16 : 20) : 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: isSmallScreen ? 24 : 28,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchase Successful!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? (isVerySmallScreen ? 16 : 18) : 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          decoration: TextDecoration.none,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your order has been confirmed',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: isSmallScreen ? 18 : 20,
                    ),
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  ),
                ),
              ],
            ),
          ),
          
          // Fixed Height Content - No Scrolling
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? (isVerySmallScreen ? 12 : 16) : 24),
              child: Column(
                children: [
                  // Product Section with Enhanced Design
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF8F9FA),
                          const Color(0xFFE9ECEF).withOpacity(0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE9ECEF),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Enhanced Product Image
                        Container(
                          width: isSmallScreen ? 60 : 70,
                          height: isSmallScreen ? 60 : 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: imageUrl.startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(imageUrl.split(',')[1]),
                                    width: isSmallScreen ? 60 : 70,
                                    height: isSmallScreen ? 60 : 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: isSmallScreen ? 60 : 70,
                                      height: isSmallScreen ? 60 : 70,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE9ECEF),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.image, 
                                        color: const Color(0xFF6C757D), 
                                        size: isSmallScreen ? 24 : 28
                                      ),
                                    ),
                                  )
                                : Image.network(
                                    imageUrl,
                                    width: isSmallScreen ? 60 : 70,
                                    height: isSmallScreen ? 60 : 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: isSmallScreen ? 60 : 70,
                                      height: isSmallScreen ? 60 : 70,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE9ECEF),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.image, 
                                        color: const Color(0xFF6C757D), 
                                        size: isSmallScreen ? 24 : 28
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 20),
                        
                        // Enhanced Product Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rewardName,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? (isVerySmallScreen ? 14 : 16) : 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF212529),
                                  letterSpacing: 0.3,
                                  decoration: TextDecoration.none,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isSmallScreen ? 8 : 12),
                              Wrap(
                                spacing: isSmallScreen ? 6 : 10,
                                runSpacing: isSmallScreen ? 4 : 6,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 8 : 10, 
                                      vertical: isSmallScreen ? 4 : 6
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      'Qty: $quantity',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 11 : 13,
                                        color: const Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.none,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 8 : 10, 
                                      vertical: isSmallScreen ? 4 : 6
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF2196F3).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '${pointsCost} pts each',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 11 : 13,
                                        color: const Color(0xFF1976D2),
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.none,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Compact Transaction Details
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF8F9FA),
                          const Color(0xFFE9ECEF).withOpacity(0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE9ECEF),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildCompactDetailRow('Transaction ID', transactionId, isHighlighted: true, isSmallScreen: isSmallScreen),
                        const SizedBox(height: 8),
                        _buildCompactDetailRow('Date & Time', '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}', isSmallScreen: isSmallScreen),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Enhanced Total Amount Section
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Paid',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2E7D32),
                                  decoration: TextDecoration.none,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Points deducted',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  color: const Color(0xFF4CAF50),
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.none,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16, 
                            vertical: isSmallScreen ? 8 : 10
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            '$totalCost pts',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              decoration: TextDecoration.none,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Close Button - No Underline
                  SizedBox(
                    width: double.infinity,
                    height: isSmallScreen ? 48 : 52,
                    child: ElevatedButton(
                      onPressed: onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
                        // Remove any underline
                        textStyle: const TextStyle(
                          decoration: TextDecoration.none,
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDetailRow(String label, String value, {bool isHighlighted = false, required bool isSmallScreen}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 13,
              color: isHighlighted ? const Color(0xFF495057) : const Color(0xFF6C757D),
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
              decoration: TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 10, 
              vertical: isSmallScreen ? 3 : 4
            ),
            decoration: BoxDecoration(
              color: isHighlighted ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isHighlighted ? Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)) : null,
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 13,
                fontWeight: FontWeight.w600,
                color: isHighlighted ? const Color(0xFF4CAF50) : const Color(0xFF212529),
                decoration: TextDecoration.none,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ),
      ],
    );
  }
} 