import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/job_model.dart';

/// Service for managing job postings in Firebase
class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _jobsCollection => _firestore.collection('jobs');
  CollectionReference get _applicationsCollection =>
      _firestore.collection('job_applications');

  /// Post a new job (requires admin approval)
  Future<JobPost> postJob({
    required JobPostType postType,
    required JobCategory category,
    required String title,
    required String description,
    required String location,
    String? locationState,
    String? locationCountry,
    double? latitude,
    double? longitude,
    String? farmName,
    double? salary,
    String? salaryPeriod,
    String? duration,
    DateTime? startDate,
    DateTime? endDate,
    int? positionsAvailable,
    List<String>? requirements,
    List<String>? benefits,
    String? skills,
    String? experience,
    String? education,
    String? expectedSalary,
    String? availability,
    String? preferredLocation,
    // Contact Info
    String? contactEmail,
    String? website,
    String? facebookUrl,
    String? twitterUrl,
    String? linkedinUrl,
    String? whatsappNumber,
    // Documents
    String? resumeUrl,
    String? coverLetterUrl,
    List<String>? documentUrls,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user info
      final farmerDoc = await _firestore
          .collection('farmers')
          .doc(user.uid)
          .get();
      final farmerData = farmerDoc.data() as Map<String, dynamic>?;

      final userName =
          farmerData?['user_name'] ?? farmerData?['name'] ?? 'Unknown';
      final userProfilePic =
          farmerData?['profilePic'] ?? farmerData?['photoUrl'];
      final userPhone =
          farmerData?['phone'] ??
          farmerData?['contact_number' ?? farmerData?['phone_number']];

      // Calculate expiration date (30 days from now)
      final expiresAt = DateTime.now().add(const Duration(days: 30));

      final jobRef = _jobsCollection.doc();
      final job = JobPost(
        id: jobRef.id,
        userId: user.uid,
        userName: userName,
        userProfilePic: userProfilePic,
        userPhone: userPhone,
        postType: postType,
        status: JobStatus.pending,
        category: category,
        title: title,
        description: description,
        location: location,
        locationState: locationState,
        locationCountry: locationCountry ?? 'Zimbabwe',
        latitude: latitude,
        longitude: longitude,
        farmName: farmName,
        salary: salary,
        salaryPeriod: salaryPeriod,
        duration: duration,
        startDate: startDate,
        endDate: endDate,
        positionsAvailable: positionsAvailable,
        requirements: requirements,
        benefits: benefits,
        skills: skills,
        experience: experience,
        education: education,
        expectedSalary: expectedSalary,
        availability: availability,
        preferredLocation: preferredLocation,
        // Contact Info
        contactEmail: contactEmail,
        website: website,
        facebookUrl: facebookUrl,
        twitterUrl: twitterUrl,
        linkedinUrl: linkedinUrl,
        whatsappNumber: whatsappNumber,
        // Documents
        resumeUrl: resumeUrl,
        coverLetterUrl: coverLetterUrl,
        documentUrls: documentUrls,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
      );

      await jobRef.set(job.toMap());

      // Send notification to admin
      await _notifyAdminOfNewJob(job);

      developer.log(
        '✅ Job posted: ${job.title} (ID: ${job.id})',
        name: 'JobService',
      );

      return job;
    } catch (e) {
      developer.log('❌ Error posting job: $e', name: 'JobService');
      throw Exception('Failed to post job: $e');
    }
  }

  /// Get all approved jobs (for main job feed)
  Stream<List<JobPost>> getApprovedJobs({
    JobPostType? type,
    JobCategory? category,
    String? location,
    int? limit,
  }) {
    Query query = _jobsCollection
        .where('status', isEqualTo: JobStatus.approved.name)
        .where('isApiJob', isEqualTo: false)
        .orderBy('createdAt', descending: true);

    if (type != null) {
      query = query.where('postType', isEqualTo: type.name);
    }

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => JobPost.fromDocument(doc))
          .where((job) => !job.isExpired)
          .toList();
    });
  }

  /// Get jobs for specific user
  Stream<List<JobPost>> getUserJobs(String userId) {
    return _jobsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => JobPost.fromDocument(doc)).toList(),
        );
  }

  /// Get pending jobs (for admin)
  Stream<List<JobPost>> getPendingJobs() {
    return _jobsCollection
        .where('status', isEqualTo: JobStatus.pending.name)
        .where('isApiJob', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => JobPost.fromDocument(doc)).toList(),
        );
  }

  /// Get single job by ID
  Future<JobPost?> getJobById(String jobId) async {
    try {
      final doc = await _jobsCollection.doc(jobId).get();
      if (doc.exists) {
        return JobPost.fromDocument(doc);
      }
      return null;
    } catch (e) {
      developer.log('❌ Error getting job: $e', name: 'JobService');
      return null;
    }
  }

  /// Approve job (admin only)
  Future<void> approveJob(String jobId, String adminId) async {
    try {
      await _jobsCollection.doc(jobId).update({
        'status': JobStatus.approved.name,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to job poster
      final job = await getJobById(jobId);
      if (job != null) {
        await _notifyUserOfJobApproval(job);
      }

      developer.log('✅ Job approved: $jobId', name: 'JobService');
    } catch (e) {
      developer.log('❌ Error approving job: $e', name: 'JobService');
      throw Exception('Failed to approve job: $e');
    }
  }

  /// Reject job (admin only)
  Future<void> rejectJob(String jobId, {String? reason}) async {
    try {
      await _jobsCollection.doc(jobId).update({
        'status': JobStatus.rejected.name,
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to job poster
      final job = await getJobById(jobId);
      if (job != null) {
        await _notifyUserOfJobRejection(job, reason);
      }

      developer.log('❌ Job rejected: $jobId', name: 'JobService');
    } catch (e) {
      developer.log('❌ Error rejecting job: $e', name: 'JobService');
      throw Exception('Failed to reject job: $e');
    }
  }

  /// Mark job as filled
  Future<void> markJobAsFilled(String jobId) async {
    try {
      await _jobsCollection.doc(jobId).update({
        'status': JobStatus.filled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log('✅ Job marked as filled: $jobId', name: 'JobService');
    } catch (e) {
      developer.log('❌ Error marking job as filled: $e', name: 'JobService');
      throw Exception('Failed to mark job as filled: $e');
    }
  }

  /// Increment job view count
  Future<void> incrementViewCount(String jobId) async {
    try {
      await _jobsCollection.doc(jobId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      developer.log('❌ Error incrementing view count: $e', name: 'JobService');
    }
  }

  /// Apply for a job
  Future<JobApplication> applyForJob({
    required String jobId,
    required String jobTitle,
    String? coverLetter,
    String? resumeUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user info
      final farmerDoc = await _firestore
          .collection('farmers')
          .doc(user.uid)
          .get();
      final farmerData = farmerDoc.data() as Map<String, dynamic>?;

      final applicantName =
          farmerData?['user_name'] ?? farmerData?['name'] ?? 'Unknown';
      final applicantPhone =
          farmerData?['phone'] ??
          farmerData?['contact_number'] ??
          farmerData?['phone_number'];
      final applicantEmail = farmerData?['email'];
      final applicantProfilePic =
          farmerData?['profilePic'] ?? farmerData?['photoUrl'];

      final applicationRef = _applicationsCollection.doc();
      final application = JobApplication(
        id: applicationRef.id,
        jobId: jobId,
        jobTitle: jobTitle,
        applicantId: user.uid,
        applicantName: applicantName,
        applicantPhone: applicantPhone,
        applicantEmail: applicantEmail,
        applicantProfilePic: applicantProfilePic,
        coverLetter: coverLetter,
        resumeUrl: resumeUrl,
        appliedAt: DateTime.now(),
      );

      await applicationRef.set(application.toMap());

      // Update job application count and add user to applied list
      await _jobsCollection.doc(jobId).update({
        'applicationCount': FieldValue.increment(1),
        'appliedUserIds': FieldValue.arrayUnion([user.uid]),
      });

      // Notify job poster
      await _notifyJobPosterOfApplication(jobId, application);

      developer.log(
        '✅ Job application submitted: ${application.id}',
        name: 'JobService',
      );

      return application;
    } catch (e) {
      developer.log('❌ Error applying for job: $e', name: 'JobService');
      throw Exception('Failed to apply for job: $e');
    }
  }

  /// Get applications for a specific job
  Stream<List<JobApplication>> getJobApplications(String jobId) {
    return _applicationsCollection
        .where('jobId', isEqualTo: jobId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => JobApplication.fromDocument(doc))
              .toList(),
        );
  }

  /// Get applications by applicant
  Stream<List<JobApplication>> getUserApplications(String userId) {
    return _applicationsCollection
        .where('applicantId', isEqualTo: userId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => JobApplication.fromDocument(doc))
              .toList(),
        );
  }

  /// Update application status and notify applicant
  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
    String? response,
  }) async {
    try {
      // Get application details first for notification
      final applicationDoc = await _applicationsCollection
          .doc(applicationId)
          .get();
      final applicationData = applicationDoc.data() as Map<String, dynamic>?;

      await _applicationsCollection.doc(applicationId).update({
        'status': status,
        'employerResponse': response,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Notify applicant if rejected
      if (status == 'rejected' && applicationData != null) {
        final applicantId = applicationData['applicantId'] as String?;
        final jobTitle =
            applicationData['jobTitle'] as String? ?? 'Unknown Job';
        if (applicantId != null) {
          await _notifyApplicantOfRejection(
            applicantId: applicantId,
            jobTitle: jobTitle,
            employerResponse: response,
          );
        }
      }

      developer.log(
        '✅ Application status updated: $applicationId -> $status',
        name: 'JobService',
      );
    } catch (e) {
      developer.log(
        '❌ Error updating application status: $e',
        name: 'JobService',
      );
      throw Exception('Failed to update application status: $e');
    }
  }

  /// Mark applicantSeen=true for all accepted/rejected applications of the given user
  Future<void> markApplicationsSeenForUser(String userId) async {
    try {
      final snapshot = await _applicationsCollection
          .where('applicantId', isEqualTo: userId)
          .where('status', whereIn: ['accepted', 'rejected'])
          .where('applicantSeen', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'applicantSeen': true});
      }
      await batch.commit();
    } catch (e) {
      developer.log('❌ Error marking applications seen: $e', name: 'JobService');
    }
  }

  /// Delete job (only by owner or admin)
  Future<void> deleteJob(String jobId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verify ownership
      final job = await getJobById(jobId);
      if (job == null) throw Exception('Job not found');

      // Check if user is owner or admin
      final farmerDoc = await _firestore
          .collection('farmers')
          .doc(user.uid)
          .get();
      final isAdmin =
          (farmerDoc.data()?['role'] ?? '').toString().toLowerCase() == 'admin';

      if (job.userId != user.uid && !isAdmin) {
        throw Exception('Not authorized to delete this job');
      }

      // Delete related applications
      final applications = await _applicationsCollection
          .where('jobId', isEqualTo: jobId)
          .get();
      final batch = _firestore.batch();

      for (final doc in applications.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(_jobsCollection.doc(jobId));
      await batch.commit();

      developer.log('✅ Job deleted: $jobId', name: 'JobService');
    } catch (e) {
      developer.log('❌ Error deleting job: $e', name: 'JobService');
      throw Exception('Failed to delete job: $e');
    }
  }

  /// Update existing job (only by owner or admin)
  Future<void> updateJob({
    required String jobId,
    required JobCategory category,
    required String title,
    required String description,
    required String location,
    String? locationState,
    String? userPhone,
    String? farmName,
    double? salary,
    String? salaryPeriod,
    String? duration,
    DateTime? startDate,
    DateTime? endDate,
    int? positionsAvailable,
    List<String>? requirements,
    List<String>? benefits,
    String? skills,
    String? experience,
    String? education,
    String? expectedSalary,
    String? availability,
    String? preferredLocation,
    // Contact Info
    String? contactEmail,
    String? website,
    String? facebookUrl,
    String? twitterUrl,
    String? linkedinUrl,
    String? whatsappNumber,
    // Documents
    String? resumeUrl,
    String? coverLetterUrl,
    List<String>? documentUrls,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verify ownership
      final job = await getJobById(jobId);
      if (job == null) throw Exception('Job not found');

      // Check if user is owner or admin
      final farmerDoc = await _firestore
          .collection('farmers')
          .doc(user.uid)
          .get();
      final isAdmin =
          (farmerDoc.data()?['role'] ?? '').toString().toLowerCase() == 'admin';

      if (job.userId != user.uid && !isAdmin) {
        throw Exception('Not authorized to edit this job');
      }

      // Build update data
      final updateData = <String, dynamic>{
        'category': category.name,
        'title': title,
        'description': description,
        'location': location,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add optional fields if provided
      if (locationState != null) updateData['locationState'] = locationState;
      if (userPhone != null) updateData['userPhone'] = userPhone;
      if (farmName != null) updateData['farmName'] = farmName;
      if (salary != null) updateData['salary'] = salary;
      if (salaryPeriod != null) updateData['salaryPeriod'] = salaryPeriod;
      if (duration != null) updateData['duration'] = duration;
      if (startDate != null)
        updateData['startDate'] = Timestamp.fromDate(startDate);
      if (endDate != null) updateData['endDate'] = Timestamp.fromDate(endDate);
      if (positionsAvailable != null)
        updateData['positionsAvailable'] = positionsAvailable;
      if (requirements != null) updateData['requirements'] = requirements;
      if (benefits != null) updateData['benefits'] = benefits;
      if (skills != null) updateData['skills'] = skills;
      if (experience != null) updateData['experience'] = experience;
      if (education != null) updateData['education'] = education;
      if (expectedSalary != null) updateData['expectedSalary'] = expectedSalary;
      if (availability != null) updateData['availability'] = availability;
      if (preferredLocation != null)
        updateData['preferredLocation'] = preferredLocation;
      // Contact Info
      if (contactEmail != null) updateData['contactEmail'] = contactEmail;
      if (website != null) updateData['website'] = website;
      if (facebookUrl != null) updateData['facebookUrl'] = facebookUrl;
      if (twitterUrl != null) updateData['twitterUrl'] = twitterUrl;
      if (linkedinUrl != null) updateData['linkedinUrl'] = linkedinUrl;
      if (whatsappNumber != null) updateData['whatsappNumber'] = whatsappNumber;
      // Documents
      if (resumeUrl != null) updateData['resumeUrl'] = resumeUrl;
      if (coverLetterUrl != null) updateData['coverLetterUrl'] = coverLetterUrl;
      if (documentUrls != null) updateData['documentUrls'] = documentUrls;

      await _jobsCollection.doc(jobId).update(updateData);

      developer.log('✅ Job updated: $jobId', name: 'JobService');
    } catch (e) {
      developer.log('❌ Error updating job: $e', name: 'JobService');
      throw Exception('Failed to update job: $e');
    }
  }

  /// Search jobs by query string
  Future<List<JobPost>> searchJobs(String query, {int limit = 20}) async {
    try {
      // Get all approved jobs and filter locally
      // Note: For production, consider using Algolia or similar for full-text search
      final snapshot = await _jobsCollection
          .where('status', isEqualTo: JobStatus.approved.name)
          .limit(limit * 3)
          .get();

      final jobs = snapshot.docs
          .map((doc) => JobPost.fromDocument(doc))
          .toList();

      // Filter by search query
      final searchLower = query.toLowerCase();
      return jobs.where((job) {
        return job.title.toLowerCase().contains(searchLower) ||
            job.description.toLowerCase().contains(searchLower) ||
            job.location.toLowerCase().contains(searchLower) ||
            job.categoryDisplay.toLowerCase().contains(searchLower) ||
            job.userName.toLowerCase().contains(searchLower);
      }).toList();
    } catch (e) {
      developer.log('❌ Error searching jobs: $e', name: 'JobService');
      return [];
    }
  }

  /// Notify admin of new job posting
  Future<void> _notifyAdminOfNewJob(JobPost job) async {
    try {
      final notificationRef = _firestore
          .collection('notifications')
          .doc('admin')
          .collection('items')
          .doc();

      final typeDisplay = job.postType == JobPostType.farmerJob
          ? 'job posting'
          : 'job seeker profile';

      await notificationRef.set({
        'id': notificationRef.id,
        'title': '🆕 New $typeDisplay needs approval',
        'body': '${job.userName} posted: "${job.title}" in ${job.location}',
        'type': 'job_pending_approval',
        'relatedType': 'job',
        'jobId': job.id,
        'jobTitle': job.title,
        'jobType': job.postType.name,
        'farmerId': job.userId,
        'farmerName': job.userName,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'requiresAction': true,
        'actionText': 'Review Job',
        'actionScreen': 'admin_job_verification',
      });

      developer.log(
        '🔔 Admin notified of new job: ${job.id}',
        name: 'JobService',
      );
    } catch (e) {
      developer.log('❌ Error notifying admin: $e', name: 'JobService');
    }
  }

  /// Notify user of job approval
  Future<void> _notifyUserOfJobApproval(JobPost job) async {
    try {
      final notificationRef = _firestore
          .collection('notifications')
          .doc(job.userId)
          .collection('items')
          .doc();

      final typeDisplay = job.postType == JobPostType.farmerJob
          ? 'job posting'
          : 'job seeker profile';

      await notificationRef.set({
        'id': notificationRef.id,
        'title': '✅ $typeDisplay Approved',
        'body':
            'Your "$typeDisplay" "${job.title}" has been approved and is now visible to others.',
        'type': 'job_approved',
        'relatedType': 'job',
        'jobId': job.id,
        'jobTitle': job.title,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'requiresAction': true,
        'actionText': 'View Job',
        'actionScreen': 'job_detail',
      });

      developer.log(
        '🔔 User notified of job approval: ${job.userId}',
        name: 'JobService',
      );
    } catch (e) {
      developer.log(
        '❌ Error notifying user of approval: $e',
        name: 'JobService',
      );
    }
  }

  /// Notify user of job rejection
  Future<void> _notifyUserOfJobRejection(JobPost job, String? reason) async {
    try {
      final notificationRef = _firestore
          .collection('notifications')
          .doc(job.userId)
          .collection('items')
          .doc();

      final typeDisplay = job.postType == JobPostType.farmerJob
          ? 'job posting'
          : 'job seeker profile';

      await notificationRef.set({
        'id': notificationRef.id,
        'title': '❌ $typeDisplay Not Approved',
        'body':
            reason ??
            'Your "$typeDisplay" "${job.title}" was not approved. Please review and resubmit.',
        'type': 'job_rejected',
        'relatedType': 'job',
        'jobId': job.id,
        'jobTitle': job.title,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      developer.log(
        '🔔 User notified of job rejection: ${job.userId}',
        name: 'JobService',
      );
    } catch (e) {
      developer.log(
        '❌ Error notifying user of rejection: $e',
        name: 'JobService',
      );
    }
  }

  /// Notify applicant that their job application was rejected
  Future<void> _notifyApplicantOfRejection({
    required String applicantId,
    required String jobTitle,
    String? employerResponse,
  }) async {
    try {
      final notificationRef = _firestore
          .collection('notifications')
          .doc(applicantId)
          .collection('items')
          .doc();

      await notificationRef.set({
        'id': notificationRef.id,
        'title': '💼 Application Not Accepted',
        'body':
            employerResponse ??
            'Your application for "$jobTitle" was not accepted.',
        'type': 'application_rejected',
        'relatedType': 'job',
        'jobTitle': jobTitle,
        'employerResponse': employerResponse,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      developer.log(
        '🔔 Applicant notified of rejection: $applicantId',
        name: 'JobService',
      );
    } catch (e) {
      developer.log(
        '❌ Error notifying applicant of rejection: $e',
        name: 'JobService',
      );
    }
  }

  /// Notify job poster of new application
  Future<void> _notifyJobPosterOfApplication(
    String jobId,
    JobApplication application,
  ) async {
    try {
      final job = await getJobById(jobId);
      if (job == null) return;

      final notificationRef = _firestore
          .collection('notifications')
          .doc(job.userId)
          .collection('items')
          .doc();

      await notificationRef.set({
        'id': notificationRef.id,
        'title': '📩 New Application Received',
        'body': '${application.applicantName} applied for "${job.title}"',
        'type': 'job_application',
        'relatedType': 'job',
        'jobId': jobId,
        'jobTitle': job.title,
        'applicantId': application.applicantId,
        'applicantName': application.applicantName,
        'applicationId': application.id,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'requiresAction': true,
        'actionText': 'View Application',
        'actionScreen': 'job_applications',
      });

      developer.log(
        '🔔 Job poster notified of application: ${job.userId}',
        name: 'JobService',
      );
    } catch (e) {
      developer.log('❌ Error notifying job poster: $e', name: 'JobService');
    }
  }
}
