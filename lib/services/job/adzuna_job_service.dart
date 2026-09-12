import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../models/job_model.dart';

/// Service to fetch jobs from Adzuna API with caching and rate limiting
class AdzunaJobService {
  static const String _baseUrl = 'https://api.adzuna.com/v1/api/jobs';
  static const String _appId = 'cad36dac';
  static const String _appKey = '38fba46f48dde42d574369b3f258ee7b';

  // Rate limiting: Max 1000 calls per day = ~41 calls per hour = ~1 call per 1.5 minutes
  // We'll cache jobs and refresh every 6 hours to be safe
  static const Duration _cacheDuration = Duration(hours: 6);
  static const int _maxApiCallsPerDay = 1000;

  // Supported countries for agriculture jobs
  static const Map<String, String> _supportedCountries = {
    'za': 'South Africa',
    'us': 'United States',
    'gb': 'United Kingdom',
    'au': 'Australia',
    'ca': 'Canada',
    'nz': 'New Zealand',
    'in': 'India',
    'de': 'Germany',
    'fr': 'France',
    'ke': 'Kenya',
    'ng': 'Nigeria',
    'zw': 'Zimbabwe',
  };

  // Agriculture search terms
  static const String _agricultureSearchTerms =
      'agriculture OR farming OR farm OR harvest OR livestock OR agronomist OR "farm worker" OR "agricultural worker" OR "farm manager" OR "dairy farmer" OR "crop production" OR "agricultural technician" OR horticulture OR "agricultural machinery" OR "tractor operator" OR "farm hand" OR "agricultural engineer" OR "soil scientist" OR "plant breeder" OR "agricultural consultant"';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final http.Client _httpClient = http.Client();

  /// Get agriculture jobs from all supported countries
  Future<List<JobPost>> getUniversalAgricultureJobs({
    int resultsPerPage = 50,
    JobCategory? category,
  }) async {
    try {
      // First check universal cache
      final cachedJobs = await _getCachedJobs('universal', 'all');

      // Check if cache is fresh
      final cacheDoc = await _firestore
          .collection('job_api_cache')
          .doc('universal_all')
          .get();

      if (cacheDoc.exists) {
        final cacheData = cacheDoc.data()!;
        final lastUpdated = (cacheData['lastUpdated'] as Timestamp?)?.toDate();

        if (lastUpdated != null &&
            DateTime.now().difference(lastUpdated) < _cacheDuration) {
          developer.log(
            '✅ Using cached universal agriculture jobs',
            name: 'AdzunaJobService',
          );
          return _filterByCategory(cachedJobs, category);
        }
      }

      // Check daily API call limit
      final canCall = await _checkApiCallCount();
      if (!canCall) {
        developer.log(
          '⚠️ Daily API limit reached, using cached data',
          name: 'AdzunaJobService',
        );
        return _filterByCategory(cachedJobs, category);
      }

      // Fetch from multiple countries (limit to 4 to save API calls)
      final countriesToFetch = ['za', 'us', 'gb', 'au', 'ca'];
      final List<JobPost> allJobs = [];
      int apiCalls = 0;

      for (final country in countriesToFetch) {
        if (apiCalls >= 5) break; // Limit API calls

        try {
          final jobs = await _fetchFromAdzuna(
            country: country,
            location: '',
            page: 1,
            resultsPerPage: (resultsPerPage / countriesToFetch.length).ceil(),
          );
          allJobs.addAll(jobs);
          apiCalls++;
          await _incrementApiCallCount();
        } catch (e) {
          developer.log(
            '❌ Error fetching from $country: $e',
            name: 'AdzunaJobService',
          );
          // Continue with other countries
        }
      }

      // Cache all jobs together
      if (allJobs.isNotEmpty) {
        await _cacheJobs(allJobs, 'universal', 'all');
      }

      developer.log(
        '✅ Fetched ${allJobs.length} agriculture jobs from $apiCalls countries',
        name: 'AdzunaJobService',
      );

      return _filterByCategory(allJobs, category);
    } catch (e) {
      developer.log(
        '❌ Error fetching universal jobs: $e',
        name: 'AdzunaJobService',
      );
      return _getCachedJobs('universal', 'all');
    }
  }

  /// Filter jobs by category
  List<JobPost> _filterByCategory(List<JobPost> jobs, JobCategory? category) {
    if (category == null) return jobs;
    return jobs.where((job) => job.category == category).toList();
  }

  /// Get cached API jobs or fetch new ones if cache is stale (legacy single country)
  Future<List<JobPost>> getJobs({
    String country = 'za',
    String location = '',
    int page = 1,
    int resultsPerPage = 20,
    String? category,
  }) async {
    // Use universal method for better results
    return getUniversalAgricultureJobs(resultsPerPage: resultsPerPage * 3);
  }

