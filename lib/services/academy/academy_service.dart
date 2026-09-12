import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/academy/course_model.dart';
import '../../models/academy/lesson_model.dart';
import '../../models/academy/lesson_block_model.dart';
import '../../models/academy/quiz_model.dart';

class AcademyService {
  static final AcademyService instance = AcademyService._internal();
  AcademyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _coursesRef =>
      _firestore.collection('academy_courses');

  // ----------------------------------------------------
  // FARMER QUERIES
  // ----------------------------------------------------

  /// Stream of all published courses for farmers
  Stream<List<CourseModel>> streamPublishedCourses({
    String? categoryId,
    String? difficulty,
    String? searchQuery,
    bool? isFreeOnly,
  }) {
    Query<Map<String, dynamic>> query = _coursesRef
        .where('status', isEqualTo: 'published');

    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    if (difficulty != null && difficulty.isNotEmpty && difficulty != 'all') {
      query = query.where('difficulty', isEqualTo: difficulty);
    }
    if (isFreeOnly == true) {
      query = query.where('isFree', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      var list = snapshot.docs
          .map((doc) => CourseModel.fromFirestore(doc))
          .toList();

      // Client-side search filtering for flexible keyword matching
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        list = list.where((c) {
          final titleMatch = c.title.toLowerCase().contains(q);
          final descMatch = c.shortDescription.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q);
          final catMatch = c.categoryName.toLowerCase().contains(q);
          final cropMatch = (c.cropOrLivestock ?? '').toLowerCase().contains(q);
          return titleMatch || descMatch || catMatch || cropMatch;
        }).toList();
      }

      // Sort featured first, then by publishedAt desc
      list.sort((a, b) {
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;
        final aDate = a.publishedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.publishedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return list;
    });
  }

