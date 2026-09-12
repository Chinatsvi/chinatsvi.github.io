import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? parseVerificationDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

DateTime? resolveVerificationExpiryDate(Map<String, dynamic>? userData) {
  if (userData == null) return null;

  final expiresAtRaw = userData['verificationExpiresAt'];
  final expiresAt = parseVerificationDate(expiresAtRaw);
  if (expiresAt != null) return expiresAt;

  final paidAtRaw = userData['verificationPaidAt'] ?? userData['verificationPaidat'];
  final paidAt = parseVerificationDate(paidAtRaw);
  if (paidAt == null) return null;

  return paidAt.add(const Duration(days: 30));
}

bool isVerificationPaymentExpired(dynamic paidAtRaw) {
  final paidAt = parseVerificationDate(paidAtRaw);
  if (paidAt == null) return true;

  final expiryDate = paidAt.add(const Duration(days: 30));
  return !DateTime.now().isBefore(expiryDate);
}

bool isVerificationExpiredFromMap(Map<String, dynamic>? userData) {
  if (userData == null) return true;

  final expiryDate = resolveVerificationExpiryDate(userData);
  if (expiryDate == null) return true;

  return !DateTime.now().isBefore(expiryDate);
}

bool shouldShowVerificationTick(Map<String, dynamic>? userData) {
  if (userData == null) return false;

  final isVerified = userData['isVerified'] == true;
  final verificationStatus = (userData['verificationStatus'] ?? '').toString().trim();
  final verificationPaid = userData['verificationPaid'] == true;

  if (!isVerified || verificationStatus != 'approved' || !verificationPaid) {
    return false;
  }

  return !isVerificationExpiredFromMap(userData);
}
