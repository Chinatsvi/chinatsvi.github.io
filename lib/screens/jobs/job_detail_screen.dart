import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:agribased/models/job_model.dart';
import 'package:agribased/services/job/job_service.dart';
import 'package:agribased/services/cloudinary_service.dart';
import 'package:agribased/app/utils/formatters.dart';
import 'package:agribased/widgets/user_info_display.dart';
import 'job_post_screen.dart';
import 'job_applications_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final JobPost job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final JobService _jobService = JobService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isLoading = false;
  bool _hasApplied = false;

  @override
  void initState() {
    super.initState();
    _incrementViewCount();
    _checkIfApplied();
  }

  Future<void> _incrementViewCount() async {
    if (!widget.job.isApiJob) {
      await _jobService.incrementViewCount(widget.job.id);
    }
  }

  Future<void> _checkIfApplied() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.job.isApiJob) return;

    try {
      final applications = await _jobService
          .getUserApplications(user.uid)
          .first;
      setState(() {
        _hasApplied = applications.any((app) => app.jobId == widget.job.id);
      });
    } catch (e) {
      // Silently handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final isFarmerJob = job.postType == JobPostType.farmerJob;
    final isApiJob = job.isApiJob;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == job.userId;
    final isAdmin = currentUser != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with job title
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: isFarmerJob
                ? Colors.green.shade700
                : Colors.blue.shade700,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                job.title,
                style: const TextStyle(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isFarmerJob
                          ? Colors.green.shade600
                          : Colors.blue.shade600,
                      isFarmerJob
                          ? Colors.green.shade800
                          : Colors.blue.shade800,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    isFarmerJob ? Icons.work : Icons.person_search,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            actions: [
              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDelete();
                    } else if (value == 'edit') {
                      _navigateToEdit();
                    } else if (value == 'applications') {
                      _viewApplications();
                    }
                  },
                  itemBuilder: (context) => [
                    if (isFarmerJob)
                      const PopupMenuItem(
                        value: 'applications',
                        child: Row(
                          children: [
                            Icon(Icons.people_outline),
                            SizedBox(width: 8),
                            Text('View Applications'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  if (!isApiJob) ...[
                    Row(
                      children: [
                        _buildStatusChip(job.status),
                        const SizedBox(width: 8),
                        _buildTypeChip(job.postType),
                        const SizedBox(width: 8),
                        _buildCategoryChip(job.category),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Posted by
                  if (!isApiJob) ...[
                    _buildSection(
                      title: 'Posted By',
                      child: Row(
                        children: [
                          UserProfileImage(
                            userId: job.userId,
                            radius: 20,
                            initialImageUrl: job.userProfilePic ?? '',
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (job.farmName != null)
                                  Text(
                                    job.farmName!,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (isApiJob) ...[
                    // API Job header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.public, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'External Job Listing',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                                Text(
                                  'Posted by ${job.userName} on ${job.apiSource}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Contact Information Section
                  _buildSection(
                    title: 'Contact Information',
                    child: _buildContactInfoSection(widget.job),
                  ),
                  const SizedBox(height: 16),

                  // Location
                  _buildSection(
                    title: 'Location',
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            job.location,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _buildSection(
                    title: 'Description',
                    child: Text(
                      job.description,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Salary section (for farmer jobs)
                  if (isFarmerJob && job.salary != null) ...[
                    _buildSection(
                      title: 'Compensation',
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              color: Colors.green.shade700,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '\$${job.salary!.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                Text(
                                  'per ${job.salaryPeriod ?? 'month'}',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Job seeker specific fields
                  if (!isFarmerJob) ...[
                    if (job.skills != null && job.skills!.isNotEmpty) ...[
                      _buildSection(
                        title: 'Skills',
                        child: _buildTagList(
                          job.skills!.split(',').map((s) => s.trim()).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (job.experience != null) ...[
                      _buildInfoRow(
                        Icons.timeline,
                        'Experience',
                        job.experience!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (job.education != null) ...[
                      _buildInfoRow(Icons.school, 'Education', job.education!),
                      const SizedBox(height: 12),
                    ],
                    if (job.expectedSalary != null) ...[
                      _buildInfoRow(
                        Icons.attach_money,
                        'Expected Salary',
                        job.expectedSalary!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (job.availability != null) ...[
                      _buildInfoRow(
                        Icons.event_available,
                        'Availability',
                        job.availability!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (job.preferredLocation != null) ...[
                      _buildInfoRow(
                        Icons.map,
                        'Preferred Location',
                        job.preferredLocation!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Documents (CVs, certificates, uploads)
                    if (job.documentUrls != null && job.documentUrls!.isNotEmpty) ...[
                      _buildSection(
                        title: 'Documents',
                        child: _buildDocumentsList(job.documentUrls!),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],

                  // Farmer job specific fields
                  if (isFarmerJob) ...[
                    if (job.duration != null) ...[
                      _buildInfoRow(
                        Icons.schedule,
                        'Employment Type',
                        job.duration!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (job.positionsAvailable != null) ...[
                      _buildInfoRow(
                        Icons.people,
                        'Positions Available',
                        '${job.positionsAvailable}',
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (job.startDate != null) ...[
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Start Date',
                        Formatter.formatDate(job.startDate!),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (job.endDate != null) ...[
                      _buildInfoRow(
                        Icons.event,
                        'End Date',
                        Formatter.formatDate(job.endDate!),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (job.requirements != null &&
                        job.requirements!.isNotEmpty) ...[
                      _buildSection(
                        title: 'Requirements',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: job.requirements!
                              .map(
                                (req) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green.shade400,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(req)),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (job.benefits != null && job.benefits!.isNotEmpty) ...[
                      _buildSection(
                        title: 'Benefits',
                        child: _buildTagList(
                          job.benefits!,
                          color: Colors.green.shade100,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],

                  // Stats
                  if (!isApiJob) ...[
                    _buildSection(
                      title: 'Stats',
                      child: Row(
                        children: [
                          _buildStatItem(
                            Icons.visibility,
                            '${job.viewCount}',
                            'Views',
                          ),
                          const SizedBox(width: 24),
                          _buildStatItem(
                            Icons.people,
                            '${job.applicationCount}',
                            'Applications',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Posted date
                  Text(
                    'Posted on ${Formatter.formatDate(job.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildBottomActionBar() {
    final job = widget.job;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == job.userId;
    final isApiJob = job.isApiJob;
    final isFarmerJob = job.postType == JobPostType.farmerJob;

    if (isOwner) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _viewApplications,
                  icon: const Icon(Icons.people),
                  label: Text('Applications (${job.applicationCount})'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Contact button
            if (!isApiJob && job.userPhone != null) ...[
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () => _contactByPhone(job.userPhone!),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            // Apply/External link button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _applyOrOpenExternal,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isApiJob
                            ? Icons.open_in_new
                            : (_hasApplied ? Icons.check : Icons.send),
                      ),
                label: Text(
                  isApiJob
                      ? 'View on ${job.apiSource}'
                      : (isFarmerJob
                            ? (_hasApplied ? 'Already Applied' : 'Apply Now')
                            : (_hasApplied ? 'Already Applied' : 'Message')),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isApiJob
                      ? Colors.orange.shade700
                      : Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildStatusChip(JobStatus status) {
    Color color;
    String label;
    switch (status) {
      case JobStatus.approved:
        color = Colors.green;
        label = 'Active';
        break;
      case JobStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case JobStatus.rejected:
        color = Colors.red;
        label = 'Rejected';
        break;
      case JobStatus.expired:
        color = Colors.grey;
        label = 'Expired';
        break;
      case JobStatus.filled:
        color = Colors.blue;
        label = 'Filled';
        break;
    }
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildTypeChip(JobPostType type) {
    final isFarmerJob = type == JobPostType.farmerJob;
    return Chip(
      label: Text(
        isFarmerJob ? 'Hiring' : 'Seeking Work',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: isFarmerJob
          ? Colors.green.shade100
          : Colors.blue.shade100,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildCategoryChip(JobCategory category) {
    return Chip(
      label: Text(
        category.name[0].toUpperCase() + category.name.substring(1),
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.grey.shade200,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildTagList(List<String> items, {Color? color}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Chip(
          label: Text(item, style: const TextStyle(fontSize: 12)),
          backgroundColor: color ?? Colors.blue.shade100,
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  Widget _buildDocumentsList(List<String> urls) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final url = urls[index];
          return GestureDetector(
            onTap: () => _showDocumentPreview(url),
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.hardEdge,
              child: url.isNotEmpty
                  ? Image.network(url, fit: BoxFit.cover, errorBuilder: (c, e, s) => Center(child: Icon(Icons.broken_image, color: Colors.grey)))
                  : Center(child: Icon(Icons.insert_drive_file, color: Colors.grey)),
            ),
          );
        },
      ),
    );
  }

  void _showDocumentPreview(String url) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              InteractiveViewer(
                child: url.isNotEmpty
                    ? Image.network(url, fit: BoxFit.contain, errorBuilder: (c, e, s) => Container(padding: const EdgeInsets.all(24), child: const Text('Failed to load document')))
                    : const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No preview available'),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(value, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 18),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _applyOrOpenExternal() async {
    if (widget.job.isApiJob) {
      // Open external URL
      final url = widget.job.apiUrl;
      if (url != null) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
      return;
    }

    final job = widget.job;
    final isFarmerJob = job.postType == JobPostType.farmerJob;

    if (_hasApplied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You have already applied for this ${isFarmerJob ? 'job' : 'position'}.',
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to apply'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show apply dialog with CV upload option
    final coverLetterController = TextEditingController();
    File? selectedCV;
    String? cvFileName;
    bool isUploading = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isFarmerJob ? 'Apply for this Job' : 'Apply to Recruit',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFarmerJob
                          ? 'Send a message to the employer (optional):'
                          : 'Send a message to the job seeker (optional):',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: coverLetterController,
                      decoration: const InputDecoration(
                        hintText: 'Briefly describe why you are a good fit...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // CV Upload Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.upload_file,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Attach CV/Resume (Optional)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (cvFileName == null) ...[
                            OutlinedButton.icon(
                              onPressed: isUploading
                                  ? null
                                  : () async {
                                      final result = await FilePicker
                                          .pickFiles(
                                            type: FileType.custom,
                                            allowedExtensions: [
                                              'pdf',
                                              'doc',
                                              'docx',
                                            ],
                                            allowMultiple: false,
                                          );

                                      if (result != null &&
                                          result.files.single.path != null) {
                                        setDialogState(() {
                                          selectedCV = File(
                                            result.files.single.path!,
                                          );
                                          cvFileName = result.files.single.name;
                                        });
                                      }
                                    },
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Select File'),
                            ),
                            Text(
                              'Supported: PDF, DOC, DOCX',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.description,
                                    color: Colors.green.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      cvFileName!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!isUploading)
                                    IconButton(
                                      onPressed: () {
                                        setDialogState(() {
                                          selectedCV = null;
                                          cvFileName = null;
                                        });
                                      },
                                      icon: const Icon(Icons.close, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading
                      ? null
                      : () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isFarmerJob ? 'Apply' : 'Send'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      String? resumeUrl;

      // Upload CV if selected
      if (selectedCV != null) {
        try {
          resumeUrl = await _cloudinaryService.uploadCVDocument(
            file: selectedCV!,
            userId: user.uid,
            applicationId: DateTime.now().millisecondsSinceEpoch.toString(),
          );

          if (resumeUrl == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '⚠️ Failed to upload CV, but application will still be sent',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } catch (e) {
          developer.log('Error uploading CV: $e', name: 'JobDetailScreen');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '⚠️ CV upload failed, but application will still be sent',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      try {
        await _jobService.applyForJob(
          jobId: widget.job.id,
          jobTitle: widget.job.title,
          coverLetter: coverLetterController.text.trim().isNotEmpty
              ? coverLetterController.text.trim()
              : null,
          resumeUrl: resumeUrl,
        );

        setState(() {
          _hasApplied = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFarmerJob
                    ? (resumeUrl != null
                          ? 'Application with CV sent successfully!'
                          : 'Application sent successfully!')
                    : (resumeUrl != null
                          ? 'Message with CV sent successfully!'
                          : 'Message sent successfully!'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _contactByPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone app')),
        );
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    }
  }

  Future<void> _launchWhatsApp(String number) async {
    // Remove spaces and ensure it starts with +
    final cleanNumber = number.replaceAll(RegExp(r'\s'), '');
    final uri = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  Widget _buildContactInfoSection(JobPost job) {
    final hasContact =
        job.userPhone != null ||
        job.contactEmail != null ||
        job.website != null ||
        job.whatsappNumber != null ||
        job.facebookUrl != null ||
        job.twitterUrl != null ||
        job.linkedinUrl != null;

    if (!hasContact) {
      return Text(
        'No additional contact information provided',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Contact Buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (job.userPhone != null)
              _buildContactButton(
                icon: Icons.phone,
                label: 'Call',
                color: Colors.green,
                onTap: () => _contactByPhone(job.userPhone!),
              ),
            if (job.contactEmail != null)
              _buildContactButton(
                icon: Icons.email,
                label: 'Email',
                color: Colors.orange,
                onTap: () => _launchEmail(job.contactEmail!),
              ),
            if (job.whatsappNumber != null)
              _buildContactButton(
                icon: Icons.chat,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _launchWhatsApp(job.whatsappNumber!),
              ),
            if (job.website != null)
              _buildContactButton(
                icon: Icons.language,
                label: 'Website',
                color: Colors.blue,
                onTap: () => _launchUrl(job.website!),
              ),
          ],
        ),
        // Social Media Links
        if (job.facebookUrl != null ||
            job.twitterUrl != null ||
            job.linkedinUrl != null) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Social Media',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (job.facebookUrl != null)
                _buildSocialLinkChip(
                  icon: Icons.facebook,
                  label: 'Facebook',
                  color: Colors.blue,
                  onTap: () => _launchUrl(job.facebookUrl!),
                ),
              if (job.twitterUrl != null)
                _buildSocialLinkChip(
                  icon: Icons.alternate_email,
                  label: 'Twitter/X',
                  color: Colors.lightBlue,
                  onTap: () => _launchUrl(job.twitterUrl!),
                ),
              if (job.linkedinUrl != null)
                _buildSocialLinkChip(
                  icon: Icons.business,
                  label: 'LinkedIn',
                  color: Colors.blueAccent,
                  onTap: () => _launchUrl(job.linkedinUrl!),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinkChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Chip(
        avatar: Icon(icon, color: color, size: 16),
        label: Text(label, style: TextStyle(fontSize: 12, color: color)),
        backgroundColor: color.withOpacity(0.1),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Job?'),
          content: Text(
            'Are you sure you want to delete "${widget.job.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _jobService.deleteJob(widget.job.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job deleted successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            JobPostScreen(postType: widget.job.postType, jobToEdit: widget.job),
      ),
    );
  }

  void _viewApplications() {
    // Navigate to applications screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobApplicationsScreen(jobId: widget.job.id),
      ),
    );
  }
}
