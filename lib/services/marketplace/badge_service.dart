import 'package:agribased/services/firestore_service.dart';

abstract class IBadgeService {
  Future<String?> computeBadgeForSeller(String sellerId);
}

class BadgeService implements IBadgeService {
  final FirestoreService _firestore = FirestoreService();

  @override
  Future<String?> computeBadgeForSeller(String sellerId) async {
    try {
      // Get the first batch of items (stream will complete after first emission)
      final items = await _firestore
          .streamMarketplaceItemsByUser(sellerId)
          .first;

      final totalSales = items.fold<int>(
        0,
        (sum, item) => sum + (item.reviewsCount),
      );

      if (totalSales >= 100) return 'gold';
      if (totalSales >= 50) return 'silver';
      if (totalSales >= 10) return 'bronze';
      return 'new';
    } catch (e) {
      return null;
    }
  }
}
