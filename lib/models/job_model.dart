import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for job posting types
enum JobPostType {
  farmerJob, // Farmer posting to find helpers/workers
  jobSeeker, // Job seeker posting to find employment
}

/// Enum for job approval status
enum JobStatus {
  pending, // Awaiting admin approval
  approved, // Approved and visible
  rejected, // Rejected by admin
  expired, // Past deadline
  filled, // Position filled
}

/// Enum for job types/categories
enum JobCategory {
  generalLabor,
  harvesting,
  planting,
  irrigation,
  livestock,
  machinery,
  technical,
  management,
  sales,
  other,
}

/// Model for job postings - both farmer jobs and job seeker profiles
class JobPost {
  final String id;
  final String userId;
  final String userName;
  final String? userProfilePic;
  final String? userPhone;
  final JobPostType postType;
  final JobStatus status;
  final JobCategory category;

  // Job details
  final String title;
  final String description;
  final String location;
  final String? locationState;
  final String? locationCountry;
  final double? latitude;
  final double? longitude;

  // For farmer jobs
  final String? farmName;
  final double? salary;
  final String? salaryPeriod; // hourly, daily, weekly, monthly
  final String? duration; // temporary, permanent, seasonal
  final DateTime? startDate;
  final DateTime? endDate;
  final int? positionsAvailable;
  final List<String>? requirements;
  final List<String>? benefits;

  // For job seekers
  final String? skills;
  final String? experience;
  final String? education;
  final String? expectedSalary;
  final String? availability;
  final String? preferredLocation;

  // Contact Information (for both types)
  final String? contactEmail;
  final String? website;
  final String? facebookUrl;
  final String? twitterUrl;
  final String? linkedinUrl;
  final String? whatsappNumber;

  // Documents (for job seekers - CV, certificates, etc.)
  final String? resumeUrl;
  final String? coverLetterUrl;
  final List<String>? documentUrls;

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime? expiresAt;
  final int viewCount;
  final int applicationCount;
  final List<String>? appliedUserIds;

  // For API jobs (Adzuna)
  final bool isApiJob;
  final String? apiSource; // 'adzuna', etc.
  final String? apiId;
  final String? apiUrl;
  final DateTime? apiCachedAt;

