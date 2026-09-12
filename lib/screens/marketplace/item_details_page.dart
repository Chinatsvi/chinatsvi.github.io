import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/models/marketplace/marketplace_item_model.dart';
import 'package:agribased/services/marketplace/cart_service.dart';
import 'package:agribased/services/marketplace/order_service.dart';
import 'package:agribased/services/marketplace/marketplace_service.dart';
import 'package:agribased/services/marketplace/firebase_marketplace_service.dart';
import 'package:agribased/services/cloudinary_image_upload_service.dart';
import 'package:agribased/screens/chat/chat_screen.dart';
import 'package:agribased/screens/marketplace/checkout_screen.dart';
import 'package:agribased/screens/marketplace/cart_screen.dart';
import 'package:agribased/screens/marketplace/edit_item_page.dart';
import 'package:agribased/screens/marketplace/report_item_page.dart';
import 'package:agribased/screens/marketplace/boost_listing_page.dart';
import 'package:agribased/screens/location_screen.dart';
import 'package:agribased/screens/profile/farmer_model.dart';
import 'package:agribased/screens/profile/farmer_profile_screen.dart';
import 'package:agribased/app/utils/formatters.dart';
import 'package:agribased/utils/verification_helpers.dart';
import 'package:agribased/widgets/user_info_display.dart';
import 'fullscreen_image_page.dart';

String _getChatId(String uid1, String uid2) {
  final ids = [uid1, uid2]..sort();
  return ids.join('_');
}

class ItemDetailsPage extends StatefulWidget {
  final MarketplaceItem item;
  final CartService cartService;
  final OrderService orderService;
  final MarketplaceService marketplaceService;
  final CloudinaryImageUploadService imageUploadService;

  ItemDetailsPage({
    super.key,
    required this.item,
    CartService? cartService,
    OrderService? orderService,
    MarketplaceService? marketplaceService,
    CloudinaryImageUploadService? imageUploadService,
  }) : cartService = cartService ?? CartService(),
       orderService = orderService ?? OrderService(),
       marketplaceService =
           marketplaceService ?? FirebaseMarketplaceService.instance,
       imageUploadService =
           imageUploadService ?? CloudinaryImageUploadService();

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  FarmerModel? _seller;
  Map<String, dynamic>? _sellerData;
  Map<String, dynamic>? _fullItemData;

