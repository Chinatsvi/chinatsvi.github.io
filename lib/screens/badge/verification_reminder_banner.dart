import 'package:flutter/material.dart';
import '../profile/farmer_model.dart';
import 'renewal_payment_screen.dart';

class VerificationReminderBanner extends StatelessWidget {
  final FarmerModel farmer;

  const VerificationReminderBanner({required this.farmer, super.key});

  bool isPaymentExpired(DateTime? paidAt) {
    if (paidAt == null) return true;
    final now = DateTime.now();
    return now.difference(paidAt).inDays >= 30;
  }

  bool isPaymentExpiringSoon(DateTime? paidAt) {
    if (paidAt == null) return false;
    final now = DateTime.now();
    final daysUntilExpiry = 30 - now.difference(paidAt).inDays;
    return daysUntilExpiry <= 3 && daysUntilExpiry > 0;
  }

  int getDaysUntilExpiry(DateTime? paidAt) {
    if (paidAt == null) return 0;
    final now = DateTime.now();
    return 30 - now.difference(paidAt).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = getDaysUntilExpiry(farmer.verificationPaidAt);

    if (isPaymentExpired(farmer.verificationPaidAt)) {
      // Payment already expired
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Your verification badge has expired. Renew now to keep it active.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RenewalPaymentScreen(),
                  ),
                );
              },
              child: const Text('Renew'),
            ),
          ],
        ),
      );
    } else if (isPaymentExpiringSoon(farmer.verificationPaidAt)) {
      // Payment expiring in 3 days or less
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.timer,
              color: daysLeft <= 1 ? Colors.red : Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                daysLeft == 1
                    ? 'Your verification badge expires tomorrow! Renew now to keep your verified status.'
                    : 'Your verification badge expires in $daysLeft days. Renew now to keep your verified status.',
                style: TextStyle(
                  color: daysLeft <= 1 ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: daysLeft <= 1 ? Colors.red : Colors.orange,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RenewalPaymentScreen(),
                  ),
                );
              },
              child: const Text('Renew Now'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
