import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app/utils/formatters.dart';
import '../../services/farmer_status_scheduler.dart';
import '../../services/verification_renewal_service.dart';

class StatusSchedulerAdminScreen extends StatefulWidget {
  const StatusSchedulerAdminScreen({super.key});

  @override
  State<StatusSchedulerAdminScreen> createState() =>
      _StatusSchedulerAdminScreenState();
}

class _StatusSchedulerAdminScreenState
    extends State<StatusSchedulerAdminScreen> {
  bool _isRefreshing = false;
  bool _isSendingReminders = false;

  String _formatStatusValue(dynamic value) {
    final normalized = (value ?? '').toString().trim().toLowerCase();
    switch (normalized) {
      case 'warning':
        return 'Under Review';
      case 'bad':
        return 'Restricted';
      case 'good':
      case '':
      case 'null':
        return 'Good Farmer';
      default:
        return normalized.isEmpty ? 'Good Farmer' : normalized;
    }
  }

  /// Formats the `location` field for display.
  String _formatLocation(dynamic location) {
    final formatted = Formatter.formatLocation(location);
    return formatted.isEmpty ? 'Unknown' : formatted;
  }


  Future<void> _refreshData() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _isRefreshing = true);
    try {
      await FarmerStatusScheduler.runScheduledChecks();
    } catch (_) {
      if (!mounted || messenger == null) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to run scheduler checks right now'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _sendVerificationRemindersNow() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _isSendingReminders = true);
    try {
      await VerificationRenewalService().checkAndSendRenewalReminders();
      if (!mounted || messenger == null) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Verification reminder scan completed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted || messenger == null) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to send reminder notifications right now'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingReminders = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _SectionCard(
            title: 'Pending status checks',
            subtitle: 'Automated status recovery checks that are due now.',
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: FarmerStatusScheduler.getPendingStatusChecks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No pending recovery checks.'),
                  );
                }

                return Column(
                  children: items.map((item) {
                    final scheduledDate = item['scheduledCheckDate'] as DateTime;
                    final dueIn = item['daysUntilCheck'] as int;
                    return ListTile(
                      title: Text(item['farmerId'] as String),
                      subtitle: Text(
                        'Current status: ${_formatStatusValue(item['currentStatus'])} • Scheduled: ${scheduledDate.toLocal().toString()} • Due in ${dueIn.abs()} day(s)',
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Farmers needing status improvement',
            subtitle: 'Manual admin review panel for reputation recovery.',
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: FarmerStatusScheduler.getAllFarmersNeedingImprovement(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final farmers = snapshot.data ?? [];
                if (farmers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No farmers currently need manual improvement.'),
                  );
                }

                return Column(
                  children: farmers.map((farmer) {
                    final farmerId = farmer['farmerId'] as String;
                    final name = farmer['name'] as String;
                    final status = farmer['currentStatus'] as String;
                    final updatedAt = farmer['reputationUpdatedAt'];
                    return ListTile(
                      title: Text('$name ($farmerId)'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${_formatStatusValue(status)}'),
                          Text('Location: ${_formatLocation(farmer['location'])}'),
                          if (updatedAt is Timestamp)
                            Text(
                              'Updated: ${updatedAt.toDate().toLocal().toString()}',
                            ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          final result = await FarmerStatusScheduler
                              .improveFarmerStatusManually(farmerId);
                          if (!mounted || messenger == null) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(result['message'] as String),
                              backgroundColor:
                                  (result['success'] == true)
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          );
                          setState(() {});
                        },
                        child: const Text('Improve'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Verification tick reminders',
            subtitle: 'Manually send reminder notifications to verified farmers who need to repay their badge subscription.',
            child: Column(
              children: [
                const Text(
                  'This sends the same renewal reminder flow used by the verification renewal service, including the “Renew Now” notification button for the farmer.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isSendingReminders ? null : _sendVerificationRemindersNow,
                  icon: const Icon(Icons.notifications_active),
                  label: _isSendingReminders
                      ? const Text('Sending...')
                      : const Text('Send reminder notifications'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isRefreshing ? null : _refreshData,
                  icon: const Icon(Icons.sync),
                  label: _isRefreshing
                      ? const Text('Running...')
                      : const Text('Run scheduler checks'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}