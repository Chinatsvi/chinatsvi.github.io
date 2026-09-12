import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../models/job_model.dart';

/// Service to fetch jobs from Jooble API with caching
class JoobleJobService {
  static const String _baseUrl = 'https://jooble.org/api/';
  static const String _apiKey = '460e99a9-7a43-4ec7-968f-b12aa313b5d9';

  // Cache duration - 6 hours
  static const Duration _cacheDuration = Duration(hours: 6);
  static const int _maxApiCallsPerDay = 500; // Jooble default limit

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final http.Client _httpClient = http.Client();

  /// Search keywords for agriculture jobs
  static const String _agricultureKeywords =
      'agriculture OR farming OR farm OR harvest OR livestock OR agronomist OR "farm worker" OR "agricultural worker" OR "farm manager" OR "dairy farmer" OR "crop production" OR "agricultural technician" OR horticulture OR "agricultural machinery" OR "tractor operator" OR "farm hand" OR "agricultural engineer" OR "soil scientist" OR "plant breeder" OR "agricultural consultant"';

  /// Get agriculture jobs from Jooble API
  Future<List<JobPost>> getAgricultureJobs({
    String location = '',
    int resultsPerPage = 50,
    JobCategory? category,
  }) async {
    try {
      // First check cache
      final cachedJobs = await _getCachedJobs(location);

      // Check if cache is fresh
      final cacheDoc = await _firestore
          .collection('job_api_cache')
          .doc('jooble_${location.isEmpty ? 'all' : location}')
          .get();

      if (cacheDoc.exists) {
        final cacheData = cacheDoc.data()!;
        final lastUpdated = (cacheData['lastUpdated'] as Timestamp?)?.toDate();

        if (lastUpdated != null &&
            DateTime.now().difference(lastUpdated) < _cacheDuration) {
          developer.log(
            '✅ Using cached Jooble agriculture jobs',
            name: 'JoobleJobService',
          );
          return _filterByCategory(cachedJobs, category);
        }
      }

      // Check daily API call limit
      final canCall = await _checkApiCallCount();
      if (!canCall) {
        developer.log(
          '⚠️ Daily API limit reached, using cached data',
          name: 'JoobleJobService',
        );
        return _filterByCategory(cachedJobs, category);
      }

      // Fetch from Jooble API
      final jobs = await _fetchFromJooble(
        keywords: _agricultureKeywords,
        location: location,
        resultsPerPage: resultsPerPage,
      );

      // Cache the jobs
      if (jobs.isNotEmpty) {
        await _cacheJobs(jobs, location);
      }

      developer.log(
        '✅ Fetched ${jobs.length} agriculture jobs from Jooble',
        name: 'JoobleJobService',
      );

      return _filterByCategory(jobs, category);
    } catch (e) {
      developer.log(
        '❌ Error fetching Jooble jobs: $e',
        name: 'JoobleJobService',
      );
      return _getCachedJobs(location);
    }
  }

  /// Search jobs with custom keywords
  Future<List<JobPost>> searchJobs({
    required String query,
    String location = '',
    int resultsPerPage = 20,
  }) async {
    try {
      // Check daily API call limit
      final canCall = await _checkApiCallCount();
      if (!canCall) {
        developer.log(
          '⚠️ Daily API limit reached for search',
          name: 'JoobleJobService',
        );
        return [];
      }

      final jobs = await _fetchFromJooble(
        keywords: query,
        location: location,
        resultsPerPage: resultsPerPage,
      );

      return jobs;
    } catch (e) {
      developer.log(
        '❌ Error searching Jooble jobs: $e',
        name: 'JoobleJobService',
      );
      return [];
    }
  }

