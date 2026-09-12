import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agribased/app/utils/formatters.dart';
import 'package:agribased/models/marketplace/marketplace_item_model.dart';
import 'package:agribased/services/marketplace/marketplace_service.dart';
import 'package:agribased/services/cloudinary_image_upload_service.dart';
import 'package:agribased/screens/profile/farmer_model.dart';
import 'package:agribased/services/firestore_service.dart';
import 'package:agribased/widgets/safe_network_image.dart';

class EditItemPage extends StatefulWidget {
  final MarketplaceItem item;
  final MarketplaceService marketplaceService;
  final CloudinaryImageUploadService imageUploadService;

  EditItemPage({
    super.key,
    required this.item,
    required this.marketplaceService,
    CloudinaryImageUploadService? imageUploadService,
  }) : imageUploadService =
           imageUploadService ?? CloudinaryImageUploadService();

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _locationCtrl;
  late String _category;
  late bool _negotiable;
  late String _selectedCurrency;
  bool _saving = false;
  late List<String> _images;
  FarmerModel? _seller;

  // Payment management
  final List<String> _selectedPaymentMethods = [];
  final Map<String, dynamic> _paymentDetails = {};

  final List<String> _categories = [
    'General',
    'Electronics',
    'Home',
    'Vehicles',
    'Fashion',
  ];

  final List<Map<String, String>> _currencyOptions = [
    {'code': 'ZAR', 'label': 'South African Rand (R)'},
    {'code': 'USD', 'label': 'US Dollar (\$)'},
    {'code': 'EUR', 'label': 'Euro (€)'},
    {'code': 'GBP', 'label': 'British Pound (£)'},
    {'code': 'KES', 'label': 'Kenyan Shilling (KSh)'},
    {'code': 'NGN', 'label': 'Nigerian Naira (₦)'},
    {'code': 'GHS', 'label': 'Ghanaian Cedi (GH₵)'},
    {'code': 'TZS', 'label': 'Tanzanian Shilling (TSh)'},
    {'code': 'UGX', 'label': 'Ugandan Shilling (USh)'},
  ];

  final List<Map<String, dynamic>> _paymentOptions = [
    // Only Cash on Delivery is allowed for listing payments in this build
    {'key': 'cod', 'label': 'Cash on Delivery', 'icon': Icons.money},
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item.title);
    _descCtrl = TextEditingController(text: widget.item.description);
    _priceCtrl = TextEditingController(
      text: widget.item.price.toStringAsFixed(2),
    );
    _locationCtrl = TextEditingController(text: widget.item.locationTag ?? '');
    _category = widget.item.category.isNotEmpty
        ? widget.item.category
        : _categories.first;
    _negotiable = widget.item.negotiable;
    _selectedCurrency = Formatter.normalizeCurrencyCode(
      widget.item.currencySymbol ?? Formatter.currencySymbol,
    );
    _images = List.from(widget.item.images);

    // Load saved payment info from the item's data
    final itemData = widget.item.toMap();
    if (itemData.containsKey('paymentMethods') &&
        itemData['paymentMethods'] != null) {
      final paymentMethods = itemData['paymentMethods'];
      if (paymentMethods is List) {
        _selectedPaymentMethods.addAll(
          paymentMethods.whereType<String>().toList(),
        );
      }
    }
    // Ensure COD is present as the only selectable method
    if (!_selectedPaymentMethods.contains('cod')) {
      _selectedPaymentMethods.clear();
      _selectedPaymentMethods.add('cod');
    }
    if (itemData.containsKey('paymentDetails') &&
        itemData['paymentDetails'] != null) {
      final paymentDetails = itemData['paymentDetails'];
      if (paymentDetails is Map) {
        _paymentDetails.addAll(Map<String, dynamic>.from(paymentDetails));
      }
    }