  // Method to navigate to location screen
  void _navigateToLocation() {
    if (widget.item.locationTag != null &&
        widget.item.locationTag!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LocationScreen(locationName: widget.item.locationTag),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
    _loadFullItemData();
  }

  Future<void> _loadFullItemData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Marketplace')
          .doc(widget.item.id)
          .get();

      if (doc.exists) {
        setState(() {
          _fullItemData = doc.data();
        });
      }
    } catch (e) {
      debugPrint('Error loading full item data: $e');
    }
  }

  Future<void> _loadSellerProfile() async {
    try {
      debugPrint(
        'DEBUG: Loading seller profile for sellerId: ${widget.item.sellerId}',
      );

      // Get raw document data to access verification fields
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(widget.item.sellerId)
          .get();

      if (!doc.exists) {
        debugPrint('DEBUG: Seller document does not exist');
        return;
      }
      if (!mounted) return;

      _sellerData = doc.data() as Map<String, dynamic>;
      debugPrint('DEBUG: Seller data: $_sellerData');
      debugPrint(
        'DEBUG: Seller name from profile: ${_sellerData!['user_name']}',
      );

      // Create FarmerModel from the data, normalizing location maps or strings
      _seller = FarmerModel.fromMap(_sellerData!, doc.id);

      debugPrint('DEBUG: Seller model created with name: ${_seller!.name}');
      setState(() {});
    } catch (e) {
      debugPrint('DEBUG: Failed to load seller: $e');
    }
  }

  bool _isPaymentExpired(dynamic paidAt) {
    return isVerificationPaymentExpired(paidAt);
  }

  bool get _isUnavailable {
    final status = (_fullItemData?['status'] ?? widget.item.status.name)
        .toString()
        .trim()
        .toLowerCase();
    return status == 'sold' || status == 'removed';
  }

  Future<bool> _checkItemAvailable() async {
    final doc = await FirebaseFirestore.instance
        .collection('Marketplace')
        .doc(widget.item.id)
        .get();
    final status = (doc.data()?['status'] ?? 'active')
        .toString()
        .trim()
        .toLowerCase();
    return doc.exists && status == 'active';
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.item.images;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == widget.item.sellerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.title),
        backgroundColor: Colors.green[700],
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditItemPage(
                      item: widget.item,
                      marketplaceService: widget.marketplaceService,
                      imageUploadService: widget.imageUploadService,
                    ),
                  ),
                );

                if (updated == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item updated successfully')),
                  );
                }
              },
            ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                // Confirm deletion
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete listing'),
                    content: const Text(
                      'Are you sure you want to delete this listing? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                try {
                  await widget.marketplaceService.deleteItem(widget.item.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Listing deleted')),
                  );
                  Navigator.of(
                    context,
                  ).pop(true); // close details page, signal deleted
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ---------------- IMAGE CAROUSEL ----------------
            if (images.isNotEmpty)
              SizedBox(
                height: 280,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, idx) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullscreenImagePage(
                              images: images,
                              initialIndex: idx,
                            ),
                          ),
                        );
                      },
                      child: SafeNetworkImage(
                        imageUrl: images[idx],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorWidget: Container(
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image, size: 48),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 240,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.image, size: 80),
              ),

            // ---------------- ITEM DETAILS ----------------
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Formatter.formatCurrency(
                      widget.item.price.toDouble(),
                      symbol: widget.item.currencySymbol ?? 'ZAR',
                    ),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  if (_isUnavailable) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: Colors.red.shade50,
                      child: Text(
                        'SOLD - This item is no longer available for purchase.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Location Tag
                  if (widget.item.locationTag != null &&
                      widget.item.locationTag!.isNotEmpty) ...[
                    GestureDetector(
                      onTap: _navigateToLocation,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.item.locationTag!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Text(
                    widget.item.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // ---------------- SELLER PROFILE ----------------
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: () {
                            // Prefer farmer profile picture if we have sellerId
                            if ((widget.item.sellerId).isNotEmpty) {
                              return UserProfileImage(
                                userId: widget.item.sellerId,
                                radius: 24,
                                initialImageUrl:
                                    _sellerData?['profile_pic'] ?? '',
                                onTap: () {
                                  if (widget.item.sellerId.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FarmerProfileScreen(
                                          userId: widget.item.sellerId,
                                          currentUserId: currentUser?.uid ?? '',
                                          initialFarmer: _seller,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            }

                            // Fallback: show static avatar or use any image from item data
                            final fallbackUrl =
                                _fullItemData?['sellerProfilePic'] as String? ??
                                '';
                            if (fallbackUrl.isNotEmpty) {
                              return CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(fallbackUrl),
                                backgroundColor: Colors.grey[200],
                              );
                            }

                            return CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[300],
                              child: Icon(
                                Icons.person,
                                color: Colors.grey[600],
                              ),
                            );
                          }(),
                          title: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (widget.item.sellerId.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FarmerProfileScreen(
                                          userId: widget.item.sellerId,
                                          currentUserId: currentUser?.uid ?? '',
                                          initialFarmer: _seller,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        final rawName =
                                            _seller?.name ??
                                            _sellerData?['user_name'] ??
                                            widget.item.sellerName ??
                                            'Seller';
                                        String displayName;
                                        if (rawName is String) {
                                          displayName = rawName;
                                        } else if (rawName is Map) {
                                          final candidate =
                                              rawName['displayName'] ??
                                              rawName['name'] ??
                                              rawName['user_name'];
                                          displayName =
                                              (candidate is String &&
                                                  candidate.isNotEmpty)
                                              ? candidate
                                              : 'Seller';
                                        } else {
                                          displayName =
                                              rawName?.toString() ?? 'Seller';
                                        }

                                        return Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        );
                                      },
                                    ),

                                    // Small gap then verification tick (if any) so it stays close to name
                                    const SizedBox(width: 6),
                                    if ((_sellerData != null &&
                                        _sellerData!['isVerified'] == true &&
                                        _sellerData!['verificationStatus'] ==
                                            'approved' &&
                                        _sellerData!['verificationPaid'] ==
                                            true &&
                                        !_isPaymentExpired(
                                          _sellerData!['verificationPaidAt'] ??
                                              _sellerData!['verificationPaidat'],
                                        )))
                                      Image.asset(
                                        'assets/icon/verification_tick.png',
                                        width: 20,
                                        height: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Rating: ${(_seller?.rating ?? (_sellerData?['rating'] ?? widget.item.rating)).toDouble().toStringAsFixed(1)} • ${_seller?.location ?? FarmerModel.formatLocation(_sellerData?['location'])}',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ---------------- OWNER BOOST BUTTON ----------------
                  if (isOwner)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.trending_up,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Boost Item',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BoostListingPage(itemId: widget.item.id),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ---------------- MESSAGE SELLER ----------------
                  if (currentUser != null && !isOwner)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.message, color: Colors.white),
                        label: const Text(
                          'Message Seller',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        onPressed: () {
                          final chatId = _getChatId(
                            currentUser.uid,
                            widget.item.sellerId,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: chatId,
                                otherUserId: widget.item.sellerId,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ---------------- ADD TO CART & BUY NOW ----------------
                  if (!isOwner && currentUser != null && !_isUnavailable)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.add_shopping_cart,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Add to Cart',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            onPressed: () async {
                              if (!await _checkItemAvailable()) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'This item has already been sold.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              await widget.cartService.addToCart({
                                'itemId': widget.item.id,
                                'sellerId': widget.item.sellerId,
                                'title': widget.item.title,
                                'price': widget.item.price.toDouble(),
                                'image': images.isNotEmpty ? images.first : '',
                                'quantity': 1,
                                'currencySymbol':
                                    widget.item.currencySymbol ?? 'ZAR',
                                'currency': widget.item.currencySymbol ?? 'ZAR',
                                'addedAt': DateTime.now().toIso8601String(),
                                'paymentMethods':
                                    _fullItemData?['paymentMethods'] ?? [],
                                'paymentDetails':
                                    _fullItemData?['paymentDetails'] ?? {},
                              }, currentUser.uid);

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Item added to cart'),
                                  duration: Duration(seconds: 2),
                                ),
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => CartScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.shopping_bag,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Buy Now',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            onPressed: () async {
                              if (!await _checkItemAvailable()) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'This item has already been sold.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              // Add item to cart first (truth)
                              await widget.cartService.addToCart({
                                'itemId': widget.item.id,
                                'sellerId': widget.item.sellerId,
                                'title': widget.item.title,
                                'price': widget.item.price.toDouble(),
                                'image': images.isNotEmpty ? images.first : '',
                                'quantity': 1,
                                'currencySymbol': widget.item.currencySymbol,
                                'currency': widget.item.currencySymbol,
                                'addedAt': DateTime.now().toIso8601String(),
                                'paymentMethods':
                                    _fullItemData?['paymentMethods'] ?? [],
                                'paymentDetails':
                                    _fullItemData?['paymentDetails'] ?? {},
                              }, currentUser.uid);

                              if (!context.mounted) return;

                              // Get the REAL document we just added (truth)
                              final cartItems = await widget.cartService
                                  .fetchCartItems(currentUser.uid);
                              final realItem = cartItems.firstWhere(
                                (doc) => doc['itemId'] == widget.item.id,
                                orElse: () => throw Exception(
                                  'Item not found in cart after adding',
                                ),
                              );

                              debugPrint(
                                'DEBUG: Buy Now - using REAL document: ${realItem.id} - ${realItem['title']}',
                              );

                              // Navigate to checkout with REAL Firestore document
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CheckoutScreen(selectedItems: [realItem]),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // ---------------- REPORT ITEM ----------------
                  if (!isOwner && currentUser != null && !_isUnavailable)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.report, color: Colors.white),
                        label: const Text(
                          'Report Item',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReportItemPage(itemId: widget.item.id),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
