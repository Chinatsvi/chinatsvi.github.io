import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:agribased/models/job_model.dart';
import 'package:agribased/services/job/job_service.dart';
import 'package:agribased/services/job/adzuna_job_service.dart';
import 'package:agribased/services/job/jooble_job_service.dart';
import 'package:agribased/services/ad_manager.dart';
import 'package:agribased/widgets/ad_banner_widget.dart';
import 'job_post_screen.dart';
import 'job_detail_screen.dart';
import 'job_applications_screen.dart';
import 'widgets/job_card.dart';
import 'widgets/api_job_card.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final JobService _jobService = JobService();
  final AdzunaJobService _adzunaService = AdzunaJobService();
  final JoobleJobService _joobleService = JoobleJobService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  JobCategory? _selectedCategory;
  JobPostType? _selectedJobType;

  // AdMob integration
  final Map<int, BannerAd> _loadedAds = {};
  final Set<int> _loadingAdSlots = {};
  static const _maxConcurrentAdLoads = 3;
  static String get _adUnitId => AdManager.bannerAdUnitId;
  // First ad after first job card (index 1), then space 6-8 job cards
  static const _adIntervals = [1, 6, 7, 8];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    for (final ad in _loadedAds.values) {
      ad.dispose();
    }
    _loadedAds.clear();
    _tabController.dispose();
    _searchController.dispose();
    _adzunaService.dispose();
    _joobleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Farm Jobs', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.work), text: 'Local Jobs'),
            Tab(icon: Icon(Icons.public), text: 'More Jobs'),
            Tab(icon: Icon(Icons.folder_shared), text: 'My Listings'),
          ],
        ),
        actions: [
          // My Visitors button with new-response indicator
          Builder(builder: (ctx) {
            if (user == null) {
              return IconButton(
                icon: const Icon(Icons.assignment, color: Colors.white),
                tooltip: 'My Visitors',
                onPressed: () {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (context) => const JobApplicationsScreen(),
                    ),
                  );
                },
              );
            }

            return StreamBuilder<List<JobApplication>>(
              stream: _jobService.getUserApplications(user.uid),
              builder: (context, snap) {
                final hasResponses = snap.hasData &&
                  snap.data!.any((a) => a.status != 'pending' && !a.applicantSeen);

                return IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.assignment, color: Colors.white),
                      if (hasResponses)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.lightBlueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  tooltip: 'My Visitors',
                  onPressed: () {
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (context) => const JobApplicationsScreen(),
                      ),
                    );
                  },
                );
              },
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search jobs, skills, location, recruiters...',
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green.shade700),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildCategoryChip(null, 'All'),
                ...JobCategory.values.map(
                  (cat) => _buildCategoryChip(cat, cat.name),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Job type filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildJobTypeChip(null, 'All Types'),
                _buildJobTypeChip(JobPostType.farmerJob, 'Farmers Hiring'),
                _buildJobTypeChip(JobPostType.jobSeeker, 'Job Seekers'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Local Jobs Tab
                _buildLocalJobsTab(user?.uid),
                // API Jobs Tab
                _buildApiJobsTab(),
                // My Listings Tab
                _buildMyListingsTab(user?.uid),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPostOptions(context),
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add),
        label: const Text('Post'),
      ),
    );
  }

  Widget _buildCategoryChip(JobCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(_formatCategoryLabel(label)),
        selected: isSelected,
        selectedColor: Colors.green.shade100,
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
      ),
    );
  }

  Widget _buildJobTypeChip(JobPostType? type, String label) {
    final isSelected = _selectedJobType == type;
    final Color chipColor = type == JobPostType.farmerJob
        ? Colors.green
        : type == JobPostType.jobSeeker
        ? Colors.blue
        : Colors.grey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: chipColor.withValues(alpha: 0.1),
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected ? chipColor : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          setState(() {
            _selectedJobType = selected ? type : null;
          });
        },
      ),
    );
  }

  String _formatCategoryLabel(String label) {
    if (label == 'All') return 'All';
    // Convert camelCase to Title Case with spaces
    return label
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
        .trim()
        .replaceFirst(label[0], label[0].toUpperCase());
  }

  // AdMob positioning logic
  int _adPositionForSlot(int slot) {
    var jobPosition = 0;
    for (var currentSlot = 0; currentSlot <= slot; currentSlot++) {
      jobPosition += _adIntervals[currentSlot % _adIntervals.length];
    }
    return jobPosition;
  }

  int _adCountForJobCount(int jobCount) {
    var count = 0;
    while (_adPositionForSlot(count) <= jobCount) {
      count++;
    }
    return count;
  }

  int _adCountThroughJobIndex(int jobIndex) {
    var count = 0;
    while (_adPositionForSlot(count) <= jobIndex) {
      count++;
    }
    return count;
  }

  int? _adSlotForListIndex(int listIndex, int jobCount) {
    final adSlotCount = _adCountForJobCount(jobCount);
    for (var slot = 0; slot < adSlotCount; slot++) {
      final adListIndex = _adPositionForSlot(slot) + slot;
      if (adListIndex == listIndex) return slot;
      if (adListIndex > listIndex) break;
    }
    return null;
  }

  int _adCountBeforeListIndex(int listIndex, int jobCount) {
    final adSlotCount = _adCountForJobCount(jobCount);
    var count = 0;
    for (var slot = 0; slot < adSlotCount; slot++) {
      if (_adPositionForSlot(slot) + slot < listIndex) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  void _scheduleAdPreload(int jobIndex, int jobCount) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _preloadAdsForJobIndex(jobIndex, jobCount);
      }
    });
  }

  void _preloadAdsForJobIndex(int jobIndex, int jobCount) {
    if (!AdManager.instance.adsEnabled || jobCount < _adIntervals.first) {
      return;
    }

    final adSlotCount = _adCountForJobCount(jobCount);
    final firstSlot = _adCountThroughJobIndex(jobIndex);
    final slotsToKeep = <int>{};

    for (
      var slot = firstSlot;
      slot < adSlotCount && slotsToKeep.length < 3;
      slot++
    ) {
      slotsToKeep.add(slot);
      _preloadAdForIndex(slot);
    }

    for (final slot in _loadedAds.keys.toList()) {
      if (!slotsToKeep.contains(slot) && (slot - firstSlot).abs() > 3) {
        _loadedAds.remove(slot)?.dispose();
      }
    }
  }

  Future<void> _preloadAdForIndex(int index) async {
    if (_loadedAds.containsKey(index) ||
        _loadingAdSlots.contains(index) ||
        _loadingAdSlots.length >= _maxConcurrentAdLoads) {
      return;
    }

    _loadingAdSlots.add(index);
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
          Orientation.portrait,
          width,
        );

    if (size == null || !mounted) {
      _loadingAdSlots.remove(index);
      return;
    }

    final ad = BannerAd(
      adUnitId: _adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ [AdMob Jobs] Banner Ad loaded successfully for slot $index (Ad Unit: ${ad.adUnitId})');
          _loadingAdSlots.remove(index);
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _loadedAds[index] = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('⚠️ [AdMob Jobs] Banner Ad failed to load for slot $index: Code ${error.code} - ${error.message}');
          debugPrint('📱 [AdMob Jobs] Domain: ${error.domain} | ResponseInfo: ${error.responseInfo}');
          _loadingAdSlots.remove(index);
          ad.dispose();
        },
        onAdOpened: (ad) => debugPrint('📱 [AdMob Jobs] Banner Ad opened for slot $index'),
        onAdClosed: (ad) => debugPrint('📱 [AdMob Jobs] Banner Ad closed for slot $index'),
        onAdImpression: (ad) => debugPrint('📱 [AdMob Jobs] Banner Ad impression for slot $index'),
      ),
    );
    debugPrint('📱 [AdMob Jobs] Requesting banner ad for slot $index with adUnitId: $_adUnitId');
    ad.load();
  }

  Widget _buildLocalJobsTab(String? userId) {
    return StreamBuilder<List<JobPost>>(
      stream: _jobService.getApprovedJobs(
        type: _selectedJobType,
        category: _selectedCategory,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading jobs',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        var jobs = snapshot.data ?? [];

        // Apply comprehensive search filter
        if (_searchQuery.isNotEmpty) {
          jobs = jobs.where((job) {
            final query = _searchQuery;
            final searchFields = [
              job.title.toLowerCase(),
              job.description.toLowerCase(),
              job.location.toLowerCase(),
              job.locationState?.toLowerCase() ?? '',
              job.locationCountry?.toLowerCase() ?? '',
              job.farmName?.toLowerCase() ?? '',
              job.userName.toLowerCase(),
              job.skills?.toLowerCase() ?? '',
              job.experience?.toLowerCase() ?? '',
              job.education?.toLowerCase() ?? '',
              job.category.name.toLowerCase(),
              job.availability?.toLowerCase() ?? '',
              ...?job.requirements?.map((r) => r.toLowerCase()),
              ...?job.benefits?.map((b) => b.toLowerCase()),
            ];
            return searchFields.any((field) => field.contains(query));
          }).toList();
        }

        // Show Zimbabwe jobs first
        jobs.sort((a, b) {
          final aInZim =
              a.locationCountry?.toLowerCase().contains('zimbabwe') ?? false;
          final bInZim =
              b.locationCountry?.toLowerCase().contains('zimbabwe') ?? false;
          if (aInZim && !bInZim) return -1;
          if (!aInZim && bInZim) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });

        if (jobs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.work_outline,
            title: 'No Jobs Available',
            subtitle: 'Be the first to post a job listing',
          );
        }

        // Schedule ad preloading
        _scheduleAdPreload(0, jobs.length);

        final totalItemCount = jobs.length + _adCountForJobCount(jobs.length);

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: totalItemCount,
          itemBuilder: (context, index) {
            // Check if this index should show an ad
            final adSlot = _adSlotForListIndex(index, jobs.length);
            if (adSlot != null) {
              return AdBannerWidget(ad: _loadedAds[adSlot]);
            }

            // Calculate the actual job index
            final adCount = _adCountBeforeListIndex(index, jobs.length);
            final jobIndex = index - adCount;

            if (jobIndex >= jobs.length) {
              return const SizedBox.shrink();
            }

            final job = jobs[jobIndex];
            return JobCard(job: job, onTap: () => _navigateToJobDetail(job));
          },
        );
      },
    );
  }

  Widget _buildApiJobsTab() {
    return FutureBuilder<List<JobPost>>(
      future: _fetchAllApiJobs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 48, color: Colors.orange.shade300),
                const SizedBox(height: 16),
                Text(
                  'External jobs temporarily unavailable',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your internet connection or try again later',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        var jobs = snapshot.data ?? [];

        // Apply category filter
        if (_selectedCategory != null) {
          jobs = jobs
              .where((job) => job.category == _selectedCategory)
              .toList();
        }

        // Apply comprehensive search filter
        if (_searchQuery.isNotEmpty) {
          jobs = jobs.where((job) {
            final query = _searchQuery;
            final searchFields = [
              job.title.toLowerCase(),
              job.description.toLowerCase(),
              job.location.toLowerCase(),
              job.skills?.toLowerCase() ?? '',
              job.experience?.toLowerCase() ?? '',
              job.category.name.toLowerCase(),
              ...?job.requirements?.map((r) => r.toLowerCase()),
            ];
            return searchFields.any((field) => field.contains(query));
          }).toList();
        }

        if (jobs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.public_off,
            title: 'No External Jobs Available',
            subtitle:
                'Try adjusting your search or filters, or check back later',
          );
        }

        // Schedule ad preloading
        _scheduleAdPreload(0, jobs.length);

        final totalItemCount = jobs.length + _adCountForJobCount(jobs.length);

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: totalItemCount,
          itemBuilder: (context, index) {
            // Check if this index should show an ad
            final adSlot = _adSlotForListIndex(index, jobs.length);
            if (adSlot != null) {
              return AdBannerWidget(ad: _loadedAds[adSlot]);
            }

            // Calculate the actual job index
            final adCount = _adCountBeforeListIndex(index, jobs.length);
            final jobIndex = index - adCount;

            if (jobIndex >= jobs.length) {
              return const SizedBox.shrink();
            }

            final job = jobs[jobIndex];
            return ApiJobCard(job: job, onTap: () => _navigateToJobDetail(job));
          },
        );
      },
    );
  }

  /// Fetch jobs from both Adzuna and Jooble APIs
  Future<List<JobPost>> _fetchAllApiJobs() async {
    try {
      // Fetch from both APIs in parallel
      final results = await Future.wait([
        _adzunaService.getJobs(
          country: 'za',
          location: '',
          resultsPerPage: 30,
        ).catchError((e) {
          developer.log('Adzuna error: $e', name: 'JobsScreen');
          return <JobPost>[];
        }),
        _joobleService.getAgricultureJobs(
          location: '',
          resultsPerPage: 30,
        ).catchError((e) {
          developer.log('Jooble error: $e', name: 'JobsScreen');
          return <JobPost>[];
        }),
      ]);

      // Combine results and remove duplicates (by title + company)
      final allJobs = <JobPost>[];
      final seenJobs = <String>{};

      for (final jobList in results) {
        for (final job in jobList) {
          final key = '${job.title.toLowerCase()}_${job.userName.toLowerCase()}';
          if (!seenJobs.contains(key)) {
            seenJobs.add(key);
            allJobs.add(job);
          }
        }
      }

      // Sort by date (newest first)
      allJobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      developer.log(
        '✅ Total API jobs: ${allJobs.length} (Adzuna: ${results[0].length}, Jooble: ${results[1].length})',
        name: 'JobsScreen',
      );

      return allJobs;
    } catch (e) {
      developer.log('❌ Error fetching API jobs: $e', name: 'JobsScreen');
      return [];
    }
  }

  Widget _buildMyListingsTab(String? userId) {
    if (userId == null) {
      return _buildEmptyState(
        icon: Icons.lock_outline,
        title: 'Please Sign In',
        subtitle: 'You need to be logged in to view your listings',
      );
    }

    return StreamBuilder<List<JobPost>>(
      stream: _jobService.getUserJobs(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final jobs = snapshot.data ?? [];

        // Apply comprehensive search filter
        var filteredJobs = jobs;
        if (_searchQuery.isNotEmpty) {
          filteredJobs = jobs.where((job) {
            final query = _searchQuery;
            final searchFields = [
              job.title.toLowerCase(),
              job.description.toLowerCase(),
              job.location.toLowerCase(),
              job.farmName?.toLowerCase() ?? '',
              job.userName.toLowerCase(),
              job.skills?.toLowerCase() ?? '',
              job.experience?.toLowerCase() ?? '',
              job.category.name.toLowerCase(),
              job.status.name.toLowerCase(),
              ...?job.requirements?.map((r) => r.toLowerCase()),
            ];
            return searchFields.any((field) => field.contains(query));
          }).toList();
        }

        // Apply job type filter for My Listings
        if (_selectedJobType != null) {
          filteredJobs = filteredJobs
              .where((job) => job.postType == _selectedJobType)
              .toList();
        }

        if (filteredJobs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.folder_open,
            title: 'No Listings Yet',
            subtitle: 'Post a job or create a job seeker profile',
          );
        }

        // Schedule ad preloading
        _scheduleAdPreload(0, filteredJobs.length);

        final totalItemCount = filteredJobs.length + _adCountForJobCount(filteredJobs.length);

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: totalItemCount,
          itemBuilder: (context, index) {
            // Check if this index should show an ad
            final adSlot = _adSlotForListIndex(index, filteredJobs.length);
            if (adSlot != null) {
              return AdBannerWidget(ad: _loadedAds[adSlot]);
            }

            // Calculate the actual job index
            final adCount = _adCountBeforeListIndex(index, filteredJobs.length);
            final jobIndex = index - adCount;

            if (jobIndex >= filteredJobs.length) {
              return const SizedBox.shrink();
            }

            final job = filteredJobs[jobIndex];
            return JobCard(
              job: job,
              onTap: () => _navigateToJobDetail(job),
              showStatus: true,
              onDelete: () => _confirmDeleteJob(job),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'What would you like to post?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildPostOption(
                  icon: Icons.work,
                  title: 'Post a Job',
                  subtitle: 'I need to hire farm workers',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToPostJob(JobPostType.farmerJob);
                  },
                ),
                const SizedBox(height: 12),
                _buildPostOption(
                  icon: Icons.person_search,
                  title: 'Looking for Work',
                  subtitle: 'I want to find a farm job',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToPostJob(JobPostType.jobSeeker);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      onTap: onTap,
    );
  }

  void _navigateToPostJob(JobPostType type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobPostScreen(postType: type)),
    );
  }

  void _navigateToJobDetail(JobPost job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobDetailScreen(job: job)),
    );
  }

  Future<void> _confirmDeleteJob(JobPost job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Job?'),
          content: Text('Are you sure you want to delete "${job.title}"?'),
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
        await _jobService.deleteJob(job.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job deleted successfully')),
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
  }
}