  /// Get featured courses
  Stream<List<CourseModel>> streamFeaturedCourses() {
    return _coursesRef
        .where('status', isEqualTo: 'published')
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList());
  }

  /// Get single course by ID
  Future<CourseModel?> getCourse(String courseId) async {
    try {
      final doc = await _coursesRef.doc(courseId).get();
      if (doc.exists) {
        return CourseModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('⚠️ [ACADEMY] Error fetching course $courseId: $e');
    }
    return null;
  }

  /// Stream single course
  Stream<CourseModel?> streamCourse(String courseId) {
    return _coursesRef.doc(courseId).snapshots().map((doc) {
      if (doc.exists) {
        return CourseModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Stream lessons for a course (ordered by lesson `order`)
  Stream<List<LessonModel>> streamLessons(String courseId) {
    return _coursesRef
        .doc(courseId)
        .collection('lessons')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LessonModel.fromFirestore(doc, courseId))
            .toList());
  }

  /// Get lessons once
  Future<List<LessonModel>> getLessons(String courseId) async {
    try {
      final snapshot = await _coursesRef
          .doc(courseId)
          .collection('lessons')
          .orderBy('order')
          .get();
      return snapshot.docs
          .map((doc) => LessonModel.fromFirestore(doc, courseId))
          .toList();
    } catch (e) {
      debugPrint('⚠️ [ACADEMY] Error getting lessons for $courseId: $e');
      return [];
    }
  }

  /// Get single lesson
  Future<LessonModel?> getLesson(String courseId, String lessonId) async {
    try {
      final doc =
          await _coursesRef.doc(courseId).collection('lessons').doc(lessonId).get();
      if (doc.exists) {
        return LessonModel.fromFirestore(doc, courseId);
      }
    } catch (e) {
      debugPrint('⚠️ [ACADEMY] Error getting lesson $lessonId: $e');
    }
    return null;
  }

  /// Get final exam for a course (or auto-generate default if not yet created)
  Future<QuizModel> getCourseExam(CourseModel course) async {
    try {
      final doc = await _coursesRef.doc(course.id).collection('exam').doc('final_exam').get();
      if (doc.exists && doc.data() != null) {
        return QuizModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('⚠️ [ACADEMY] Error fetching exam for course ${course.id}: $e');
    }

    // Fallback: build standard or lesson-aggregated exam
    return await buildDefaultCourseExam(course);
  }

  /// Stream final exam for a course
  Stream<QuizModel?> streamCourseExam(String courseId) {
    return _coursesRef.doc(courseId).collection('exam').doc('final_exam').snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return QuizModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Save or update final exam for a course
  Future<void> saveCourseExam(String courseId, QuizModel exam) async {
    final ref = _coursesRef.doc(courseId).collection('exam').doc('final_exam');
    await ref.set(exam.toMap(), SetOptions(merge: true));
  }

  /// Generate high-quality default exam questions for course based on lessons or topic
  Future<QuizModel> buildDefaultCourseExam(CourseModel course) async {
    final List<QuizQuestionModel> questions = [];

    // Check if lessons have embedded quiz blocks to aggregate
    try {
      final lessons = await getLessons(course.id);
      for (final lesson in lessons) {
        for (final block in lesson.blocks) {
          if (block.type == LessonBlockType.quiz &&
              block.metadata != null &&
              block.metadata!['questions'] is List) {
            final qList = block.metadata!['questions'] as List;
            for (final qData in qList) {
              if (qData is Map<String, dynamic>) {
                final q = QuizQuestionModel.fromMap(qData);
                if (q.question.isNotEmpty && q.options.isNotEmpty) {
                  questions.add(q);
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    // If still empty, supply comprehensive agronomy questions based on course topic
    if (questions.isEmpty) {
      final cat = course.categoryId.toLowerCase();
      if (cat.contains('tomato')) {
        questions.addAll([
          QuizQuestionModel(
            id: 'q_tomato_1',
            question: 'What is the optimal soil pH range for field tomato production?',
            options: ['4.0 - 5.0 (Highly acidic)', '6.0 - 6.8 (Slightly acidic)', '7.5 - 8.5 (Alkaline)', '3.0 - 4.0 (Peat)'],
            correctAnswerIndex: 1,
            explanation: 'Tomatoes thrive best in slightly acidic soils with a pH between 6.0 and 6.8 for optimal nutrient uptake.',
          ),
          QuizQuestionModel(
            id: 'q_tomato_2',
            question: 'What is the primary cause of Blossom End Rot in tomato fruits?',
            options: ['Excessive nitrogen only', 'Calcium deficiency during rapid cell development', 'Bacterial wilt infection', 'Over-pruning leaves'],
            correctAnswerIndex: 1,
            explanation: 'Blossom end rot is caused by calcium deficiency in developing fruits, often worsened by irregular watering.',
          ),
          QuizQuestionModel(
            id: 'q_tomato_3',
            question: 'At what age are tomato seedlings generally ready for field transplanting?',
            options: ['1 to 2 weeks', '3 to 4 weeks (15-20cm tall with 4-5 true leaves)', '8 to 10 weeks', '12 weeks'],
            correctAnswerIndex: 1,
            explanation: 'Healthy seedlings are typically transplanted around 3-4 weeks (21-28 days) when they have 4-5 sturdy true leaves.',
          ),
          QuizQuestionModel(
            id: 'q_tomato_4',
            question: 'Why is crop rotation recommended for solanaceous crops like tomatoes?',
            options: ['To eliminate the need for trellising', 'To break soil-borne disease cycles such as Bacterial Wilt and Fusarium', 'To change fruit color', 'To increase water salinity'],
            correctAnswerIndex: 1,
            explanation: 'Rotating with non-solanaceous crops breaks life cycles of soil pathogens and nematodes.',
          ),
          QuizQuestionModel(
            id: 'q_tomato_5',
            question: 'What is the recommended irrigation method to minimize foliar fungal infections in tomatoes?',
            options: ['Overhead sprinkler', 'Drip irrigation at base', 'Flood irrigation', 'Canopy misting'],
            correctAnswerIndex: 1,
            explanation: 'Drip irrigation delivers moisture directly to roots without wetting leaves, dramatically reducing blight risks.',
          ),
        ]);
      } else if (cat.contains('poultry')) {
        questions.addAll([
          QuizQuestionModel(
            id: 'q_poultry_1',
            question: 'What is the standard brooding temperature required for day-old broiler chicks during week 1?',
            options: ['20°C - 24°C', '32°C - 34°C', '40°C - 45°C', '15°C - 18°C'],
            correctAnswerIndex: 1,
            explanation: 'Day-old chicks cannot self-regulate body temperature and require 32°C - 34°C during their first week of life.',
          ),
          QuizQuestionModel(
            id: 'q_poultry_2',
            question: 'Which of the following is an essential biosecurity measure on a commercial poultry unit?',
            options: ['Allowing wild birds to roost inside', 'Disinfectant footbaths and dedicated footwear at house entrances', 'Feeding damp moldy litter', 'Mixing age groups in one pen'],
            correctAnswerIndex: 1,
            explanation: 'Footbaths, vehicle disinfection, and strict access controls prevent pathogen entry into poultry pens.',
          ),
          QuizQuestionModel(
            id: 'q_poultry_3',
            question: 'What does FCR (Feed Conversion Ratio) measure in broiler farming?',
            options: ['Water consumption per hour', 'Kilograms of feed required to produce 1 kg of live body weight', 'Egg shell thickness', 'Mortality rate per batch'],
            correctAnswerIndex: 1,
            explanation: 'FCR measures feed efficiency; lower FCR indicates more efficient weight gain per kilogram of feed consumed.',
          ),
          QuizQuestionModel(
            id: 'q_poultry_4',
            question: 'Why is proper ventilation crucial even during cold brooding periods?',
            options: ['To cool chicks down rapidly', 'To expel toxic ammonia, carbon dioxide, and excess moisture', 'To dry out the drinker lines', 'To increase light intensity'],
            correctAnswerIndex: 1,
            explanation: 'Continuous fresh air exchange eliminates harmful ammonia fumes and keeps litter dry without creating cold drafts.',
          ),
        ]);
      } else {
        questions.addAll([
          QuizQuestionModel(
            id: 'q_gen_1',
            question: 'What is the foundational principle of Integrated Pest Management (IPM)?',
            options: ['Spraying synthetic pesticides on a strict weekly schedule', 'Combining cultural, biological, and chemical methods to keep pests below economic injury levels', 'Complete eradication of all insects including beneficials', 'Using untreated irrigation water'],
            correctAnswerIndex: 1,
            explanation: 'IPM emphasizes prevention, monitoring, and targeted interventions rather than blanket chemical spraying.',
          ),
          QuizQuestionModel(
            id: 'q_gen_2',
            question: 'How does regular soil testing benefit crop productivity and farm profitability?',
            options: ['It guarantees rainfall', 'It reveals exact nutrient levels and pH, preventing wasteful over- or under-fertilization', 'It eliminates all weed seeds', 'It replaces organic matter'],
            correctAnswerIndex: 1,
            explanation: 'Soil analysis guides precise nutrient application and corrective liming, saving input costs and boosting yield.',
          ),
          QuizQuestionModel(
            id: 'q_gen_3',
            question: 'What is the primary role of mulch on crop beds in semi-arid environments?',
            options: ['Attracting rodents', 'Conserving soil moisture, suppressing weeds, and moderating soil temperature', 'Increasing soil erosion', 'Blocking oxygen from soil'],
            correctAnswerIndex: 1,
            explanation: 'Organic mulch shields soil from direct sunlight, reducing evaporation by up to 60% and controlling weed growth.',
          ),
          QuizQuestionModel(
            id: 'q_gen_4',
            question: 'Why are post-harvest handling and cool-chain management critical for fresh produce profitability?',
            options: ['To change the genetic variety', 'To minimize field heat, reduce respiration rates, and prevent spoilage losses', 'To increase moisture loss', 'To bypass market standards'],
            correctAnswerIndex: 1,
            explanation: 'Rapid cooling and hygienic handling preserve nutritional value, texture, and shelf life for higher market prices.',
          ),
        ]);
      }
    }

    return QuizModel(
      id: 'final_exam',
      title: '${course.title} — Official Final Exam',
      description: 'Complete this certification exam to verify your mastery and earn your accredited AgriBase Academy certificate.',
      passPercentage: 70,
      allowRetry: true,
      questions: questions,
    );
  }

  // ----------------------------------------------------
  // ADMIN ACTIONS
  // ----------------------------------------------------

  /// Stream all courses for admin (all statuses)
  Stream<List<CourseModel>> streamAdminCourses({String? statusFilter}) {
    Query<Map<String, dynamic>> query = _coursesRef;
    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CourseModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  /// Create a new course
  Future<String> createCourse(CourseModel course) async {
    final docId = course.id.isNotEmpty ? course.id : _uuid.v4();
    final now = DateTime.now();
    final data = course.toMap();
    data['createdAt'] = now;
    data['updatedAt'] = now;
    if (course.status == 'published' && data['publishedAt'] == null) {
      data['publishedAt'] = now;
    }
    await _coursesRef.doc(docId).set(data);
    return docId;
  }

  /// Update existing course
  Future<void> updateCourse(CourseModel course) async {
    final data = course.toMap();
    data['updatedAt'] = DateTime.now();
    if (course.status == 'published' && course.publishedAt == null) {
      data['publishedAt'] = DateTime.now();
    }
    await _coursesRef.doc(course.id).update(data);
  }

  /// Delete course and its lessons
  Future<void> deleteCourse(String courseId) async {
    try {
      final lessonsSnap =
          await _coursesRef.doc(courseId).collection('lessons').get();
      for (var doc in lessonsSnap.docs) {
        await doc.reference.delete();
      }
      await _coursesRef.doc(courseId).delete();
    } catch (e) {
      debugPrint('⚠️ [ACADEMY] Error deleting course $courseId: $e');
      rethrow;
    }
  }

  /// Duplicate a course
  Future<String> duplicateCourse(String courseId) async {
    final original = await getCourse(courseId);
    if (original == null) throw Exception('Course not found');

    final newCourseId = _uuid.v4();
    final duplicated = original.copyWith(
      id: newCourseId,
      title: '${original.title} (Copy)',
      status: 'draft',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      publishedAt: null,
      enrolledCount: 0,
      completionCount: 0,
    );

    await createCourse(duplicated);

    // Copy lessons
    final lessons = await getLessons(courseId);
    for (var lesson in lessons) {
      final newLessonId = _uuid.v4();
      final duplicatedLesson = lesson.copyWith(
        id: newLessonId,
        courseId: newCourseId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _coursesRef
          .doc(newCourseId)
          .collection('lessons')
          .doc(newLessonId)
          .set(duplicatedLesson.toMap());
    }

    return newCourseId;
  }

  /// Publish or unpublish course
  Future<void> setCourseStatus(String courseId, String status) async {
    final Map<String, dynamic> update = {
      'status': status,
      'updatedAt': DateTime.now(),
    };
    if (status == 'published') {
      update['publishedAt'] = DateTime.now();
    }
    await _coursesRef.doc(courseId).update(update);
  }

  /// Create or update a lesson
  Future<String> saveLesson(LessonModel lesson) async {
    final lessonId = lesson.id.isNotEmpty ? lesson.id : _uuid.v4();
    final now = DateTime.now();
    final data = lesson.toMap();
    data['updatedAt'] = now;
    if (data['createdAt'] == null) {
      data['createdAt'] = now;
    }

    await _coursesRef
        .doc(lesson.courseId)
        .collection('lessons')
        .doc(lessonId)
        .set(data, SetOptions(merge: true));

    // Update course lesson count
    await _updateCourseLessonCount(lesson.courseId);

    return lessonId;
  }

  /// Delete lesson
  Future<void> deleteLesson(String courseId, String lessonId) async {
    await _coursesRef
        .doc(courseId)
        .collection('lessons')
        .doc(lessonId)
        .delete();
    await _updateCourseLessonCount(courseId);
  }

  /// Reorder lessons
  Future<void> reorderLessons(String courseId, List<LessonModel> reordered) async {
    final batch = _firestore.batch();
    for (int i = 0; i < reordered.length; i++) {
      final lesson = reordered[i];
      final ref = _coursesRef.doc(courseId).collection('lessons').doc(lesson.id);
      batch.update(ref, {'order': i});
    }
    await batch.commit();
  }

  Future<void> _updateCourseLessonCount(String courseId) async {
    try {
      final snap =
          await _coursesRef.doc(courseId).collection('lessons').get();
      await _coursesRef.doc(courseId).update({
        'lessonCount': snap.docs.length,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      debugPrint('⚠️ [ACADEMY] Error updating lesson count: $e');
    }
  }

  /// Recalculates and updates the real live learner & completed count for a course
  Future<void> syncRealLiveStatsForCourse(String courseId) async {
    try {
      final progressSnap = await _firestore
          .collectionGroup('courseProgress')
          .where('courseId', isEqualTo: courseId)
          .get();

      final int liveEnrolledCount = progressSnap.docs.length;
      final int liveCompletionCount = progressSnap.docs
          .where((doc) => doc.data()['completed'] == true)
          .length;

      await _coursesRef.doc(courseId).update({
        'enrolledCount': liveEnrolledCount,
        'completionCount': liveCompletionCount,
      });

      debugPrint('📊 [ACADEMY] Live stats synced for $courseId: $liveEnrolledCount learners, $liveCompletionCount completed');
    } catch (e) {
      debugPrint('⚠️ [ACADEMY] Error syncing live stats for $courseId: $e');
      // Fallback: check certificates collection
      try {
        final certSnap = await _firestore
            .collection('certificates')
            .where('courseId', isEqualTo: courseId)
            .get();
        await _coursesRef.doc(courseId).update({
          'completionCount': certSnap.docs.length,
        });
      } catch (_) {}
    }
  }

  /// Recalculates and synchronizes real live learner & completion stats for all courses
  Future<void> syncRealLiveStatsForAllCourses() async {
    try {
      final coursesSnap = await _coursesRef.get();
      for (final doc in coursesSnap.docs) {
        await syncRealLiveStatsForCourse(doc.id);
      }
      debugPrint('✅ [ACADEMY] All courses live stats successfully synchronized with real database records.');
    } catch (e) {
      debugPrint('⚠️ [ACADEMY] Error syncing all courses live stats: $e');
    }
  }

  // ----------------------------------------------------
  // STARTER SEED DATA
  // ----------------------------------------------------

  /// Seeds realistic initial high quality courses if none exist in Firestore
  Future<void> seedStarterCoursesIfEmpty() async {
    try {
      final snap = await _coursesRef.limit(1).get();
      if (snap.docs.isNotEmpty) return;

      debugPrint('🌱 [ACADEMY] Firestore courses empty. Seeding starter courses...');

      final tomatoCourseId = _uuid.v4();
      final poultryCourseId = _uuid.v4();
      final irrigationCourseId = _uuid.v4();

      final tomatoCourse = CourseModel(
        id: tomatoCourseId,
        title: 'Tomato Farming for Beginners',
        shortDescription: 'Master commercial and home tomato production from seed to harvest.',
        description: 'A comprehensive step-by-step masterclass on tomato agronomy designed specifically for African conditions, focusing on nursery preparation, spacing, irrigation, pest monitoring, fertilizer budgeting, and market harvesting.',
        categoryId: 'crop_production',
        categoryName: 'Crop Production',
        difficulty: 'Beginner',
        language: 'English',
        thumbnailUrl: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=800&auto=format&fit=crop&q=80',
        instructorName: 'Dr. T. Chinatsvi (Agronomist)',
        estimatedDuration: '2h 15m',
        isFree: true,
        isFeatured: true,
        status: 'published',
        cropOrLivestock: 'Tomato',
        targetRegions: ['Southern Africa', 'East Africa', 'West Africa'],
        targetCountries: ['Zimbabwe', 'South Africa', 'Zambia', 'Kenya', 'Nigeria'],
        whatYouWillLearn: [
          'Prepare a disease-free tomato seedling nursery',
          'Select the right hybrid varieties for open field & greenhouse',
          'Accurate plant spacing and population estimation',
          'Drip and furrow irrigation scheduling during flowering',
          'Balanced nutrient and fertilizer top-dressing schedules',
          'Integrated pest management for Tuta Absoluta and blight',
          'Harvesting stages and farm budget calculations',
        ],
        agriculturalSource: 'AgriBase Agricultural Extension & Hort Research Institute',
        disclaimer: 'AgriBase provides educational recommendations. Adjust fertilizer and spray rates based on local soil tests and regional agricultural extension guidance.',
        lessonCount: 4,
        enrolledCount: 0,
        completionCount: 0,
        rating: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        publishedAt: DateTime.now(),
      );

      await createCourse(tomatoCourse);

      // Lesson 1: Variety Selection & Nursery
      final l1Id = _uuid.v4();
      await saveLesson(
        LessonModel(
          id: l1Id,
          courseId: tomatoCourseId,
          title: 'Lesson 1 — Site & Variety Selection',
          description: 'Choosing well-drained loamy soils and disease-resistant hybrid varieties.',
          order: 0,
          duration: '15 min',
          isRequired: true,
          status: 'published',
          sourcesAndReferences: [
            'Seed Co Horticultural Variety Guide',
            'Department of Agricultural Research & Extension (AGRITEX)',
          ],
          blocks: [
            LessonBlockModel(
              id: _uuid.v4(),
              type: LessonBlockType.text,
              order: 0,
              content: '### Welcome to Tomato Production!\n\nTomatoes (*Solanum lycopersicum*) are among the most lucrative horticultural crops across Africa. Success begins with **proper site selection** and choosing varieties matched to your local market and rainfall pattern.\n\n#### Key Site Selection Criteria:\n* **Soil:** Well-drained sandy loam to clay loam with pH between 6.0 and 6.8.\n* **Sunlight:** Full sun exposure (at least 6-8 hours daily).\n* **Water:** Reliable, clean irrigation source free of high salinity.',
            ),
            LessonBlockModel(
              id: _uuid.v4(),
              type: LessonBlockType.tip,
              order: 1,
              title: '💡 FARMER TIP',
              content: 'Avoid planting tomatoes in soils where potatoes, eggplants, or peppers were grown in the previous season to prevent bacterial wilt and root-knot nematode build-up.',
            ),
            LessonBlockModel(
              id: _uuid.v4(),
              type: LessonBlockType.image,
              order: 2,
              mediaUrl: 'https://images.unsplash.com/photo-1592841200221-a6898f307baa?w=800&auto=format&fit=crop&q=80',
              caption: 'Healthy nursery seedlings ready for hardening off.',
            ),
            LessonBlockModel(
              id: _uuid.v4(),
              type: LessonBlockType.warning,
              order: 3,
              title: '⚠️ IMPORTANT',
              content: 'Nursery seedlings must undergo a 5-7 day hardening-off period (reduced watering) before field transplanting to minimize transplant shock.',
            ),
          ],
        ),
      );

      // Lesson 2: Spacing & Population
      final l2Id = _uuid.v4();
      await saveLesson(
        LessonModel(
          id: l2Id,
          courseId: tomatoCourseId,
          title: 'Lesson 2 — Spacing & Population Calculation',
          description: 'Optimal plant density for open-field and staked production.',
          order: 1,
          duration: '15 min',
          isRequired: true,
          status: 'published',
          blocks: [
            LessonBlockModel(
              id: _uuid.v4(),
              type: LessonBlockType.text,
              order: 0,
              content: '### Plant Spacing & Density\n\nStandard open-field staked tomato spacing is typically **90 cm to 100 cm** between rows and **45 cm to 50 cm** within rows, giving a population of roughly **22,000 to 24,000 plants per hectare**.\n\nCorrect spacing ensures adequate air circulation, lowers fungal disease pressure, and allows easy spraying and harvesting.',
            ),
            LessonBlockModel(
              id: _uuid.v4(),
              type: LessonBlockType.calculator,
              order: 1,
              calculatorType: 'population',
              title: 'Calculate Your Plant Population',
              content: 'Use our interactive Population Calculator to find the exact number of seedlings required for your plot size.',
            ),
          ],
        ),
      );

      // Lesson 3: Fertilizer & Irrigation Management
      final l3Id = _uuid.v4();
      await saveLesson(
        LessonModel(
          id: l3Id,
          courseId: tomatoCourseId,
          title: 'Lesson 3 — Nutrient & Irrigation Management',
          description: 'Basal application, Calcium nitrate, and Potassium top-dressing.',
          order: 2,
          duration: '20 min',
          isRequired: true,
          status: 'published',
          blocks: [
            LessonBlockModel(
              id: _uuid.v4(),
              type: LessonBlockType.text,
              order: 0,
              content: '### Feeding Your Tomatoes\n\nTomatoes are heavy feeders requiring:\n1. **Basal Application:** Compound C or NPK 7-14-7 at planting.\n2. **Early Vegetative:** Calcium Nitrate to strengthen cell walls and prevent Blossom End Rot.\n3. **Flowering & Fruiting:** High Potassium (Potassium Nitrate / SOP) to build fruit size, brix, and shelf-life.',
            ),
            LessonBlockModel(
              id: _uuid.v4(),
              type: LessonBlockType.tip,
              order: 1,
              title: '💡 FARMER TIP',
              content: 'Irregular watering during fruiting causes fruit cracking and blossom end rot. Maintain steady soil moisture through drip irrigation.',
            ),
            LessonBlockModel(
              id: _uuid.v4(),
              type: LessonBlockType.calculator,
              order: 2,
              calculatorType: 'fertilizer',
              title: 'Fertilizer Requirement Calculator',
              content: 'Compute basal and top-dressing bags needed for your field.',
            ),
            LessonBlockModel(
              id: _uuid.v4(),
              type: LessonBlockType.calculator,
              order: 3,
              calculatorType: 'irrigation',
              title: 'Irrigation Water Requirement Calculator',
              content: 'Calculate daily irrigation runtime based on crop stage.',
            ),
          ],
        ),
      );

      // Lesson 4: Final Quiz & Economics
      final l4Id = _uuid.v4();
      await saveLesson(
        LessonModel(
          id: l4Id,
          courseId: tomatoCourseId,
          title: 'Lesson 4 — Farm Economics & Final Assessment',
          description: 'Calculate gross margins and take the certification exam.',
          order: 3,
          duration: '20 min',
          isRequired: true,
          status: 'published',
          blocks: [
            LessonBlockModel(
              id: _uuid.v4(),
              type: LessonBlockType.text,
              order: 0,
              content: '### Farm Economics & Production Costs\n\nBefore marketing your crop, accurately calculate seed, fertilizer, chemical, labor, and transport costs to determine your break-even price per crate or kilogram.',
            ),
            LessonBlockModel(
              id: _uuid.v4(),
              type: LessonBlockType.calculator,
              order: 1,
              calculatorType: 'profit',
              title: 'Farm Profit & Margin Calculator',
              content: 'Estimate your total revenue, operational costs, and net farm profit.',
            ),
            LessonBlockModel(
              id: _uuid.v4(),
              type: LessonBlockType.quiz,
              order: 2,
              title: 'Tomato Farming Certification Quiz',
              metadata: {
                'title': 'Tomato Production Knowledge Assessment',
                'description': 'Answer all questions correctly to earn your AgriBase Certificate.',
                'passPercentage': 75,
                'allowRetry': true,
                'questions': [
                  {
                    'id': 'q1',
                    'question': 'What is the primary cause of Blossom End Rot in tomato fruits?',
                    'options': [
                      'Excessive sunlight on leaves',
                      'Calcium deficiency often caused by irregular watering',
                      'Over-fertilization with Phosphorus',
                      'Insect pest attacks'
                    ],
                    'correctAnswerIndex': 1,
                    'explanation': 'Blossom End Rot is a physiological disorder caused by inadequate calcium uptake in rapidly expanding fruit cells, usually triggered by irregular irrigation.',
                  },
                  {
                    'id': 'q2',
                    'question': 'Why is crop rotation important before planting tomatoes?',
                    'options': [
                      'To avoid soil-borne diseases such as bacterial wilt and nematodes',
                      'To make weeds grow faster',
                      'To increase soil salinity',
                      'To change fruit color'
                    ],
                    'correctAnswerIndex': 0,
                    'explanation': 'Rotating away from solanaceous crops prevents pest and pathogen build-up in the soil profile.',
                  },
                  {
                    'id': 'q3',
                    'question': 'Which key nutrient is most critical during tomato fruit sizing and ripening?',
                    'options': [
                      'Nitrogen only',
                      'Potassium (K)',
                      'Iron',
                      'Chlorine'
                    ],
                    'correctAnswerIndex': 1,
                    'explanation': 'Potassium regulates water pressure, sugars, fruit density, skin firmness, and overall yield.',
                  },
                  {
                    'id': 'q4',
                    'question': 'What is the purpose of hardening off seedlings before transplanting?',
                    'options': [
                      'To make the leaves turn yellow',
                      'To prepare seedlings for outdoor climate conditions and reduce transplant shock',
                      'To kill root aphids',
                      'To dry out the soil completely'
                    ],
                    'correctAnswerIndex': 1,
                    'explanation': 'Hardening off acclimates delicate nursery plants to field sunlight, wind, and moisture fluctuations.',
                  }
                ]
              },
            ),
          ],
        ),
      );

      // Seed Poultry Course
      final poultryCourse = CourseModel(
        id: poultryCourseId,
        title: 'Broiler & Layer Poultry Management',
        shortDescription: 'Modern poultry housing, brooding temperatures, feed formulation, and biosecurity.',
        description: 'Learn efficient poultry management techniques suited for smallholder and commercial setups across Africa. Covers house design, brooding chick warmth, vaccination schedules, feed conversion ratios (FCR), and disease prevention.',
        categoryId: 'poultry',
        categoryName: 'Poultry',
        difficulty: 'Beginner',
        language: 'English',
        thumbnailUrl: 'https://images.unsplash.com/photo-1548550023-2bdb3c5beed7?w=800&auto=format&fit=crop&q=80',
        instructorName: 'Vet Officer Dr. M. Ncube',
        estimatedDuration: '1h 45m',
        isFree: true,
        isFeatured: true,
        status: 'published',
        cropOrLivestock: 'Poultry',
        targetRegions: ['All Africa'],
        targetCountries: ['Zimbabwe', 'South Africa', 'Kenya', 'Zambia', 'Ghana'],
        whatYouWillLearn: [
          'Design cost-effective, well-ventilated poultry fowl runs',
          'Manage brooding temperatures for Day 1 to Day 14 chicks',
          'Biosecurity protocols to prevent Newcastle and Gumboro diseases',
          'Understanding Feed Conversion Ratio (FCR) and balanced rations',
        ],
        lessonCount: 2,
        enrolledCount: 0,
        completionCount: 0,
        rating: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        publishedAt: DateTime.now(),
      );
      await createCourse(poultryCourse);

      // Seed Irrigation Course
      final irrigationCourse = CourseModel(
        id: irrigationCourseId,
        title: 'Drip & Smart Irrigation for African Farms',
        shortDescription: 'Maximize water use efficiency, reduce pumping electricity, and boost crop yields.',
        description: 'Comprehensive guide to gravity drip systems, solar pumping, filtration, and water scheduling for small to medium scale farms.',
        categoryId: 'irrigation',
        categoryName: 'Irrigation',
        difficulty: 'Intermediate',
        language: 'English',
        thumbnailUrl: 'https://images.unsplash.com/photo-1563514227147-6d2ff665a6a0?w=800&auto=format&fit=crop&q=80',
        instructorName: 'Eng. K. Moyo (Irrigation Specialist)',
        estimatedDuration: '1h 15m',
        isFree: true,
        isFeatured: false,
        status: 'published',
        targetRegions: ['Sub-Saharan Africa'],
        whatYouWillLearn: [
          'Sizing drip lines and emitter discharge rates',
          'Calculating crop water requirements based on ET0',
          'Operating disk and screen filters to prevent emitter clogging',
        ],
        lessonCount: 2,
        enrolledCount: 0,
        completionCount: 0,
        rating: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        publishedAt: DateTime.now(),
      );
      await createCourse(irrigationCourse);

      debugPrint('✅ [ACADEMY] Starter courses seeded successfully!');
    } catch (e) {
      debugPrint('⚠️ [ACADEMY] Error seeding starter courses: $e');
    }
  }
}
