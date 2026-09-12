import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'farmer_model.dart';
import '../../app/utils/formatters.dart';
import '../../services/farmer_reputation_service.dart';
import '../../models/academy/certificate_model.dart';
import '../../services/academy/academy_progress_service.dart';
import '../academy/certificate_screen.dart';

class FarmerAboutScreen extends StatefulWidget {
  final FarmerModel farmer;

  const FarmerAboutScreen({super.key, required this.farmer});

  @override
  State<FarmerAboutScreen> createState() => _FarmerAboutScreenState();
}

class _FarmerAboutScreenState extends State<FarmerAboutScreen> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _farmerStatusStream;
  late final Future<FarmerStatus> _statusFuture;

  @override
  void initState() {
    super.initState();
    _farmerStatusStream = FirebaseFirestore.instance
        .collection('farmers')
        .doc(widget.farmer.id)
        .snapshots();

    _statusFuture = FarmerReputationService.getFarmerStatus(widget.farmer.id);
  }

  /// Helper method to format location data properly
  String _formatLocation(dynamic location) {
    return Formatter.formatLocation(location);
  }


  // Helper function to launch URLs
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        developer.log('Could not launch $url', name: 'FarmerAboutScreen');
      }
    } catch (e) {
      developer.log('Error launching URL: $e', name: 'FarmerAboutScreen');
    }
  }

  // Format date range without seconds
  String formatDateRange(String? start, String? end) {
    final s = (start?.isNotEmpty ?? false) ? _formatDate(start!) : 'N/A';
    final e = (end?.isNotEmpty ?? false) ? _formatDate(end!) : 'Present';
    return '$s – $e';
  }

  // Format individual date without seconds
  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Format datetime to normal time without seconds (handles various formats)
  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'Unknown';

    DateTime parsedDateTime;
    if (dateTime is Timestamp) {
      parsedDateTime = dateTime.toDate();
    } else if (dateTime is DateTime) {
      parsedDateTime = dateTime;
    } else if (dateTime is String) {
      try {
        parsedDateTime = DateTime.parse(dateTime);
      } catch (e) {
        return 'Unknown';
      }
    } else {
      return 'Unknown';
    }

    return '${parsedDateTime.day}/${parsedDateTime.month}/${parsedDateTime.year} ${parsedDateTime.hour.toString().padLeft(2, '0')}:${parsedDateTime.minute.toString().padLeft(2, '0')}';
  }

  // Use workList or fallback to legacy single fields
  List<WorkExperience> getWorkList() {
    if (widget.farmer.workList.isNotEmpty) return widget.farmer.workList;

    if ((widget.farmer.work ?? '').isNotEmpty ||
        (widget.farmer.experienceLegacy ?? '').isNotEmpty) {
      return [
        WorkExperience(
          role: widget.farmer.work ?? '',
          company: '', // no legacy company
          description: widget.farmer.experienceLegacy ?? '',
          startDate: '',
          endDate: '',
        ),
      ];
    }
    return [];
  }

  // Use educationList or fallback to legacy fields
  List<EducationEntry> getEducationList() {
    if (widget.farmer.educationList.isNotEmpty) return widget.farmer.educationList;

    final List<EducationEntry> list = [];

    if ((widget.farmer.educationLegacy ?? '').isNotEmpty ||
        (widget.farmer.college ?? '').isNotEmpty) {
      list.add(
        EducationEntry(
          degree: widget.farmer.educationLegacy ?? '',
          institution: widget.farmer.college ?? '',
          description: '', // No legacy description for education
        ),
      );
    }

    if ((widget.farmer.university ?? '').isNotEmpty) {
      list.add(
        EducationEntry(
          degree: 'University',
          institution: widget.farmer.university,
          description: '',
        ),
      );
    }

    if ((widget.farmer.highSchool ?? '').isNotEmpty) {
      list.add(
        EducationEntry(
          degree: 'High School',
          institution: widget.farmer.highSchool,
          description: '',
        ),
      );
    }

    return list;
  }

  Widget _buildStatusWidget(FarmerStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: status.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Status: ${status.label}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: status.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _getStatusDescription(status),
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final workList = getWorkList();
    final educationList = getEducationList();

    // Debug work data
    developer.log(
      '🔍 DEBUG: workList length: ${workList.length}',
      name: 'FarmerAboutScreen',
    );
    for (int i = 0; i < workList.length; i++) {
      final work = workList[i];
      developer.log(
        '🔍 DEBUG: Work $i - role: "${work.role}", description: "${work.description}"',
        name: 'FarmerAboutScreen',
      );
    }
    developer.log(
      '🔍 DEBUG: widget.farmer.workList length: ${widget.farmer.workList.length}',
      name: 'FarmerAboutScreen',
    );
    developer.log(
      '🔍 DEBUG: widget.farmer.work: "${widget.farmer.work}"',
      name: 'FarmerAboutScreen',
    );
    developer.log(
      '🔍 DEBUG: widget.farmer.experienceLegacy: "${widget.farmer.experienceLegacy}"',
      name: 'FarmerAboutScreen',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("About ${widget.farmer.name}"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- WORK ----------------
            if (workList.isNotEmpty) ...[
              const Text(
                "Work",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...workList.map(
                (job) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("💼 ", style: TextStyle(fontSize: 18)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${job.role}${job.company?.isNotEmpty == true ? ', ${job.company}' : ''}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (job.description?.isNotEmpty ?? false)
                              Text(
                                job.description!,
                                style: const TextStyle(fontSize: 15),
                              ),
                            Text(
                              formatDateRange(job.startDate, job.endDate),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ---------------- EDUCATION ----------------
            if (educationList.isNotEmpty) ...[
              const Text(
                "Education",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...educationList.map(
                (edu) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("🎓 ", style: TextStyle(fontSize: 18)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              edu.degree?.isNotEmpty == true
                                  ? edu.degree!
                                  : 'No degree specified',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (edu.institution?.isNotEmpty ?? false)
                              Text(
                                edu.institution!,
                                style: const TextStyle(fontSize: 15),
                              ),
                            if (edu.description?.isNotEmpty ?? false)
                              Text(
                                edu.description!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            Text(
                              formatDateRange(edu.startDate, edu.endDate),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            if (edu.certificate?.isNotEmpty ?? false)
                              Text(
                                "Certificate: ${edu.certificate}",
                                style: const TextStyle(fontSize: 14),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ---------------- AGRIBASE ACADEMY CERTIFICATES & BADGES ----------------
            _buildAcademySection(),
            const SizedBox(height: 20),

            // ---------------- LOCATION ----------------
            if (widget.farmer.location?.isNotEmpty ?? false) ...[
              Text(_formatLocation(widget.farmer.location!), style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
            ],

            // ---------------- WEBSITE ----------------
            if ((widget.farmer.website ?? '').isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.language, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _launchUrl(widget.farmer.website!),
                      child: Text(
                        widget.farmer.website!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // ---------------- FARMER REPUTATION STATUS ----------------
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _farmerStatusStream,
              builder: (context, snapshot) {
                final liveStatusValue = snapshot.data?.data()?['reputationStatus'] as String?;
                final liveStatus = _statusFromString(liveStatusValue);

                if (liveStatus != null) {
                  return _buildStatusWidget(liveStatus);
                }

                return FutureBuilder<FarmerStatus>(
                  future: _statusFuture,
                  builder: (context, statusSnapshot) {
                    final fallbackStatus = _statusFromString(widget.farmer.status);
                    final status = statusSnapshot.data ?? fallbackStatus;

                    if (status == null) {
                      if (statusSnapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      return const SizedBox.shrink();
                    }

                    return _buildStatusWidget(status);
                  },
                );
              },
            ),

            // ---------------- SOCIAL LINKS ----------------
            if (widget.farmer.socialLinks.isNotEmpty) ...[
              const Text(
                "Social Links",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...widget.farmer.socialLinks.map(
                (link) => Row(
                  children: [
                    const Icon(Icons.link, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _launchUrl(link),
                        child: Text(
                          link,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ---------------- PHONE ----------------
            if ((widget.farmer.phone ?? '').isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(widget.farmer.phone!, style: const TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // ---------------- COOPERATIVE ----------------
            if ((widget.farmer.cooperative ?? '').isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.group, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Cooperative: ${widget.farmer.cooperative!}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // ---------------- STATUS ----------------
            if ((widget.farmer.status ?? '').isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.farmer.status!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // ---------------- ACCOUNT CREATION DATE ----------------
            if (widget.farmer.createdAt != null) ...[
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    "Joined: ${_formatDateTime(widget.farmer.createdAt!)}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAcademySection() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid != null && currentUid == widget.farmer.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text("🎓 ", style: TextStyle(fontSize: 18)),
            Text(
              "Farming Academy Certificates",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Certificates stream
        StreamBuilder<List<CertificateModel>>(
          stream: AcademyProgressService.instance.streamUserCertificates(widget.farmer.id),
          builder: (context, certSnap) {
            if (certSnap.connectionState == ConnectionState.waiting && !certSnap.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                ),
              );
            }

            final certs = certSnap.data ?? [];

            if (certs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium_outlined, color: Colors.grey.shade400, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isOwner
                          ? "Complete AgriBase Academy courses to display certificates here."
                          : "No rewarded certificates yet.",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: certs.map((cert) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.amber.shade400, width: 1.2),
                  ),
                  color: Colors.amber.shade50.withValues(alpha: 0.35),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber.shade700, width: 1.2),
                      ),
                      child: Center(
                        child: Text(
                          cert.badgeName.split(' ').first,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    title: Text(
                      cert.courseTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        "ID: ${cert.certificateNumber} • ${_formatDateTime(cert.issuedAt)}",
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CertificateScreen(certificate: cert),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // Get status description for display
  String _getStatusDescription(FarmerStatus status) {
    switch (status) {
      case FarmerStatus.good:
        return 'This farmer has a clean record and follows community guidelines.';
      case FarmerStatus.warning:
        return 'This farmer has some violations and is being monitored.';
      case FarmerStatus.bad:
        return 'This farmer has multiple violations and has limited privileges.';
    }
  }

  FarmerStatus? _statusFromString(String? statusValue) {
    switch (statusValue?.toLowerCase()) {
      case 'warning':
        return FarmerStatus.warning;
      case 'bad':
        return FarmerStatus.bad;
      case 'good':
        return FarmerStatus.good;
      default:
        return null;
    }
  }
}

