import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/mock_cash_handler.dart';
import '../../models/mock_product.dart';
import '../../services/build_config_service.dart';

class RenewalPaymentScreen extends StatefulWidget {
  const RenewalPaymentScreen({super.key});

  @override
  State<RenewalPaymentScreen> createState() => _RenewalPaymentScreenState();
}

class _RenewalPaymentScreenState extends State<RenewalPaymentScreen> {
  bool loading = false;

  // ✅ Base subscription fee in ZAR (South African Rand)
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

      final response = await http.get(Uri.parse(
          "https://api.exchangerate.host/latest?base=ZAR&symbols=$localCurrency"));
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
      case "NG": return "NGN"; // Nigeria
      case "KE": return "KES"; // Kenya
      case "US": return "USD"; // USA
      default: return "ZAR";   // South Africa
    }
  }

  Future<void> _startRenewalPayment() async {
    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final email = user.email ?? "farmer@example.com";

      final amount = (localAmount ?? baseFeeZAR.toDouble());
      if (BuildConfigService.useMockBilling) {
        final product = mockProducts.firstWhere(
          (p) => p.id == 'verification_tick_monthly',
          orElse: () => mockProducts.first,
        );
        await MockCashHandler.instance.purchase(product, userId: user.uid, context: context);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Renewal successful, badge re-activated! (mock)')),
        );
        Navigator.pop(context);
      } else {
        // TODO: Wire real payment provider (Paystack or Play Billing)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment provider not configured')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Renewal error: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayAmount = localAmount?.toStringAsFixed(2) ?? baseFeeZAR.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Renew Verification Badge'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Your verification badge has expired.\n'
              'Renew your subscription for R150 per month.\n'
              'Equivalent in your local currency: $displayAmount $localCurrency\n\n'
              'You can pay with card, bank transfer, USSD, or mobile money depending on your country.',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.all(14),
                      ),
                      onPressed: _startRenewalPayment,
                      child: const Text('Renew & Reactivate Badge'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}