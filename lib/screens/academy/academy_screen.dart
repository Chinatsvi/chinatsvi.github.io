import 'package:flutter/material.dart';
import '../../../models/academy/course_model.dart';
import '../../../models/academy/course_progress_model.dart';
import '../../../services/academy/academy_progress_service.dart';
import '../../../services/academy/academy_service.dart';
import '../../../widgets/ads/farm_banner_ad.dart';
import '../../../widgets/ads/farm_native_ad.dart';
import 'bookmarks_screen.dart';
import 'course_details_screen.dart';
import 'widgets/course_card.dart';
import 'widgets/data_saver_banner.dart';

class AcademyScreen extends StatefulWidget {
  const AcademyScreen({super.key});

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> {
  String _selectedCategory = 'all';
  String _selectedDifficulty = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _categories = const [
    {'id': 'all', 'label': '🌟 All Courses'},
    {'id': 'crop_production', 'label': '🌱 Crop Production'},
    {'id': 'poultry', 'label': '🐔 Poultry'},
    {'id': 'livestock', 'label': '🐄 Livestock'},
    {'id': 'irrigation', 'label': '💧 Irrigation'},
    {'id': 'aquaculture', 'label': '🐟 Aquaculture'},
    {'id': 'soil_fertility', 'label': '🌿 Soil & Fertility'},
    {'id': 'agribusiness', 'label': '💰 Agribusiness'},
    {'id': 'greenhouse', 'label': '🏡 Greenhouse'},
    {'id': 'farm_management', 'label': '📊 Farm Management'},
  ];

  final List<Map<String, String>> _difficulties = const [
    {'id': 'all', 'label': 'All Levels'},
    {'id': 'Beginner', 'label': 'Beginner'},
    {'id': 'Intermediate', 'label': 'Intermediate'},
    {'id': 'Advanced', 'label': 'Advanced'},
  ];

  @override
  void initState() {
    super.initState();
    // Seed starter courses if Firestore is clean/empty and sync real live learner counts
    AcademyService.instance.seedStarterCoursesIfEmpty();
    AcademyService.instance.syncRealLiveStatsForAllCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      bottomNavigationBar: const FarmBannerAd(),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'AgriBase Academy',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            tooltip: 'My Bookmarks',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AcademyBookmarksScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<CourseProgressModel>>(
        stream: AcademyProgressService.instance.streamUserProgressList(),
        builder: (context, progressSnap) {
          final userProgressList = progressSnap.data ?? [];
          final progressMap = {
            for (var p in userProgressList) p.courseId: p
          };

          return StreamBuilder<List<CourseModel>>(
            stream: AcademyService.instance.streamPublishedCourses(
              categoryId: _selectedCategory,
              difficulty: _selectedDifficulty,
              searchQuery: _searchQuery,
            ),
            builder: (context, courseSnap) {
              if (courseSnap.connectionState == ConnectionState.waiting &&
                  !courseSnap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                );
              }

              final courses = courseSnap.data ?? [];
              final featuredCourses =
                  courses.where((c) => c.isFeatured).toList();

              // Courses in progress
              final inProgressCourses = courses
                  .where((c) =>
                      progressMap.containsKey(c.id) &&
                      !progressMap[c.id]!.completed)
                  .toList();

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    _buildSearchBar(),

                    // Data Saver & Offline Banner
                    const DataSaverBanner(),

                    // Lesson of the Day
                    _buildLessonOfTheDay(courses),

                    // Continue Learning Section (if active)
                    if (inProgressCourses.isNotEmpty &&
                        _searchQuery.isEmpty) ...[
                      _buildContinueLearning(inProgressCourses, progressMap),
                      const SizedBox(height: 16),
                    ],

                    // Categories Filter Chips
                    _buildCategoryChips(),

                    // Difficulty Filter Chips
                    _buildDifficultyChips(),

                    const SizedBox(height: 14),

                    // Featured Courses Carousel
                    if (featuredCourses.isNotEmpty &&
                        _searchQuery.isEmpty &&
                        _selectedCategory == 'all') ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '🌟 Featured Masterclasses',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: featuredCourses.length,
                          itemBuilder: (context, index) {
                            final course = featuredCourses[index];
                            return CourseCard(
                              course: course,
                              progress: progressMap[course.id],
                              isHorizontal: true,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // All / Filtered Courses List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Search Results (${courses.length})'
                                : (_selectedCategory == 'all'
                                    ? '📚 All Courses (${courses.length})'
                                    : '${_getCategoryName(_selectedCategory)} (${courses.length})'),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (courses.isEmpty)
                      _buildEmptyState()
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: _buildCourseListWithAds(courses, progressMap),
                        ),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildCourseListWithAds(
    List<CourseModel> courses,
    Map<String, CourseProgressModel> progressMap,
  ) {
    final List<Widget> widgets = [];
    for (int i = 0; i < courses.length; i++) {
      widgets.add(
        CourseCard(
          course: courses[i],
          progress: progressMap[courses[i].id],
        ),
      );
      // Insert ad starting at index 1 and repeat every 4 cards
      if (i == 1 || (i > 1 && (i - 1) % 4 == 0)) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: FarmNativeAd(),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search courses, crops, livestock...',
          prefixIcon: const Icon(Icons.search, color: Colors.green),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade600, width: 1.5),
          ),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildLessonOfTheDay(List<CourseModel> courses) {
    if (courses.isEmpty) return const SizedBox.shrink();
    final sampleCourse = courses.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_stories, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📖 Farming Tip of the Day',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Why consistent soil moisture prevents Blossom End Rot in tomatoes.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseDetailsScreen(courseId: sampleCourse.id),
                ),
              );
            },
            child: const Text('Learn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueLearning(
    List<CourseModel> inProgress,
    Map<String, CourseProgressModel> progressMap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '▶️ Continue Learning',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: inProgress.length,
            itemBuilder: (context, index) {
              final course = inProgress[index];
              final progress = progressMap[course.id];
              final percent = progress?.progressPercent ?? 0.0;

              return Container(
                width: 260,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CourseDetailsScreen(courseId: course.id),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              course.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            '${percent.toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          backgroundColor: Colors.grey.shade200,
                          color: Colors.green.shade700,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Continue where you stopped →',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat['label']!),
              selected: isSelected,
              backgroundColor: Colors.white,
              selectedColor: Colors.green.shade100,
              checkmarkColor: Colors.green.shade800,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.green.shade900 : Colors.black87,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? Colors.green.shade600
                      : Colors.grey.shade300,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = cat['id']!;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDifficultyChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        height: 32,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _difficulties.length,
          itemBuilder: (context, index) {
            final diff = _difficulties[index];
            final isSelected = _selectedDifficulty == diff['id'];

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(diff['label']!),
                selected: isSelected,
                backgroundColor: Colors.grey.shade100,
                selectedColor: Colors.teal.shade100,
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.teal.shade900 : Colors.grey.shade800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? Colors.teal.shade600
                        : Colors.grey.shade300,
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedDifficulty = diff['id']!;
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No courses found',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing your search term or category filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(String id) {
    final match = _categories.where((c) => c['id'] == id).toList();
    return match.isNotEmpty ? match.first['label']! : 'Courses';
  }
}