  /// Fetch jobs from Jooble API
  Future<List<JobPost>> _fetchFromJooble({
    required String keywords,
    required String location,
    required int resultsPerPage,
  }) async {
    final url = Uri.parse('$_baseUrl$_apiKey');

    final requestBody = {
      'keywords': keywords,
      if (location.isNotEmpty) 'location': location,
      'page': 1,
      'resultOnPage': resultsPerPage,
    };

    developer.log(
      '🌐 Calling Jooble API: $url',
      name: 'JoobleJobService',
    );

    final response = await _httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      await _incrementApiCallCount();
      final data = json.decode(response.body);
      final jobs = data['jobs'] as List<dynamic>? ?? [];

      developer.log(
        '✅ Fetched ${jobs.length} jobs from Jooble',
        name: 'JoobleJobService',
      );

      return jobs.map((job) => _convertJoobleJob(job)).toList();
    } else {
      throw Exception(
        'Jooble API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Convert Jooble job format to JobPost model
  JobPost _convertJoobleJob(Map<String, dynamic> job) {
    final title = job['title'] ?? 'Untitled Job';
    final company = job['company'] ?? 'Unknown Company';
    final location = job['location'] ?? 'Unknown Location';
    final rawDescription = job['snippet'] ?? job['description'] ?? '';
    final description = _cleanDescription(rawDescription);
    
    // Debug: Log if HTML tags were found and cleaned
    if (rawDescription.contains('<') && rawDescription.contains('>')) {
      developer.log(
        '🧹 Cleaned HTML tags from description: "$rawDescription" -> "$description"',
        name: 'JoobleJobService',
      );
    }
    final salary = job['salary']?.toString();
    final createdAt = _parseJoobleDate(job['updated'] ?? job['date']);
    final redirectUrl = job['link'] ?? job['url'] ?? '';
    final jobId = job['id']?.toString() ?? '';

    // Parse salary if available
    double? salaryValue;
    if (salary != null && salary.isNotEmpty) {
      // Try to extract numeric value from salary string
      final numericMatch = RegExp(r'[\d,]+').firstMatch(salary);
      if (numericMatch != null) {
        final numericStr = numericMatch.group(0)?.replaceAll(',', '');
        salaryValue = double.tryParse(numericStr ?? '');
      }
    }

    return JobPost(
      id: 'jooble_$jobId',
      userId: 'jooble_system',
      userName: company,
      postType: JobPostType.farmerJob,
      status: JobStatus.approved,
      category: _categorizeJob(title, description),
      title: title,
      description: description,
      location: location,
      locationCountry: _extractCountry(location),
      salary: salaryValue,
      salaryPeriod: salaryValue != null ? 'monthly' : null,
      farmName: company,
      createdAt: createdAt ?? DateTime.now(),
      isApiJob: true,
      apiSource: 'jooble',
      apiId: jobId.toString(),
      apiUrl: redirectUrl,
      apiCachedAt: DateTime.now(),
    );
  }

  /// Clean up description by removing HTML tags and formatting
  String _cleanDescription(String raw) {
    if (raw.isEmpty) return '';

    var cleaned = raw;

    // Remove HTML tags - more comprehensive regex
    // This handles nested tags, self-closing tags, and malformed HTML
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false), ' ');
    
    // Handle specific problematic patterns that might remain
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*$', multiLine: true), ' '); // Incomplete tags at end
    cleaned = cleaned.replaceAll(RegExp(r'^[^<]*<', multiLine: true), ' '); // Incomplete tags at start

    // Decode common HTML entities
    final entities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
      '&apos;': "'",
      '&nbsp;': ' ',
      '&ndash;': '-',
      '&mdash;': '-',
      '&hellip;': '...',
      '&bull;': '•',
      '&copy;': '©',
      '&reg;': '®',
      '&trade;': '™',
      '&euro;': '€',
      '&pound;': '£',
      '&dollar;': '\$',
      '&cent;': '¢',
      '&yen;': '¥',
      '&sect;': '§',
      '&para;': '¶',
      '&deg;': '°',
      '&plusmn;': '±',
      '&sup2;': '²',
      '&sup3;': '³',
      '&frac14;': '¼',
      '&frac12;': '½',
      '&frac34;': '¾',
    };

    entities.forEach((entity, char) {
      cleaned = cleaned.replaceAll(entity, char);
    });

