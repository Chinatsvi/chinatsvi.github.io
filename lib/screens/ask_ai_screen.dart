import 'package:flutter/material.dart';
import '../services/enhanced_ai_service.dart';
import 'badge/renewal_payment_screen.dart';
import 'dart:async';

class AskAiScreen extends StatefulWidget {
  const AskAiScreen({super.key});

  @override
  State<AskAiScreen> createState() => _AskAiScreenState();
}

class _AskAiScreenState extends State<AskAiScreen> {
  final TextEditingController _controller = TextEditingController();
  String response = '';
  bool isLoading = false;
  int _remainingRequests = 25;
  bool _isVerified = false;
  bool _isExpired = false;
  DateTime? _expiresAt;
  int _daysRemaining = 0;
  Timer? _verificationCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadRemainingRequests();
    _startVerificationStatusCheck();
  }

  @override
  void dispose() {
    _verificationCheckTimer?.cancel();
    super.dispose();
  }

  /// Periodically check verification status to update UI in real-time
  void _startVerificationStatusCheck() {
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      if (mounted) {
        await _loadRemainingRequests(); // This will refresh verification status
      }
    });
  }

  Future<void> _loadRemainingRequests() async {
    final rateLimitInfo = await EnhancedAiService.instance.getRateLimitInfo();
    final remaining = rateLimitInfo['remaining'] as int;
    final isVerified = rateLimitInfo['isVerified'] as bool;
    final isExpired = rateLimitInfo['isExpired'] as bool;
    final expiresAt = rateLimitInfo['expiresAt'] as DateTime?;
    final daysRemaining = rateLimitInfo['daysRemaining'] as int;
    
    if (mounted) {
      setState(() {
        _remainingRequests = remaining;
        _isVerified = isVerified;
        _isExpired = isExpired;
        _expiresAt = expiresAt;
        _daysRemaining = daysRemaining;
      });
    }
  }

  String _getRequestDisplayText() {
    if (_remainingRequests >= 999999) {
      return 'Unlimited';
    }
    return _remainingRequests.toString();
  }

  bool _isUnlimitedUser() {
    return _remainingRequests >= 999999;
  }

  Future<void> _askAi() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;
    // Check rate limits first
    final rateInfo = await EnhancedAiService.instance.getRateLimitInfo();
    final remaining = rateInfo['remaining'] as int;
    final isUnlimited = rateInfo['unlimited'] as bool;

    if (!isUnlimited && remaining <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Daily AI limit reached (${rateInfo['limit']} requests). Try again tomorrow or renew.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      isLoading = true;
      response = 'Thinking... please wait.';
    });

    // Track usage now (will be refunded on failure)
    await EnhancedAiService.instance.trackUsage(isUpload: false);

    try {
      final responseStream = EnhancedAiService.instance.streamResponse(prompt);
      String fullResponse = '';

      await for (final chunk in responseStream) {
        fullResponse += chunk;
        if (mounted) {
          setState(() {
            response = fullResponse;
          });
        }
      }

      // Update remaining requests counter
      await _loadRemainingRequests();
    } catch (e) {
      // Refund usage when AI fails
      await EnhancedAiService.instance.refundUsage(isUpload: false);
      setState(() {
        response = '''Service temporarily unavailable.\n\nThis may be due to:\n• High server demand - please try again shortly\n• Daily limit reached - resets every 24 hours\n• Network connectivity issue\n\nTap the diagnostic icon (🔍) for details.'''
        ;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      isLoading = true;
      response = '🔍 Running API diagnostics...\n\n';
    });

    final results = await EnhancedAiService.instance.runDiagnostics();

    String report = '🔍 API DIAGNOSTICS RESULTS:\n';
    report += '=' * 40 + '\n\n';

    results.forEach((key, value) {
      final status = (value as Map)['status'];
      final error = value['error'];
      final httpCode = value['http_code'];

      report += '$key:\n';
      report += '  Status: $status\n';
      if (httpCode != null) report += '  HTTP Code: $httpCode\n';
      if (error != null) report += '  Error: $error\n';
      report += '\n';
    });

    report += '\n' + '=' * 40 + '\n';

    // Summary
    final allFailed = results.values.every((v) =>
        (v as Map)['status'] == '❌ FAILED' || v['status'] == '❌ ERROR');

    if (allFailed) {
      report += '⚠️ ALL APIs FAILED\n\n';
      report += 'Common fixes:\n';
      report += '1. Check your internet connection\n';
      report += '2. Create NEW Google AI Studio project (not just new key)\n';
      report += '3. Wait 24h for quota to reset\n';
      report += '4. OpenAI also needs billing enabled\n';
    } else {
      report += '✅ At least one API is working!';
    }

    setState(() {
      response = report;
      isLoading = false;
    });
  }

  Widget _buildExpirationBanner() {
    if (_isExpired && !_isVerified) {
      // Verification has expired - show renewal banner
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade300, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verification Expired',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Limited to 15 requests per day. Renew now to get unlimited access.',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RenewalPaymentScreen(),
                  ),
                );
              },
              child: const Text('Renew', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    } else if (_isVerified && _daysRemaining > 0 && _daysRemaining <= 3) {
      // Verification expiring soon - show warning banner
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade300, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.timer, color: Colors.orange.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verification Expiring Soon',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _daysRemaining == 1
                        ? 'Your verification expires tomorrow. Renew now to keep unlimited access.'
                        : 'Your verification expires in $_daysRemaining days. Renew now to keep unlimited access.',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RenewalPaymentScreen(),
                  ),
                );
              },
              child: const Text('Renew', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask AI'),
        actions: [
          // 🔥 Diagnostic button
          IconButton(
            icon: const Icon(Icons.network_check, color: Colors.white),
            tooltip: 'Test APIs',
            onPressed: _runDiagnostics,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flash_on, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  _getRequestDisplayText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (_isUnlimitedUser()) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, size: 14, color: Colors.yellow),
                ],
                if (_isExpired && !_isVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.warning, size: 14, color: Colors.red),
                ],
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildExpirationBanner(),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Ask something',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _askAi, child: const Text('Submit')),
            const SizedBox(height: 20),
            if (isLoading)
              const CircularProgressIndicator()
            else if (response.isNotEmpty)
              Expanded(child: SingleChildScrollView(child: Text(response))),
          ],
        ),
      ),
    );
  }
}
