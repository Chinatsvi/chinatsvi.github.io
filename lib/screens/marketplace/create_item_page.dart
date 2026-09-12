import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:agribased/app/utils/formatters.dart';
import 'package:agribased/models/marketplace/marketplace_item_model.dart';
import 'package:agribased/services/marketplace/marketplace_service.dart';
import 'package:agribased/services/cloudinary_image_upload_service.dart';
import 'package:agribased/services/auth_service.dart';
import 'package:agribased/widgets/safe_network_image.dart';

class CreateItemPage extends StatefulWidget {
  final MarketplaceService marketplaceService;
  final CloudinaryImageUploadService imageUploadService;

  CreateItemPage({
    super.key,
    required this.marketplaceService,
    CloudinaryImageUploadService? imageUploadService,
  }) : imageUploadService =
           imageUploadService ?? CloudinaryImageUploadService();

  @override
  State<CreateItemPage> createState() => _CreateItemPageState();
}

class _CreateItemPageState extends State<CreateItemPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  // Payment controllers
  final _bankNameCtrl = TextEditingController();
  final _accountHolderCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _branchCodeCtrl = TextEditingController();
  final _mobileMoneyCtrl = TextEditingController();

  String _category = 'General';
  bool _negotiable = false;
  String _selectedCurrency = 'R';
  bool _saving = false;

  final List<String> _uploadedUrls = [];
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

  // Only allow Cash on Delivery in current builds (mock billing)
  final List<Map<String, dynamic>> _paymentOptions = [
    {'key': 'cod', 'label': 'Cash on Delivery', 'icon': Icons.money},
  ];

  // Helper method to get payment method label
  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'card':
        return 'Bank Card';
      case 'mobile_money':
        return 'Mobile Money';
      case 'cod':
        return 'Cash on Delivery';
      default:
        return method;
    }
  }

  late final MarketplaceService _marketplaceService;
  bool _isDiscreet = false;

  @override
  void initState() {
    super.initState();
    _marketplaceService = widget.marketplaceService;
    _selectedCurrency = Formatter.normalizeCurrencyCode(
      Formatter.currencySymbol,
    );

    // Default to COD as the only accepted payment method
    if (!_selectedPaymentMethods.contains('cod')) {
      _selectedPaymentMethods.clear();
      _selectedPaymentMethods.add('cod');
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountHolderCtrl.dispose();
    _accountNumberCtrl.dispose();
    _branchCodeCtrl.dispose();
    _mobileMoneyCtrl.dispose();
    super.dispose();
  }

  // ====================== SAVE ======================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _snack('Please fill in all required fields');
      return;
    }

    // Location validation - mandatory
    if (_locationCtrl.text.trim().isEmpty) {
      _snack('⚠️ Location is required! Please enter the item location.');
      return;
    }

    // Strict payment method validation
    if (_selectedPaymentMethods.isEmpty) {
      _snack(
        '⚠️ Payment method is required! Please select at least one payment method.',
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showPaymentMethodConfirmation();
    if (!confirmed) return;

    _paymentDetails.clear();

    // ---- CARD VALIDATION ----
    if (_selectedPaymentMethods.contains('card')) {
      if (_bankNameCtrl.text.isEmpty ||
          _accountHolderCtrl.text.isEmpty ||
          _accountNumberCtrl.text.isEmpty ||
          _branchCodeCtrl.text.isEmpty) {
        _snack('⚠️ Complete all bank card details for card payment');
        return;
      }

      _paymentDetails['card'] = {
        'bank_name': _bankNameCtrl.text.trim(),
        'account_holder': _accountHolderCtrl.text.trim(),
        'account_number': _accountNumberCtrl.text.trim(),
        'branch_code': _branchCodeCtrl.text.trim(),
      };
    }

    // ---- MOBILE MONEY VALIDATION ----
    if (_selectedPaymentMethods.contains('mobile_money')) {
      if (_mobileMoneyCtrl.text.isEmpty) {
        _snack('⚠️ Enter mobile money number for mobile money payment');
        return;
      }

      _paymentDetails['mobile_money'] = {'phone': _mobileMoneyCtrl.text.trim()};
    }

    // ---- COD VALIDATION ----
    if (_selectedPaymentMethods.contains('cod')) {
      _paymentDetails['cod'] = {'type': 'cash_on_delivery'};
    }

    setState(() => _saving = true);

    try {
      final id = const Uuid().v4();
      final price = double.tryParse(_priceCtrl.text) ?? 0;

      final item = MarketplaceItem(
        id: id,
        sellerId: _marketplaceService.currentUserId,
        sellerName: AuthService.currentUserStatic?.displayName ?? 'Unknown',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: price,
        category: _category,
        negotiable: _negotiable,
        isDiscreet: _isDiscreet,
        images: _uploadedUrls,
        status: ItemStatus.active,
        locationTag: _locationCtrl.text.trim(),
        currencySymbol: _selectedCurrency,
      );

      final itemData = item.toMap()
        ..addAll({
          'paymentMethods': _selectedPaymentMethods,
          'paymentDetails': _paymentDetails,
        });

      await _marketplaceService.createItem(MarketplaceItem.fromMap(itemData));

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Save failed: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ====================== PAYMENT METHOD CONFIRMATION ======================
  Future<bool> _showPaymentMethodConfirmation() async {
    final selectedLabels = _selectedPaymentMethods
        .map((m) => _getPaymentMethodLabel(m))
        .join(', ');
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Payment Methods'),
              content: Text(
                'You selected: $selectedLabels\n\n'
                'Buyers will be able to pay using these methods.\n\n'
                'Continue with these payment options?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // ====================== IMAGES ======================
  Future<void> _addImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading indicator
      setState(() => _saving = true);

      // Convert XFile to File and upload to Cloudinary
      final file = File(image.path);
      final url = await widget.imageUploadService.uploadMarketplaceImage(
        file: file,
      );

      setState(() {
        _uploadedUrls.add(url);
        _saving = false;
      });
    } catch (e) {
      debugPrint('Error uploading image: $e');
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
    }
  }

  // ====================== PAYMENT FIELDS ======================
  Widget _buildPaymentFields() {
    return Column(
      children: [
        if (_selectedPaymentMethods.contains('card'))
          Column(
            children: [
              TextFormField(
                controller: _bankNameCtrl,
                decoration: const InputDecoration(labelText: 'Bank Name'),
                validator: (v) =>
                    _selectedPaymentMethods.contains('card') &&
                        (v == null || v.isEmpty)
                    ? 'Required'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _accountHolderCtrl,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
                ),
                validator: (v) =>
                    _selectedPaymentMethods.contains('card') &&
                        (v == null || v.isEmpty)
                    ? 'Required'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _accountNumberCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Account Number'),
                validator: (v) =>
                    _selectedPaymentMethods.contains('card') &&
                        (v == null || v.isEmpty)
                    ? 'Required'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _branchCodeCtrl,
                decoration: const InputDecoration(labelText: 'Branch Code'),
                validator: (v) =>
                    _selectedPaymentMethods.contains('card') &&
                        (v == null || v.isEmpty)
                    ? 'Required'
                    : null,
              ),
            ],
          ),

        if (_selectedPaymentMethods.contains('mobile_money'))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextFormField(
              controller: _mobileMoneyCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Money Number',
              ),
              validator: (v) =>
                  _selectedPaymentMethods.contains('mobile_money') &&
                      (v == null || v.isEmpty)
                  ? 'Required'
                  : null,
            ),
          ),

        if (_selectedPaymentMethods.contains('cod'))
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Customer pays cash on delivery',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  // ====================== UI ======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Listing'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
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
              TextFormField(
                controller: _priceCtrl,
                decoration: InputDecoration(
                  labelText: 'Price',
                  prefixText:
                      '${Formatter.resolveCurrencySymbol(_selectedCurrency)} ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
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
              SwitchListTile(
                title: const Text('Discreet Item'),
                subtitle: const Text('Won\'t continue selling after bought'),
                value: _isDiscreet,
                onChanged: (v) => setState(() => _isDiscreet = v),
                secondary: Icon(
                  _isDiscreet ? Icons.visibility_off : Icons.visibility,
                  color: _isDiscreet ? Colors.orange : Colors.grey,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedPaymentMethods.isEmpty
                        ? Colors.red
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _selectedPaymentMethods.isEmpty
                      ? Colors.red.shade50
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Payment Methods *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _selectedPaymentMethods.isEmpty
                                ? Colors.red
                                : Colors.black87,
                          ),
                        ),
                        if (_selectedPaymentMethods.isEmpty)
                          const Icon(Icons.error, color: Colors.red, size: 20)
                        else
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedPaymentMethods.isEmpty
                          ? 'Please select at least one payment method (required)'
                          : 'Selected: ${_selectedPaymentMethods.map((m) => _getPaymentMethodLabel(m)).join(', ')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _selectedPaymentMethods.isEmpty
                            ? Colors.red.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: _paymentOptions.map((o) {
                        final selected = _selectedPaymentMethods.contains(
                          o['key'],
                        );
                        return FilterChip(
                          label: Text(o['label']),
                          selected: selected,
                          avatar: Icon(o['icon']),
                          backgroundColor: selected
                              ? Colors.green.shade100
                              : null,
                          selectedColor: Colors.green.shade700,
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                _selectedPaymentMethods.add(o['key']);
                              } else {
                                _selectedPaymentMethods.remove(o['key']);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              _buildPaymentFields(),

              const SizedBox(height: 16),
              // ====================== IMAGES ======================
              const Text(
                'Images',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._uploadedUrls.map(
                    (url) => Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: url.startsWith('http')
                                ? SafeNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    errorWidget: const Icon(Icons.image),
                                  )
                                : const Icon(Icons.image),
                          ),
                        ),
                        Positioned(
                          right: -4,
                          top: -4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _uploadedUrls.remove(url));
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _addImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      child: const Icon(Icons.add, color: Colors.grey),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Publish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