    // Handle numeric HTML entities (&#34; or &#x22;)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (match) => String.fromCharCode(int.parse(match.group(1)!)),
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (match) => String.fromCharCode(int.parse(match.group(1)!, radix: 16)),
    );

    // Normalize whitespace (remove multiple spaces, newlines, tabs)
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    // Trim and limit length
    cleaned = cleaned.trim();

    // Limit to reasonable length for preview
    if (cleaned.length > 500) {
      cleaned = '${cleaned.substring(0, 497)}...';
    }

    return cleaned;
  }

  /// Categorize job based on title and description
  JobCategory _categorizeJob(String title, String description) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';

    if (text.contains('harvest') ||
        text.contains('picking') ||
        text.contains('collection')) {
      return JobCategory.harvesting;
    }
    if (text.contains('plant') || text.contains('sow') || text.contains('seedling')) {
      return JobCategory.planting;
    }
    if (text.contains('irrigation') || text.contains('water')) {
      return JobCategory.irrigation;
    }
    if (text.contains('livestock') ||
        text.contains('animal') ||
        text.contains('cattle') ||
        text.contains('poultry') ||
        text.contains('dairy')) {
      return JobCategory.livestock;
    }
    if (text.contains('machinery') ||
        text.contains('tractor') ||
        text.contains('equipment') ||
        text.contains('operator')) {
      return JobCategory.machinery;
    }
    if (text.contains('manager') ||
        text.contains('supervisor') ||
        text.contains('foreman')) {
      return JobCategory.management;
    }
    if (text.contains('technician') ||
        text.contains('agronomist') ||
        text.contains('specialist')) {
      return JobCategory.technical;
    }
    if (text.contains('sales') || text.contains('marketing')) {
      return JobCategory.sales;
    }

    return JobCategory.generalLabor;
  }

  /// Extract country from location string
  String _extractCountry(String location) {
    final lowerLocation = location.toLowerCase();
    
    if (lowerLocation.contains('zimbabwe') || lowerLocation.contains('zw')) return 'Zimbabwe';
    if (lowerLocation.contains('south africa') || lowerLocation.contains('za')) return 'South Africa';
    if (lowerLocation.contains('united states') || lowerLocation.contains('usa') || lowerLocation.contains('us')) return 'United States';
    if (lowerLocation.contains('united kingdom') || lowerLocation.contains('uk') || lowerLocation.contains('gb')) return 'United Kingdom';
    if (lowerLocation.contains('australia') || lowerLocation.contains('au')) return 'Australia';
    if (lowerLocation.contains('canada') || lowerLocation.contains('ca')) return 'Canada';
    if (lowerLocation.contains('kenya') || lowerLocation.contains('ke')) return 'Kenya';
    if (lowerLocation.contains('nigeria') || lowerLocation.contains('ng')) return 'Nigeria';
    if (lowerLocation.contains('germany') || lowerLocation.contains('de')) return 'Germany';
    if (lowerLocation.contains('france') || lowerLocation.contains('fr')) return 'France';
    
    return '';
  }

  /// Parse Jooble date format
  DateTime? _parseJoobleDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      // Try ISO 8601 format first
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // Try common date formats
        final formats = [
          'yyyy-MM-dd',
          'dd/MM/yyyy',
          'MM/dd/yyyy',
          'dd-MM-yyyy',
        ];
        for (final format in formats) {
          try {
            return DateTime.parse(dateStr);
          } catch (_) {}
        }
      } catch (_) {}
      return null;
    }
  }

  /// Filter jobs by category
  List<JobPost> _filterByCategory(List<JobPost> jobs, JobCategory? category) {
    if (category == null) return jobs;
    return jobs.where((job) => job.category == category).toList();
  }

  /// Cache jobs in Firestore
  Future<void> _cacheJobs(List<JobPost> jobs, String location) async {
    try {
      final batch = _firestore.batch();
      final cacheRef = _firestore
          .collection('job_api_cache')
          .doc('jooble_${location.isEmpty ? 'all' : location}');

      // Store jobs in subcollection
      for (final job in jobs) {
        final jobRef = cacheRef.collection('jobs').doc(job.id);
        batch.set(jobRef, job.toMap());
      }

      // Update cache metadata
      batch.set(cacheRef, {
        'lastUpdated': FieldValue.serverTimestamp(),
        'location': location.isEmpty ? 'all' : location,
        'jobCount': jobs.length,
        'source': 'jooble',
      });

      await batch.commit();

      developer.log(
        '💾 Cached ${jobs.length} Jooble jobs',
        name: 'JoobleJobService',
      );
    } catch (e) {
      developer.log('❌ Error caching Jooble jobs: $e', name: 'JoobleJobService');
    }
  }

  /// Get cached jobs from Firestore
  Future<List<JobPost>> _getCachedJobs(String location) async {
    try {
      final snapshot = await _firestore
          .collection('job_api_cache')
          .doc('jooble_${location.isEmpty ? 'all' : location}')
          .collection('jobs')
          .get();

      return snapshot.docs.map((doc) => JobPost.fromDocument(doc)).toList();
    } catch (e) {
      developer.log(
        '❌ Error getting cached Jooble jobs: $e',
        name: 'JoobleJobService',
      );
      return [];
    }
  }

  /// Check if we can make more API calls today
  Future<bool> _checkApiCallCount() async {
    try {
      final doc = await _firestore.collection('api_usage').doc('jooble').get();

      if (!doc.exists) return true;

      final data = doc.data()!;
      final today = DateTime.now().toIso8601String().split('T')[0];
      final usageDate = data['date'] as String?;
      final callCount = data['callCount'] as int? ?? 0;

      // Reset if new day
      if (usageDate != today) return true;

      return callCount < _maxApiCallsPerDay;
    } catch (e) {
      return true; // Allow on error
    }
  }

  /// Increment API call count
  Future<void> _incrementApiCallCount() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final docRef = _firestore.collection('api_usage').doc('jooble');

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          transaction.set(docRef, {
            'date': today,
            'callCount': 1,
            'lastCall': FieldValue.serverTimestamp(),
          });
        } else {
          final data = doc.data()!;
          final usageDate = data['date'] as String?;

          if (usageDate != today) {
            // Reset for new day
            transaction.update(docRef, {
              'date': today,
              'callCount': 1,
              'lastCall': FieldValue.serverTimestamp(),
            });
          } else {
            transaction.update(docRef, {
              'callCount': FieldValue.increment(1),
              'lastCall': FieldValue.serverTimestamp(),
            });
          }
        }
      });
    } catch (e) {
      developer.log(
        '❌ Error incrementing Jooble API count: $e',
        name: 'JoobleJobService',
      );
    }
  }

  /// Get current API usage stats
  Future<Map<String, dynamic>> getApiUsageStats() async {
    try {
      final doc = await _firestore.collection('api_usage').doc('jooble').get();

      if (!doc.exists) {
        return {
          'date': DateTime.now().toIso8601String().split('T')[0],
          'callCount': 0,
          'limit': _maxApiCallsPerDay,
          'remaining': _maxApiCallsPerDay,
        };
      }

      final data = doc.data()!;
      final today = DateTime.now().toIso8601String().split('T')[0];
      final usageDate = data['date'] as String?;
      final callCount = data['callCount'] as int? ?? 0;

      // Reset if new day
      if (usageDate != today) {
        return {
          'date': today,
          'callCount': 0,
          'limit': _maxApiCallsPerDay,
          'remaining': _maxApiCallsPerDay,
        };
      }

      return {
        'date': usageDate,
        'callCount': callCount,
        'limit': _maxApiCallsPerDay,
        'remaining': _maxApiCallsPerDay - callCount,
        'lastCall': data['lastCall'],
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Clear cached jobs to force refresh with cleaned descriptions
  Future<void> clearCache({String location = ''}) async {
    try {
      final cacheRef = _firestore
          .collection('job_api_cache')
          .doc('jooble_${location.isEmpty ? 'all' : location}');
      
      // Delete the entire cache document
      await cacheRef.delete();
      
      developer.log(
        '🗑️ Cleared Jooble cache for location: ${location.isEmpty ? 'all' : location}',
        name: 'JoobleJobService',
      );
    } catch (e) {
      developer.log(
        '❌ Error clearing Jooble cache: $e',
        name: 'JoobleJobService',
      );
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