  /// Search jobs with keywords
  Future<List<JobPost>> searchJobs({
    required String query,
    String country = 'za',
    String location = '',
    int page = 1,
    int resultsPerPage = 20,
  }) async {
    try {
      // Check daily API call limit
      final canCall = await _checkApiCallCount();
      if (!canCall) {
        developer.log(
          '⚠️ Daily API limit reached for search',
          name: 'AdzunaJobService',
        );
        return [];
      }

      final url = Uri.parse(
        '$_baseUrl/$country/search/$page?app_id=$_appId&app_key=$_appKey&results_per_page=$resultsPerPage&what=${Uri.encodeComponent(query)}${location.isNotEmpty ? '&where=${Uri.encodeComponent(location)}' : ''}&content-type=application/json',
      );

      developer.log('🔍 Searching Adzuna: $url', name: 'AdzunaJobService');

      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        await _incrementApiCallCount();
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];

        return results.map((job) => _convertAdzunaJob(job, country)).toList();
      } else {
        developer.log(
          '❌ Adzuna API error: ${response.statusCode}',
          name: 'AdzunaJobService',
        );
        return [];
      }
    } catch (e) {
      developer.log(
        '❌ Error searching Adzuna jobs: $e',
        name: 'AdzunaJobService',
      );
      return [];
    }
  }

  /// Fetch jobs from Adzuna API
  Future<List<JobPost>> _fetchFromAdzuna({
    required String country,
    required String location,
    required int page,
    required int resultsPerPage,
    String? category,
  }) async {
    // Build query params for agriculture-related jobs
    final what = _agricultureSearchTerms;

    final url = Uri.parse(
      '$_baseUrl/$country/search/$page?app_id=$_appId&app_key=$_appKey&results_per_page=$resultsPerPage&what=${Uri.encodeComponent(what)}${location.isNotEmpty ? '&where=${Uri.encodeComponent(location)}' : ''}${category != null ? '&category=$category' : ''}&content-type=application/json',
    );

    developer.log('🌐 Calling Adzuna API: $url', name: 'AdzunaJobService');

    final response = await _httpClient.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List<dynamic>? ?? [];

      developer.log(
        '✅ Fetched ${results.length} jobs from Adzuna ($country)',
        name: 'AdzunaJobService',
      );

      return results.map((job) => _convertAdzunaJob(job, country)).toList();
    } else {
      throw Exception(
        'Adzuna API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Convert Adzuna job format to JobPost model
  JobPost _convertAdzunaJob(Map<String, dynamic> job, String country) {
    final title = job['title'] ?? 'Untitled Job';
    final company = job['company']?['display_name'] ?? 'Unknown Company';
    final location = job['location']?['display_name'] ?? 'Unknown Location';
    final rawDescription = job['description'] ?? '';
    final description = _cleanDescription(rawDescription);
    
    // Debug: Log if HTML tags were found and cleaned
    if (rawDescription.contains('<') && rawDescription.contains('>')) {
      developer.log(
        '🧹 Cleaned HTML tags from Adzuna description: "$rawDescription" -> "$description"',
        name: 'AdzunaJobService',
      );
    }
    final salaryMin = job['salary_min']?.toDouble();
    final salaryMax = job['salary_max']?.toDouble();
    final createdAt = _parseAdzunaDate(job['created_at']);
    final redirectUrl = job['redirect_url'] ?? '';
    final jobId = job['id'] ?? '';

    // Calculate average salary if both min and max available
    final salary = (salaryMin != null && salaryMax != null)
        ? (salaryMin + salaryMax) / 2
        : salaryMin ?? salaryMax;

    return JobPost(
      id: 'adzuna_$jobId',
      userId: 'adzuna_system',
      userName: company,
      postType: JobPostType.farmerJob,
      status: JobStatus.approved,
      category: _categorizeJob(title, description),
      title: title,
      description: description,
      location: location,
      locationCountry: _supportedCountries[country] ?? country.toUpperCase(),
      salary: salary,
      salaryPeriod: salary != null ? 'monthly' : null,
      farmName: company,
      createdAt: createdAt ?? DateTime.now(),
      isApiJob: true,
      apiSource: 'adzuna',
      apiId: jobId.toString(),
      apiUrl: redirectUrl,
      apiCachedAt: DateTime.now(),
    );
  }

  /// Categorize job based on title and description
  JobCategory _categorizeJob(String title, String description) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';

    if (text.contains('harvest') ||
        text.contains('picking') ||
        text.contains('collection')) {
      return JobCategory.harvesting;
    }
    if (text.contains('plant') ||
        text.contains('sow') ||
        text.contains('seedling')) {
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

  /// Parse Adzuna date format
  DateTime? _parseAdzunaDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Cache jobs in Firestore
  Future<void> _cacheJobs(
    List<JobPost> jobs,
    String country,
    String location,
  ) async {
    try {
      final batch = _firestore.batch();
      final cacheRef = _firestore
          .collection('job_api_cache')
          .doc('${country}_$location');

      // Store jobs in subcollection
      for (final job in jobs) {
        final jobRef = cacheRef.collection('jobs').doc(job.id);
        batch.set(jobRef, job.toMap());
      }

      // Update cache metadata
      batch.set(cacheRef, {
        'lastUpdated': FieldValue.serverTimestamp(),
        'country': country,
        'location': location,
        'jobCount': jobs.length,
      });

      await batch.commit();

      developer.log(
        '💾 Cached ${jobs.length} jobs for $country/$location',
        name: 'AdzunaJobService',
      );
    } catch (e) {
      developer.log('❌ Error caching jobs: $e', name: 'AdzunaJobService');
    }
  }

  /// Get cached jobs from Firestore
  Future<List<JobPost>> _getCachedJobs(String country, String location) async {
    try {
      final snapshot = await _firestore
          .collection('job_api_cache')
          .doc('${country}_$location')
          .collection('jobs')
          .get();

      return snapshot.docs.map((doc) => JobPost.fromDocument(doc)).toList();
    } catch (e) {
      developer.log(
        '❌ Error getting cached jobs: $e',
        name: 'AdzunaJobService',
      );
      return [];
    }
  }

  /// Check if we can make more API calls today
  Future<bool> _checkApiCallCount() async {
    try {
      final doc = await _firestore.collection('api_usage').doc('adzuna').get();

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
      final docRef = _firestore.collection('api_usage').doc('adzuna');

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
        '❌ Error incrementing API count: $e',
        name: 'AdzunaJobService',
      );
    }
  }

  /// Get current API usage stats
  Future<Map<String, dynamic>> getApiUsageStats() async {
    try {
      final doc = await _firestore.collection('api_usage').doc('adzuna').get();

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

  void dispose() {
    _httpClient.close();
  }
}
