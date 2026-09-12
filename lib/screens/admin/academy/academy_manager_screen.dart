import 'package:flutter/material.dart';
import '../../../models/academy/course_model.dart';
import '../../../services/academy/academy_service.dart';
import '../../academy/course_details_screen.dart';
import 'course_builder_screen.dart';
import 'course_editor_screen.dart';

class AcademyManagerScreen extends StatefulWidget {
  const AcademyManagerScreen({super.key});

  @override
  State<AcademyManagerScreen> createState() => _AcademyManagerScreenState();
}

class _AcademyManagerScreenState extends State<AcademyManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['All', 'Published', 'Draft', 'Review', 'Archived'];

  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Automatically synchronize live learner & completion stats from real database records
    AcademyService.instance.syncRealLiveStatsForAllCourses();
  }

  Future<void> _syncLiveStats() async {
    setState(() => _isSyncing = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing live learner and completion data...'),
        duration: Duration(seconds: 1),
      ),
    );
    await AcademyService.instance.syncRealLiveStatsForAllCourses();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Real live stats updated successfully! ✅'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎓 Academy Manager'),
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Sync Real Live Learners & Completions',
            onPressed: _isSyncing ? null : _syncLiveStats,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amberAccent,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Course'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CourseEditorScreen(),
            ),
          );
        },
      ),
      body: StreamBuilder<List<CourseModel>>(
        stream: AcademyService.instance.streamAdminCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            );
          }

          final allCourses = snapshot.data ?? [];

          return Column(
            children: [
              // Analytics Overview Cards
              _buildAnalyticsCards(allCourses),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCourseList(allCourses),
                    _buildCourseList(allCourses
                        .where((c) => c.status == 'published')
                        .toList()),
                    _buildCourseList(allCourses
                        .where((c) => c.status == 'draft')
                        .toList()),
                    _buildCourseList(allCourses
                        .where((c) => c.status == 'review')
                        .toList()),
                    _buildCourseList(allCourses
                        .where((c) => c.status == 'archived')
                        .toList()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsCards(List<CourseModel> courses) {
    final totalPublished = courses.where((c) => c.status == 'published').length;
    final totalDrafts = courses.where((c) => c.status == 'draft').length;
    final totalEnrolled =
        courses.fold<int>(0, (sum, c) => sum + c.enrolledCount);
    final totalCompletions =
        courses.fold<int>(0, (sum, c) => sum + c.completionCount);

    return Container(
      padding: const EdgeInsets.all(14),
      color: Colors.purple.shade50,
      child: Row(
        children: [
          _statCard('Courses', '${courses.length}', Colors.purple),
          _statCard('Published', '$totalPublished', Colors.green),
          _statCard('Drafts', '$totalDrafts', Colors.orange),
          _statCard('Learners', '$totalEnrolled', Colors.blue),
          _statCard('Completed', '$totalCompletions', Colors.teal),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, MaterialColor color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.shade200),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color.shade800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList(List<CourseModel> courses) {
    if (courses.isEmpty) {
      return const Center(
        child: Text(
          'No courses in this category.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(course.status).withOpacity(0.2),
              child: Icon(
                Icons.school,
                color: _getStatusColor(course.status),
              ),
            ),
            title: Text(
              course.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(course.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    course.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(course.status),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${course.lessonCount} Lessons • ${course.enrolledCount} Learners',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    // Preview as farmer
                    OutlinedButton.icon(
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Preview'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CourseDetailsScreen(courseId: course.id),
                          ),
                        );
                      },
                    ),
                    // Course Builder (Lessons)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.list_alt, size: 16),
                      label: const Text('Builder & Lessons'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CourseBuilderScreen(course: course),
                          ),
                        );
                      },
                    ),
                    // Edit Metadata
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Edit Details',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CourseEditorScreen(course: course),
                          ),
                        );
                      },
                    ),
                    // Duplicate
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.teal),
                      tooltip: 'Duplicate Course',
                      onPressed: () => _duplicateCourse(course),
                    ),
                    // Publish/Unpublish toggle
                    PopupMenuButton<String>(
                      tooltip: 'Change Status',
                      icon: const Icon(Icons.more_vert),
                      onSelected: (status) async {
                        await AcademyService.instance
                            .setCourseStatus(course.id, status);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Status set to $status')),
                        );
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'published', child: Text('✅ Publish')),
                        const PopupMenuItem(
                            value: 'draft', child: Text('📝 Set as Draft')),
                        const PopupMenuItem(
                            value: 'review', child: Text('🔍 Needs Review')),
                        const PopupMenuItem(
                            value: 'archived', child: Text('📦 Archive')),
                      ],
                    ),
                    // Delete
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete Course',
                      onPressed: () => _confirmDeleteCourse(course),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return Colors.green;
      case 'review':
        return Colors.blue;
      case 'draft':
        return Colors.orange;
      case 'archived':
      default:
        return Colors.grey;
    }
  }

  Future<void> _duplicateCourse(CourseModel course) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duplicating course...')),
      );
      await AcademyService.instance.duplicateCourse(course.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course duplicated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error duplicating course: $e')),
      );
    }
  }

  Future<void> _confirmDeleteCourse(CourseModel course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course?'),
        content: Text(
          'Are you sure you want to delete "${course.title}" and all its lessons? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AcademyService.instance.deleteCourse(course.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course deleted.')),
        );
      }
    }
  }
}