  const JobPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfilePic,
    this.userPhone,
    required this.postType,
    required this.status,
    required this.category,
    required this.title,
    required this.description,
    required this.location,
    this.locationState,
    this.locationCountry,
    this.latitude,
    this.longitude,
    this.farmName,
    this.salary,
    this.salaryPeriod,
    this.duration,
    this.startDate,
    this.endDate,
    this.positionsAvailable,
    this.requirements,
    this.benefits,
    this.skills,
    this.experience,
    this.education,
    this.expectedSalary,
    this.availability,
    this.preferredLocation,
    // Contact Info
    this.contactEmail,
    this.website,
    this.facebookUrl,
    this.twitterUrl,
    this.linkedinUrl,
    this.whatsappNumber,
    // Documents
    this.resumeUrl,
    this.coverLetterUrl,
    this.documentUrls,
    required this.createdAt,
    this.updatedAt,
    this.approvedAt,
    this.approvedBy,
    this.expiresAt,
    this.viewCount = 0,
    this.applicationCount = 0,
    this.appliedUserIds,
    this.isApiJob = false,
    this.apiSource,
    this.apiId,
    this.apiUrl,
    this.apiCachedAt,
  });

  /// Factory from Firestore document
  factory JobPost.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return JobPost.fromMap(data, doc.id);
  }

  /// Factory from JSON map
  factory JobPost.fromMap(Map<String, dynamic> map, String id) {
    return JobPost(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userProfilePic: map['userProfilePic'],
      userPhone: map['userPhone'],
      postType: _parsePostType(map['postType']),
      status: _parseStatus(map['status']),
      category: _parseCategory(map['category']),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      locationState: map['locationState'],
      locationCountry: map['locationCountry'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      farmName: map['farmName'],
      salary: map['salary']?.toDouble(),
      salaryPeriod: map['salaryPeriod'],
      duration: map['duration'],
      startDate: _parseTimestamp(map['startDate']),
      endDate: _parseTimestamp(map['endDate']),
      positionsAvailable: map['positionsAvailable'],
      requirements: _parseStringList(map['requirements']),
      benefits: _parseStringList(map['benefits']),
      skills: map['skills'],
      experience: map['experience'],
      education: map['education'],
      expectedSalary: map['expectedSalary'],
      availability: map['availability'],
      preferredLocation: map['preferredLocation'],
      // Contact Info
      contactEmail: map['contactEmail'],
      website: map['website'],
      facebookUrl: map['facebookUrl'],
      twitterUrl: map['twitterUrl'],
      linkedinUrl: map['linkedinUrl'],
      whatsappNumber: map['whatsappNumber'],
      // Documents
      resumeUrl: map['resumeUrl'],
      coverLetterUrl: map['coverLetterUrl'],
      documentUrls: _parseStringList(map['documentUrls']),
      createdAt: _parseTimestamp(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(map['updatedAt']),
      approvedAt: _parseTimestamp(map['approvedAt']),
      approvedBy: map['approvedBy'],
      expiresAt: _parseTimestamp(map['expiresAt']),
      viewCount: map['viewCount'] ?? 0,
      applicationCount: map['applicationCount'] ?? 0,
      appliedUserIds: _parseStringList(map['appliedUserIds']),
      isApiJob: map['isApiJob'] ?? false,
      apiSource: map['apiSource'],
      apiId: map['apiId'],
      apiUrl: map['apiUrl'],
      apiCachedAt: _parseTimestamp(map['apiCachedAt']),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfilePic': userProfilePic,
      'userPhone': userPhone,
      'postType': postType.name,
      'status': status.name,
      'category': category.name,
      'title': title,
      'description': description,
      'location': location,
      'locationState': locationState,
      'locationCountry': locationCountry,
      'latitude': latitude,
      'longitude': longitude,
      'farmName': farmName,
      'salary': salary,
      'salaryPeriod': salaryPeriod,
      'duration': duration,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'positionsAvailable': positionsAvailable,
      'requirements': requirements,
      'benefits': benefits,
      'skills': skills,
      'experience': experience,
      'education': education,
      'expectedSalary': expectedSalary,
      'availability': availability,
      'preferredLocation': preferredLocation,
      // Contact Info
      'contactEmail': contactEmail,
      'website': website,
      'facebookUrl': facebookUrl,
      'twitterUrl': twitterUrl,
      'linkedinUrl': linkedinUrl,
      'whatsappNumber': whatsappNumber,
      // Documents
      'resumeUrl': resumeUrl,
      'coverLetterUrl': coverLetterUrl,
      'documentUrls': documentUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'viewCount': viewCount,
      'applicationCount': applicationCount,
      'appliedUserIds': appliedUserIds,
      'isApiJob': isApiJob,
      'apiSource': apiSource,
      'apiId': apiId,
      'apiUrl': apiUrl,
      'apiCachedAt': apiCachedAt != null
          ? Timestamp.fromDate(apiCachedAt!)
          : null,
    };
  }

  /// Create a copy with updated fields
  JobPost copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfilePic,
    String? userPhone,
    JobPostType? postType,
    JobStatus? status,
    JobCategory? category,
    String? title,
    String? description,
    String? location,
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
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    String? approvedBy,
    DateTime? expiresAt,
    int? viewCount,
    int? applicationCount,
    List<String>? appliedUserIds,
    bool? isApiJob,
    String? apiSource,
    String? apiId,
    String? apiUrl,
    DateTime? apiCachedAt,
  }) {
    return JobPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePic: userProfilePic ?? this.userProfilePic,
      userPhone: userPhone ?? this.userPhone,
      postType: postType ?? this.postType,
      status: status ?? this.status,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      locationState: locationState ?? this.locationState,
      locationCountry: locationCountry ?? this.locationCountry,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      farmName: farmName ?? this.farmName,
      salary: salary ?? this.salary,
      salaryPeriod: salaryPeriod ?? this.salaryPeriod,
      duration: duration ?? this.duration,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      positionsAvailable: positionsAvailable ?? this.positionsAvailable,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      expectedSalary: expectedSalary ?? this.expectedSalary,
      availability: availability ?? this.availability,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      // Contact Info
      contactEmail: contactEmail ?? this.contactEmail,
      website: website ?? this.website,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      // Documents
      resumeUrl: resumeUrl ?? this.resumeUrl,
      coverLetterUrl: coverLetterUrl ?? this.coverLetterUrl,
      documentUrls: documentUrls ?? this.documentUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      expiresAt: expiresAt ?? this.expiresAt,
      viewCount: viewCount ?? this.viewCount,
      applicationCount: applicationCount ?? this.applicationCount,
      appliedUserIds: appliedUserIds ?? this.appliedUserIds,
      isApiJob: isApiJob ?? this.isApiJob,
      apiSource: apiSource ?? this.apiSource,
      apiId: apiId ?? this.apiId,
      apiUrl: apiUrl ?? this.apiUrl,
      apiCachedAt: apiCachedAt ?? this.apiCachedAt,
    );
  }

  // Helper methods
  static JobPostType _parsePostType(String? value) {
    if (value == null) return JobPostType.farmerJob;
    return JobPostType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => JobPostType.farmerJob,
    );
  }

  static JobStatus _parseStatus(String? value) {
    if (value == null) return JobStatus.pending;
    return JobStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => JobStatus.pending,
    );
  }

  static JobCategory _parseCategory(String? value) {
    if (value == null) return JobCategory.other;
    return JobCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => JobCategory.other,
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return null;
  }

  /// Get display name for post type
  String get postTypeDisplay {
    switch (postType) {
      case JobPostType.farmerJob:
        return 'Farm Job';
      case JobPostType.jobSeeker:
        return 'Seeking Work';
    }
  }

  /// Get display name for category
  String get categoryDisplay {
    switch (category) {
      case JobCategory.generalLabor:
        return 'General Labor';
      case JobCategory.harvesting:
        return 'Harvesting';
      case JobCategory.planting:
        return 'Planting';
      case JobCategory.irrigation:
        return 'Irrigation';
      case JobCategory.livestock:
        return 'Livestock';
      case JobCategory.machinery:
        return 'Machinery';
      case JobCategory.technical:
        return 'Technical';
      case JobCategory.management:
        return 'Management';
      case JobCategory.sales:
        return 'Sales';
      case JobCategory.other:
        return 'Other';
    }
  }

  /// Get color for status
  int get statusColor {
    switch (status) {
      case JobStatus.approved:
        return 0xFF4CAF50; // Green
      case JobStatus.pending:
        return 0xFFFF9800; // Orange
      case JobStatus.rejected:
        return 0xFFF44336; // Red
      case JobStatus.expired:
        return 0xFF9E9E9E; // Grey
      case JobStatus.filled:
        return 0xFF2196F3; // Blue
    }
  }

  /// Check if job is active and visible
  bool get isActive => status == JobStatus.approved && !isExpired;

  /// Check if job has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Get formatted salary display
  String? get salaryDisplay {
    if (salary == null) return null;
    final period = salaryPeriod ?? 'monthly';
    return '\$${salary!.toStringAsFixed(0)} / $period';
  }
}

