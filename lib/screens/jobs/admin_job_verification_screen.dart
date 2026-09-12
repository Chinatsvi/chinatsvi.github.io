import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'package:url_launcher/url_launcher.dart';
import 'package:agribased/models/job_model.dart';
import 'package:agribased/services/job/job_service.dart';

class AdminJobVerificationScreen extends StatelessWidget {
  const AdminJobVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jobService = JobService();
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text(
          'Job Verification',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<JobPost>>(
        stream: jobService.getPendingJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading jobs',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      '${snapshot.error}',
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Force refresh by rebuilding
                      (context as Element).markNeedsBuild();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final jobs = snapshot.data ?? [];

          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending jobs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All job postings have been reviewed',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return _buildJobCard(context, job, jobService, currentUser?.uid);
            },
          );
        },
      ),
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    JobPost job,
    JobService jobService,
    String? adminId,
  ) {
    final isFarmerJob = job.postType == JobPostType.farmerJob;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isFarmerJob
              ? Colors.green.shade100
              : Colors.blue.shade100,
          child: Icon(
            isFarmerJob ? Icons.work : Icons.person_search,
            color: isFarmerJob ? Colors.green : Colors.blue,
          ),
        ),
        title: Text(
          job.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By: ${job.userName}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              'Location: ${job.location}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: 'Approve',
              onPressed: () => _approveJob(context, job, jobService, adminId),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              tooltip: 'Reject',
              onPressed: () => _rejectJob(context, job, jobService),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job Type Badge
                Row(
                  children: [
                    _buildBadge(
                      isFarmerJob ? 'FARMER HIRING' : 'JOB SEEKER',
                      isFarmerJob ? Colors.green : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildBadge(job.category.name.toUpperCase(), Colors.grey),
                  ],
                ),

                const SizedBox(height: 16),

                // Contact Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (job.userPhone != null)
                        InkWell(
                          onTap: () => _launchPhone(context, job.userPhone!),
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 16,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                job.userPhone!,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (job.contactEmail != null) ...[
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _launchEmail(context, job.contactEmail!),
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.email,
                                size: 16,
                                color: Colors.orange.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                job.contactEmail!,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (job.website != null) ...[
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _launchUrl(context, job.website!),
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.language,
                                size: 16,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  job.website!,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(job.userName),
                        ],
                      ),
                      // Social Links
                      if (job.facebookUrl != null ||
                          job.twitterUrl != null ||
                          job.linkedinUrl != null ||
                          job.whatsappNumber != null) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 4),
                        Text(
                          'Social Links:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (job.facebookUrl != null)
                              _buildClickableSocialChip(
                                context,
                                Icons.facebook,
                                'Facebook',
                                Colors.blue,
                                job.facebookUrl!,
                              ),
                            if (job.twitterUrl != null)
                              _buildClickableSocialChip(
                                context,
                                Icons.alternate_email,
                                'Twitter',
                                Colors.lightBlue,
                                job.twitterUrl!,
                              ),
                            if (job.linkedinUrl != null)
                              _buildClickableSocialChip(
                                context,
                                Icons.business,
                                'LinkedIn',
                                Colors.blueAccent,
                                job.linkedinUrl!,
                              ),
                            if (job.whatsappNumber != null)
                              _buildClickableSocialChip(
                                context,
                                Icons.chat,
                                'WhatsApp',
                                Colors.green,
                                'https://wa.me/${job.whatsappNumber!.replaceAll(RegExp(r"\s"), "")}',
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  'Description',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(job.description),

                const SizedBox(height: 16),

                // Farmer Job Details
                if (isFarmerJob) ...[
                  if (job.farmName != null) ...[
                    _buildDetailRow('Farm Name', job.farmName!),
                  ],
                  if (job.salary != null) ...[
                    _buildDetailRow(
                      'Salary',
                      '\$${job.salary!.toStringAsFixed(0)} ${job.salaryPeriod ?? ""}',
                    ),
                  ],
                  if (job.duration != null) ...[
                    _buildDetailRow('Duration', job.duration!),
                  ],
                  if (job.positionsAvailable != null) ...[
                    _buildDetailRow('Positions', '${job.positionsAvailable}'),
                  ],
                  if (job.startDate != null) ...[
                    _buildDetailRow('Start Date', _formatDate(job.startDate!)),
                  ],
                  if (job.requirements != null &&
                      job.requirements!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Requirements',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...job.requirements!.map(
                      (req) => Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.green.shade400,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(req)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (job.benefits != null && job.benefits!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Benefits',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: job.benefits!
                          .map(
                            (benefit) => Chip(
                              label: Text(
                                benefit,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.green.shade50,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ] else ...[
                  // Job Seeker Details
                  if (job.skills != null) ...[
                    _buildDetailRow('Skills', job.skills!),
                  ],
                  if (job.experience != null) ...[
                    _buildDetailRow('Experience', job.experience!),
                  ],
                  if (job.education != null) ...[
                    _buildDetailRow('Education', job.education!),
                  ],
                  if (job.expectedSalary != null) ...[
                    _buildDetailRow('Expected Salary', job.expectedSalary!),
                  ],
                  if (job.availability != null) ...[
                    _buildDetailRow('Availability', job.availability!),
                  ],
                  if (job.preferredLocation != null) ...[
                    _buildDetailRow(
                      'Preferred Location',
                      job.preferredLocation!,
                    ),
                  ],
                  // Documents Section for Job Seekers
                  if (job.documentUrls != null &&
                      job.documentUrls!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Uploaded Documents (${job.documentUrls!.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...job.documentUrls!.asMap().entries.map((entry) {
                            final index = entry.key;
                            final url = entry.value;
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.insert_drive_file,
                                color: Colors.blue,
                                size: 20,
                              ),
                              title: Text(
                                'Document ${index + 1}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                url.length > 30
                                    ? '${url.substring(0, 30)}...'
                                    : url,
                                style: const TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(
                                Icons.open_in_new,
                                size: 16,
                                color: Colors.blue,
                              ),
                              onTap: () {
                                // Open document URL
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Open: $url')),
                                );
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 16),

                // Posted Date
                Text(
                  'Posted: ${_formatDate(job.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _approveJob(context, job, jobService, adminId),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectJob(context, job, jobService),
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text(
                          'Reject',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildClickableSocialChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    String url,
  ) {
    return InkWell(
      onTap: () => _launchUrl(context, url),
      borderRadius: BorderRadius.circular(20),
      child: Chip(
        avatar: Icon(icon, size: 16, color: color),
        label: Text(label, style: TextStyle(fontSize: 12, color: color)),
        backgroundColor: color.withOpacity(0.1),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _launchPhone(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone app')),
        );
      }
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    }
  }

  Future<void> _approveJob(
    BuildContext context,
    JobPost job,
    JobService jobService,
    String? adminId,
  ) async {
    try {
      await jobService.approveJob(job.id, adminId ?? 'system');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${job.title}" approved ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }

      developer.log(
        '✅ Admin approved job: ${job.id}',
        name: 'AdminJobVerification',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      developer.log('❌ Error approving job: $e', name: 'AdminJobVerification');
    }
  }

  Future<void> _rejectJob(
    BuildContext context,
    JobPost job,
    JobService jobService,
  ) async {
    // Show dialog to get rejection reason
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Job Posting'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Why are you rejecting "${job.title}"?'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Optional reason...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await jobService.rejectJob(
          job.id,
          reason: reasonController.text.trim().isNotEmpty
              ? reasonController.text.trim()
              : null,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${job.title}" rejected ❌'),
              backgroundColor: Colors.red,
            ),
          );
        }

        developer.log(
          '❌ Admin rejected job: ${job.id}',
          name: 'AdminJobVerification',
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rejecting job: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }

        developer.log(
          '❌ Error rejecting job: $e',
          name: 'AdminJobVerification',
        );
      }
    }
  }
}
