import 'package:flutter/material.dart';

// Stub service - Paystack removed
class PaystackService {
  void initialize() {
    // No-op - Paystack removed
  }

  Future<bool> charge({
    required BuildContext context,
    required String email,
    required int amount,
    required String reference,
  }) async {
    // Stub - always returns true
    // Replace with actual payment provider when ready
    return true;
  }
}