/// Model for job applications
class JobApplication {
  final String id;
  final String jobId;
  final String jobTitle;
  final String applicantId;
  final String applicantName;
  final String? applicantPhone;
  final String? applicantEmail;
  final String? applicantProfilePic;
  final String? coverLetter;
  final String? resumeUrl;
  final DateTime appliedAt;
  final String status; // pending, viewed, accepted, rejected
  final String? employerResponse;
  final DateTime? respondedAt;
  final bool applicantSeen;

  const JobApplication({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.applicantId,
    required this.applicantName,
    this.applicantPhone,
    this.applicantEmail,
    this.applicantProfilePic,
    this.coverLetter,
    this.resumeUrl,
    required this.appliedAt,
    this.status = 'pending',
    this.employerResponse,
    this.respondedAt,
    this.applicantSeen = false,
  });

  factory JobApplication.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return JobApplication.fromMap(data, doc.id);
  }

  factory JobApplication.fromMap(Map<String, dynamic> map, String id) {
    return JobApplication(
      id: id,
      jobId: map['jobId'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      applicantId: map['applicantId'] ?? '',
      applicantName: map['applicantName'] ?? '',
      applicantPhone: map['applicantPhone'],
      applicantEmail: map['applicantEmail'],
      applicantProfilePic: map['applicantProfilePic'],
      coverLetter: map['coverLetter'],
      resumeUrl: map['resumeUrl'],
      appliedAt: JobPost._parseTimestamp(map['appliedAt']) ?? DateTime.now(),
      status: map['status'] ?? 'pending',
      employerResponse: map['employerResponse'],
      respondedAt: JobPost._parseTimestamp(map['respondedAt']),
      applicantSeen: map['applicantSeen'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'jobTitle': jobTitle,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'applicantPhone': applicantPhone,
      'applicantEmail': applicantEmail,
      'applicantProfilePic': applicantProfilePic,
      'coverLetter': coverLetter,
      'resumeUrl': resumeUrl,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'status': status,
      'employerResponse': employerResponse,
      'respondedAt': respondedAt != null
          ? Timestamp.fromDate(respondedAt!)
          : null,
      'applicantSeen': applicantSeen,
    };
  }
}
