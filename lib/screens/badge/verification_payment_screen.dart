import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/play_billing_service.dart';
import '../../services/mock_cash_handler.dart';
import '../../models/mock_product.dart';
import '../../services/build_config_service.dart';

class VerificationPaymentScreen extends StatefulWidget {
  const VerificationPaymentScreen({super.key});

  @override
  State<VerificationPaymentScreen> createState() =>
      _VerificationPaymentScreenState();
}

class _VerificationPaymentScreenState extends State<VerificationPaymentScreen> {
  bool loading = false;

  final int baseFeeZAR = 150;
  double? localAmount;
  String localCurrency = "ZAR";

  @override
  void initState() {
    super.initState();
    _detectCurrencyAndFetchRate();
  }

  Future<void> _detectCurrencyAndFetchRate() async {
    try {
      Locale deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      String countryCode = deviceLocale.countryCode ?? "ZA";
      localCurrency = _mapCountryToCurrency(countryCode);

      final response = await http.get(
        Uri.parse(
          "https://api.exchangerate.host/latest?base=ZAR&symbols=$localCurrency",
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'];
        double exchangeRate = rates[localCurrency];
        setState(() {
          localAmount = baseFeeZAR * exchangeRate;
        });
      }
    } catch (e) {
      debugPrint("Error fetching exchange rate: $e");
      setState(() {
        localAmount = baseFeeZAR.toDouble();
        localCurrency = "ZAR";
      });
    }
  }

  String _mapCountryToCurrency(String countryCode) {
    switch (countryCode) {
      case "NG":
        return "NGN";
      case "KE":
        return "KES";
      case "US":
        return "USD";
      default:
        return "ZAR";
    }
  }

  Future<void> _startPayment() async {
    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      if (BuildConfigService.useMockBilling) {
        // Use mock handler for development/testing
        final product = mockProducts.firstWhere(
          (p) => p.id == 'verification_tick_monthly',
          orElse: () => mockProducts.first,
        );
        await MockCashHandler.instance.purchase(product, userId: user.uid, context: context);
        if (!mounted) return;
        Navigator.pop(context);
        return;
      }

      // ✅ Process payment via Play Billing
      await PlayBillingService.instance.buyVerificationTick(userId: user.uid);

      // Note: The actual verification update happens in the PlayBillingService
      // after successful purchase completion
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment initiated, please complete the purchase in Google Play',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment error: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayAmount =
        localAmount?.toStringAsFixed(2) ?? baseFeeZAR.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activate Verification Badge'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Pay R$baseFeeZAR per month to activate your verification badge.\n'
                'Equivalent in your local currency: $displayAmount $localCurrency\n\n'
                'You can pay via Google Play for instant verification.',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.all(14),
                        ),
                        onPressed: _startPayment,
                        child: const Text('Pay & Activate Badge'),
                      ),
                    ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
