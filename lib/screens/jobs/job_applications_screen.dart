import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../docs/pdf_viewer_screen.dart';
import '../docs/doc_viewer_screen.dart';
import 'package:agribased/models/job_model.dart';
import 'package:agribased/services/job/job_service.dart';
import 'package:agribased/widgets/user_info_display.dart';

class JobApplicationsScreen extends StatefulWidget {
  final String? jobId; // If null, shows all user's applications

  const JobApplicationsScreen({super.key, this.jobId});

  @override
  State<JobApplicationsScreen> createState() => _JobApplicationsScreenState();
}

class _JobApplicationsScreenState extends State<JobApplicationsScreen> {
  final JobService _jobService = JobService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green.shade700,
          title: const Text('Visitors', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: Text('Please sign in to view visitors')),
      );
    }

    final isViewingReceivedApplications = widget.jobId != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: Text(
          isViewingReceivedApplications ? 'Job Visitors' : 'My Visitors',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isViewingReceivedApplications
          ? _buildReceivedApplicationsList(widget.jobId!)
          : _buildMyApplicationsList(user.uid),
    );
  }

  Widget _buildReceivedApplicationsList(String jobId) {
    return StreamBuilder<List<JobApplication>>(
      stream: _jobService.getJobApplications(jobId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading visitors',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }

        final applications = snapshot.data ?? [];

        // If this is the user's own applications list, mark any accepted/rejected
        // applications as seen so the indicator clears.
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && widget.jobId == null && applications.isNotEmpty) {
            final hasUnseen = applications
                .any((a) => a.status != 'pending' && !a.applicantSeen);
            if (hasUnseen) {
              _jobService.markApplicationsSeenForUser(user.uid);
            }
          }
        } catch (_) {}

        if (applications.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inbox,
            message: 'No visitors yet',
            subtitle: 'When people visit, you will see them here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final app = applications[index];
            return _buildApplicationCard(
              application: app,
              isReceived: true,
              onStatusUpdate: (status) =>
                  _updateApplicationStatus(app.id, status),
            );
          },
        );
      },
    );
  }

  Widget _buildMyApplicationsList(String userId) {
    return StreamBuilder<List<JobApplication>>(
      stream: _jobService.getUserApplications(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading visitors',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }

        final applications = snapshot.data ?? [];

        if (applications.isEmpty) {
          return _buildEmptyState(
            icon: Icons.send_outlined,
            message: 'No messages sent',
            subtitle: 'Jobs you message will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final app = applications[index];
            return _buildApplicationCard(application: app, isReceived: false);
          },
        );
      },
    );
  }

  Widget _buildApplicationCard({
    required JobApplication application,
    required bool isReceived,
    Function(String)? onStatusUpdate,
  }) {
    final statusColor = _getStatusColor(application.status);
    final statusIcon = _getStatusIcon(application.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserProfileImage(
                  userId: application.applicantId,
                  radius: 20,
                  initialImageUrl: application.applicantProfilePic ?? '',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.applicantName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Applied on ${_formatDate(application.appliedAt)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        application.status[0].toUpperCase() +
                            application.status.substring(1),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (!isReceived) ...[
              Text(
                'For: ${application.jobTitle}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
            ],
            if (application.coverLetter != null &&
                application.coverLetter!.isNotEmpty) ...[
              Text(
                'Message:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  application.coverLetter!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (application.applicantPhone != null) ...[
              Row(
                children: [
                  Icon(Icons.phone, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    application.applicantPhone!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (application.applicantEmail != null) ...[
              Row(
                children: [
                  Icon(Icons.email, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 8),
                  Text(application.applicantEmail!),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (application.resumeUrl != null) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _viewCV(application.resumeUrl!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CV/Resume Attached',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            Text(
                              'Tap to view',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.open_in_new,
                        color: Colors.blue.shade700,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (isReceived &&
                onStatusUpdate != null &&
                application.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showResponseDialog(application.id, 'accepted'),
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      label: const Text('Accept'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showResponseDialog(application.id, 'rejected'),
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (application.employerResponse != null &&
                application.employerResponse!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: application.status == 'accepted'
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: application.status == 'accepted'
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: FutureBuilder(
                  future: _jobService.getJobById(application.jobId),
                  builder: (context, AsyncSnapshot<dynamic> jobSnap) {
                    final employerName = (jobSnap.data != null &&
                            jobSnap.data.userName != null &&
                            jobSnap.data.userName.toString().isNotEmpty)
                        ? jobSnap.data.userName
                        : 'Employer';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Response from $employerName:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: application.status == 'accepted'
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(application.employerResponse!),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _viewCV(String cvUrl) async {
    // Open PDF inside app, otherwise attempt to show via WebView (Google Docs viewer)
    try {
      final lower = cvUrl.toLowerCase();
      if (lower.endsWith('.pdf') || lower.contains('.pdf')) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PdfViewerScreen(url: cvUrl),
            ),
          );
        }
        return;
      }

      // For doc/docx or other document types, attempt to show in WebView via Google Docs
      if (lower.endsWith('.doc') || lower.endsWith('.docx') || lower.contains('.doc')) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DocViewerScreen(url: cvUrl),
            ),
          );
        }
        return;
      }

      // Fallback: try opening in external app if WebView or PDF not applicable
      final uri = Uri.parse(cvUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open CV'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening CV: $e')),
        );
      }
    }
  }

  Future<void> _showResponseDialog(String applicationId, String status) async {
    final responseController = TextEditingController();
    final isAccept = status == 'accepted';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isAccept ? 'Accept Visitor' : 'Decline Visitor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAccept
                    ? 'Send a message to the visitor (optional):'
                    : 'Let the visitor know why (optional):',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: responseController,
                decoration: InputDecoration(
                  hintText: isAccept
                      ? 'e.g., Please call me to arrange an interview'
                      : 'e.g., We have filled the position',
                  border: const OutlineInputBorder(),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: isAccept ? Colors.green : Colors.red,
              ),
              child: Text(isAccept ? 'Accept' : 'Decline'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _updateApplicationStatus(
        applicationId,
        status,
        response: responseController.text.trim().isNotEmpty
            ? responseController.text.trim()
            : null,
      );
    }
  }

  Future<void> _updateApplicationStatus(
    String applicationId,
    String status, {
    String? response,
  }) async {
    try {
      await _jobService.updateApplicationStatus(
        applicationId: applicationId,
        status: status,
        response: response,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted' ? 'Visitor accepted' : 'Visitor declined',
            ),
            backgroundColor: status == 'accepted'
                ? Colors.green
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'viewed':
        return Colors.blue;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'viewed':
        return Icons.visibility;
      case 'pending':
      default:
        return Icons.hourglass_empty;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
