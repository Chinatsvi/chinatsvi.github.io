import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemStatus { active, sold, removed }

class MarketplaceItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final bool negotiable;
  final bool isDiscreet;
  final List<String> images;
  final String sellerId;
  final String sellerName;
  final ItemStatus status;
  final DateTime createdAt;
  final double rating;
  final int reviewsCount;
  final bool isBoosted;
  final DateTime? boostExpiresAt;
  final String? locationTag;
  final String? currencySymbol;

  MarketplaceItem({
    String? id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.negotiable,
    this.isDiscreet = false,
    required this.images,
    required this.sellerId,
    required this.sellerName,
    this.status = ItemStatus.active,
    DateTime? createdAt,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.isBoosted = false,
    this.boostExpiresAt,
    this.locationTag,
    this.currencySymbol,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  /// Copy with updated fields
  MarketplaceItem copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? category,
    bool? negotiable,
    bool? isDiscreet,
    List<String>? images,
    String? sellerId,
    String? sellerName,
    ItemStatus? status,
    DateTime? createdAt,
    double? rating,
    int? reviewsCount,
    bool? isBoosted,
    DateTime? boostExpiresAt,
    String? locationTag,
    String? currencySymbol,
  }) {
    return MarketplaceItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      negotiable: negotiable ?? this.negotiable,
      isDiscreet: isDiscreet ?? this.isDiscreet,
      images: images ?? this.images,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      isBoosted: isBoosted ?? this.isBoosted,
      boostExpiresAt: boostExpiresAt ?? this.boostExpiresAt,
      locationTag: locationTag ?? this.locationTag,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  /// Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'negotiable': negotiable,
      'isDiscreet': isDiscreet,
      'images': images,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'rating': rating,
      'reviewsCount': reviewsCount,
      'isBoosted': isBoosted,
      'boostExpiresAt': boostExpiresAt != null
          ? Timestamp.fromDate(boostExpiresAt!)
          : null,
      'locationTag': locationTag,
      'currencySymbol': currencySymbol,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  /// Create item from Firestore document snapshot (safe for streams)
  factory MarketplaceItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MarketplaceItem.fromMap(data);
  }

  /// Create item from Map
  factory MarketplaceItem.fromMap(Map<String, dynamic> map) {
    // Helper parsers
    bool parseBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase().trim();
        return s == 'true' || s == '1' || s == 'yes';
      }
      return false;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '')) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String)
        return int.tryParse(v) ?? (double.tryParse(v)?.toInt() ?? 0);
      return 0;
    }

    List<String> parseImages(Map<String, dynamic> m) {
      final cand =
          m['images'] ?? m['imageUrls'] ?? m['photos'] ?? m['photos_urls'];
      if (cand is List)
        return cand
            .map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      return [];
    }

    dynamic boostRaw =
        map['boostExpiresAt'] ??
        map['boost_expires_at'] ??
        map['boostEndDate'] ??
        map['boost_end_date'] ??
        map['expiresAt'] ??
        map['expires_at'] ??
        map['endDate'] ??
        map['end_date'] ??
        map['boostExpireDate'] ??
        map['boost_expire_date'] ??
        map['boostEnd'] ??
        map['boost_end'] ??
        map['expiryDate'] ??
        map['expiry_date'];
    DateTime? boostDate;
    if (boostRaw is Timestamp) {
      boostDate = boostRaw.toDate();
    } else if (boostRaw is DateTime) {
      boostDate = boostRaw;
    } else if (boostRaw is int) {
      boostDate = boostRaw > 100000000000
          ? DateTime.fromMillisecondsSinceEpoch(boostRaw)
          : DateTime.fromMillisecondsSinceEpoch(boostRaw * 1000);
    } else if (boostRaw is double) {
      final intVal = boostRaw.toInt();
      boostDate = intVal > 100000000000
          ? DateTime.fromMillisecondsSinceEpoch(intVal)
          : DateTime.fromMillisecondsSinceEpoch(intVal * 1000);
    } else if (boostRaw is Map) {
      final seconds = boostRaw['_seconds'] ?? boostRaw['seconds'];
      if (seconds is num) {
        final nanoseconds =
            boostRaw['_nanoseconds'] ?? boostRaw['nanoseconds'] ?? 0;
        boostDate = Timestamp(
          seconds.toInt(),
          (nanoseconds as num).toInt(),
        ).toDate();
      }
    } else if (boostRaw is String) {
      boostDate = DateTime.tryParse(boostRaw);
    }

    final price = parseDouble(
      map['price'] ?? map['amount'] ?? map['price_str'],
    );
    final ratingVal = parseDouble(
      map['rating'] ?? map['sellerRating'] ?? map['rating_score'],
    );
    final images = parseImages(map);

    return MarketplaceItem(
      id: map['id'] ?? const Uuid().v4(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: price,
      category: map['category'] ?? 'General',
      negotiable: parseBool(
        map['negotiable'] ?? map['isNegotiable'] ?? map['negotiable_flag'],
      ),
      isDiscreet: parseBool(map['isDiscreet'] ?? map['is_discreet']),
      images: images,
      sellerId:
          map['sellerId'] ??
          map['seller_id'] ??
          map['vendorId'] ??
          map['vendor_id'] ??
          map['userId'] ??
          map['user_id'] ??
          '',
      sellerName:
          map['sellerName'] ??
          map['seller_name'] ??
          map['vendorName'] ??
          map['vendor_name'] ??
          map['user_name'] ??
          map['name'] ??
          '',
      status: _statusFromString(map['status']),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['created_at'] is String
                ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
                : DateTime.now()),
      rating: ratingVal,
      reviewsCount: parseInt(
        map['reviewsCount'] ?? map['reviews_count'] ?? map['reviews'],
      ),
      isBoosted: parseBool(
        map['isBoosted'] ?? map['is_boosted'] ?? map['boosted'] ?? map['boost'],
      ),
      boostExpiresAt: boostDate,
      locationTag:
          map['locationTag'] ??
          map['location_tag'] ??
          (map['location'] is String ? map['location'] as String : null),
      currencySymbol:
          (map['currencySymbol'] ??
                  map['currency'] ??
                  map['currencyCode'] ??
                  '')
              .toString()
              .trim()
              .isEmpty
          ? null
          : (map['currencySymbol'] ?? map['currency'] ?? map['currencyCode'])
                .toString(),
    );
  }

  /// Helper: convert string to ItemStatus
  static ItemStatus _statusFromString(String? status) {
    switch (status?.trim().toLowerCase()) {
      case 'sold':
        return ItemStatus.sold;
      case 'removed':
        return ItemStatus.removed;
      case 'active':
      default:
        return ItemStatus.active;
    }
  }

  /// Determine the listing status after a purchase.
  /// Discreet items should stop appearing for sale once bought, while normal
  /// listings should remain active so they continue to be visible.
  static ItemStatus resolveStatusAfterPurchase({required bool isDiscreet}) {
    return isDiscreet ? ItemStatus.sold : ItemStatus.active;
  }

  /// Create item from JSON
  factory MarketplaceItem.fromJson(Map<String, dynamic> json) =>
      MarketplaceItem.fromMap(json);
}