    _loadSellerProfile();
  }

  Future<void> _loadSellerProfile() async {
    try {
      final userProfile = await FirestoreService().getUserProfile(
        widget.item.sellerId,
      );
      if (!mounted) return;

      _seller = FarmerModel(
        id: userProfile.id,
        name: userProfile.userName,
        bio: userProfile.bio,
        location: userProfile.location,
        crops: userProfile.crops,
        followers: userProfile.followers,
        following: userProfile.following,
        posts: userProfile.reviewsCount,
        profilePic: userProfile.profilePic,
        isSeller: true,
        products: const [],
        rating: userProfile.rating,
        totalSales: 0,
      );
      setState(() {});
    } catch (e) {
      debugPrint('Failed to load seller: $e');
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Location validation - mandatory
    if (_locationCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location is required! Please enter the item location.',
            ),
          ),
        );
      }
      return;
    }

    if (_selectedPaymentMethods.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one payment method')),
        );
      }
      return;
    }

    setState(() => _saving = true);
    try {
      // First create the base item
      final updatedItem = MarketplaceItem(
        id: widget.item.id,
        sellerId: widget.item.sellerId,
        sellerName: _seller?.name ?? 'Unknown',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text) ?? widget.item.price,
        category: _category,
        negotiable: _negotiable,
        images: _images,
        status: widget.item.status,
        createdAt: widget.item.createdAt,
        locationTag: _locationCtrl.text.trim(),
        currencySymbol: _selectedCurrency,
      );

      // Add payment methods and details to the item data
      final itemData = updatedItem.toMap()
        ..addAll({
          'paymentMethods': _selectedPaymentMethods,
          'paymentDetails': _paymentDetails,
        });

      // Create a new item with the updated data
      final itemWithPayments = MarketplaceItem.fromMap(itemData);
      await widget.marketplaceService.updateItem(itemWithPayments);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    setState(() => _saving = true);

    try {
      final file = File(picked.path);
      final url = await widget.imageUploadService.uploadMarketplaceImage(
        file: file,
        itemId: '${widget.item.id}_${_images.length}',
      );
      setState(() {
        _images.add(url);
        _saving = false;
      });
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
    }
  }

  Widget _buildPaymentFields() {
    return Column(
      children: [
        if (_selectedPaymentMethods.contains('mobile_money'))
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Mobile Money Number',
              hintText: '+2637XXXXXXXX',
            ),
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (_selectedPaymentMethods.contains('mobile_money') &&
                  (v == null || v.isEmpty)) {
                return 'Enter Mobile Money number';
              }
              return null;
            },
            initialValue: _paymentDetails['mobile_money'] ?? '',
            onChanged: (v) => _paymentDetails['mobile_money'] = v.trim(),
          ),
        if (_selectedPaymentMethods.contains('bank')) ...[
          TextFormField(
            decoration: const InputDecoration(labelText: 'Bank Name'),
            validator: (v) {
              if (_selectedPaymentMethods.contains('bank') &&
                  (v == null || v.isEmpty))
                return 'Enter Bank Name';
              return null;
            },
            initialValue: _paymentDetails['bank_name'] ?? '',
            onChanged: (v) => _paymentDetails['bank_name'] = v.trim(),
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Account Name'),
            validator: (v) {
              if (_selectedPaymentMethods.contains('bank') &&
                  (v == null || v.isEmpty))
                return 'Enter Account Name';
              return null;
            },
            initialValue: _paymentDetails['account_name'] ?? '',
            onChanged: (v) => _paymentDetails['account_name'] = v.trim(),
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Account Number'),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (_selectedPaymentMethods.contains('bank') &&
                  (v == null || v.isEmpty))
                return 'Enter Account Number';
              return null;
            },
            initialValue: _paymentDetails['account_number'] ?? '',
            onChanged: (v) => _paymentDetails['account_number'] = v.trim(),
          ),
        ],
        if (_selectedPaymentMethods.contains('cod'))
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Cash on Delivery selected. No additional info needed.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Listing'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_seller != null)
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        _seller!.profilePic != null &&
                            _seller!.profilePic!.isNotEmpty
                        ? NetworkImage(_seller!.profilePic!)
                        : null,
                    child:
                        _seller!.profilePic == null ||
                            _seller!.profilePic!.isEmpty
                        ? Text(_seller!.name[0])
                        : null,
                  ),
                  title: Text(_seller!.name),
                  subtitle: Text(
                    'Rating: ${_seller!.rating.toStringAsFixed(1)} • Sales: ${_seller!.totalSales}',
                  ),
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter a description' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: _currencyOptions
                    .map(
                      (currency) => DropdownMenuItem(
                        value: currency['code'],
                        child: Text(currency['label'] ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCurrency = value);
                  }
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceCtrl,
                decoration: InputDecoration(
                  labelText: 'Price',
                  prefixText:
                      '${Formatter.resolveCurrencySymbol(_selectedCurrency)} ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter a price' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  hintText: 'e.g., Nairobi, Kenya',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Location is required' : null,
              ),
              SwitchListTile(
                title: const Text('Negotiable'),
                value: _negotiable,
                onChanged: (v) => setState(() => _negotiable = v),
              ),
              const SizedBox(height: 12),

              // Payment methods
              const Text(
                'Accepted Payment Methods',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: _paymentOptions.map((option) {
                  final selected = _selectedPaymentMethods.contains(
                    option['key'],
                  );
                  return FilterChip(
                    label: Text(option['label']),
                    selected: selected,
                    avatar: Icon(option['icon'], size: 20),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedPaymentMethods.add(option['key']);
                        } else {
                          _selectedPaymentMethods.remove(option['key']);
                          _paymentDetails.remove(option['key']);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              _buildPaymentFields(),

              const SizedBox(height: 12),
              const Text(
                'Images',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: _images
                    .map(
                      (url) => Stack(
                        alignment: Alignment.topRight,
                        children: [
                          SafeNetworkImage(
                            imageUrl: url,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _images.remove(url)),
                            child: const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo),
                    label: const Text('Gallery'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
