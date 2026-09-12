import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/academy/course_progress_model.dart';
import '../../models/academy/certificate_model.dart';
import '../../models/academy/badge_model.dart';
import '../../models/academy/course_model.dart';
import '../../models/academy/lesson_model.dart';
import '../../models/academy/quiz_model.dart';
import 'academy_service.dart';

class CourseExamResult {
  final bool passed;
  final int scorePercentage;
  final int correctCount;
  final int totalQuestions;
  final int passPercentage;
  final CertificateModel? certificate;
  final String message;

  CourseExamResult({
    required this.passed,
    required this.scorePercentage,
    required this.correctCount,
    required this.totalQuestions,
    required this.passPercentage,
    this.certificate,
    required this.message,
  });
}

class AcademyProgressService {
  static final AcademyProgressService instance = AcademyProgressService._internal();
  AcademyProgressService._internal();

  static const int minimumCertificateScore = 50;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // ----------------------------------------------------
  // DATA SAVER & OFFLINE CACHE
  // ----------------------------------------------------

  static const String _keyDataSaver = 'academy_data_saver_enabled';
  static const String _keyOfflineLessonPrefix = 'academy_offline_lesson_';

  Future<bool> isDataSaverEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDataSaver) ?? false;
  }

  Future<void> setDataSaverEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDataSaver, enabled);
  }

  Future<void> cacheLessonOffline(LessonModel lesson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(lesson.toMap());
      await prefs.setString('$_keyOfflineLessonPrefix${lesson.id}', jsonStr);
    } catch (e) {
      debugPrint('⚠️ [ACADEMY] Error caching lesson offline: $e');
    }
  }

  Future<LessonModel?> getCachedLessonOffline(String courseId, String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('$_keyOfflineLessonPrefix$lessonId');
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return LessonModel.fromMap(map, lessonId, courseId);
      }
    } catch (e) {
      debugPrint('⚠️ [ACADEMY] Error reading offline cached lesson: $e');
    }
    return null;
  }

  // ----------------------------------------------------
  // PROGRESS TRACKING
  // ----------------------------------------------------

  /// Stream of user's progress for a single course
  Stream<CourseProgressModel?> streamCourseProgress(String courseId, [String? userId]) {
    final uid = userId ?? _currentUserId;
    if (uid == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('courseProgress')
        .doc(courseId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return CourseProgressModel.fromFirestore(doc, uid);
      }
      return null;
    });
  }

  /// Get user's progress for a single course once
  Future<CourseProgressModel?> getCourseProgress(String courseId, [String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('courseProgress')
        .doc(courseId)
        .get();

    if (doc.exists) {
      return CourseProgressModel.fromFirestore(doc, uid);
    }
    return null;
  }

  /// Stream of all started/in-progress courses for current user
  Stream<List<CourseProgressModel>> streamUserProgressList([String? userId]) {
    final uid = userId ?? _currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('courseProgress')
        .orderBy('lastAccessedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CourseProgressModel.fromFirestore(doc, uid))
            .toList());
  }

  /// Start a course (records enrollment if not yet started)
  Future<CourseProgressModel> startOrTouchCourse(CourseModel course, [String? firstLessonId]) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception('Must be logged in to learn');

    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('courseProgress')
        .doc(course.id);

    final doc = await ref.get();
    final now = DateTime.now();

    if (doc.exists) {
      final updateData = <String, dynamic>{'lastAccessedAt': now};
      if (firstLessonId != null) {
        updateData['lastLessonId'] = firstLessonId;
      }
      await ref.update(updateData);
      final updated = await ref.get();
      return CourseProgressModel.fromFirestore(updated, uid);
    } else {
      final initial = CourseProgressModel(
        courseId: course.id,
        userId: uid,
        startedAt: now,
        lastAccessedAt: now,
        progressPercent: 0.0,
        lastLessonId: firstLessonId,
        completed: false,
        completedLessonIds: [],
        quizScores: {},
      );
      await ref.set(initial.toMap());

      // Sync real live enrolledCount on course from actual database records
      AcademyService.instance.syncRealLiveStatsForCourse(course.id).catchError((_) {});

      return initial;
    }
  }

  /// Mark a lesson as complete and recalculate progress percentage
  Future<CourseProgressModel> markLessonComplete({
    required CourseModel course,
    required String lessonId,
    int? quizScore,
    bool hasQuiz = false,
    String? nextLessonId,
    String? userName,
  }) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception('Must be logged in');

    final progressRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('courseProgress')
        .doc(course.id);

    final doc = await progressRef.get();
    final now = DateTime.now();

    // If lesson has a quiz, require at least 50% pass mark before marking complete
    final isQuizPassed = !hasQuiz || (quizScore != null && quizScore >= minimumCertificateScore);
    if (!isQuizPassed) {
      if (doc.exists) {
        final existing = CourseProgressModel.fromFirestore(doc, uid);
        if (quizScore != null) {
          final updatedScores = Map<String, int>.from(existing.quizScores);
          updatedScores[lessonId] = quizScore;
          await progressRef.set({
            'quizScores': updatedScores,
            'lastAccessedAt': now,
          }, SetOptions(merge: true));
        }
        return CourseProgressModel.fromFirestore(await progressRef.get(), uid);
      }
      return CourseProgressModel(
        courseId: course.id,
        userId: uid,
        startedAt: now,
        lastAccessedAt: now,
        quizScores: quizScore != null ? {lessonId: quizScore} : {},
      );
    }

    List<String> completedIds = [];
    Map<String, int> scores = {};
    DateTime startedAt = now;

    if (doc.exists) {
      final existing = CourseProgressModel.fromFirestore(doc, uid);
      completedIds = List.from(existing.completedLessonIds);
      scores = Map.from(existing.quizScores);
      startedAt = existing.startedAt;
    }

    if (!completedIds.contains(lessonId)) {
      completedIds.add(lessonId);
    }

    if (quizScore != null) {
      scores[lessonId] = quizScore;
    }

    final totalLessons = course.lessonCount > 0 ? course.lessonCount : 1;
    final progressPercent =
        ((completedIds.length / totalLessons) * 100).clamp(0.0, 100.0);
    final isComplete = completedIds.length >= totalLessons;

    final updatedModel = CourseProgressModel(
      courseId: course.id,
      userId: uid,
      startedAt: startedAt,
      lastAccessedAt: now,
      completedAt: isComplete ? now : null,
      progressPercent: progressPercent,
      lastLessonId: nextLessonId ?? lessonId,
      completed: isComplete,
      completedLessonIds: completedIds,
      quizScores: scores,
      bestQuizScore: quizScore ?? 0,
    );

    await progressRef.set(updatedModel.toMap(), SetOptions(merge: true));

    // If newly completed, trigger certificate & badge award
    if (isComplete) {
      await _onCourseCompleted(course, uid, userName ?? 'Farmer', scores);
    }

    return updatedModel;
  }

  /// Submit official course final exam and evaluate dynamic percentage
  Future<CourseExamResult> submitCourseExam({
    required CourseModel course,
    required QuizModel exam,
    required Map<int, int> userAnswers, // questionIndex -> selectedOptionIndex
    required String userName,
  }) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception('Must be logged in to take the course exam');

    final totalQuestions = exam.questions.length;
    if (totalQuestions == 0) {
      throw Exception('This course exam has no questions.');
    }

    // Backend grading: compare user selection to question.correctAnswerIndex
    int correctCount = 0;
    for (int i = 0; i < totalQuestions; i++) {
      final selected = userAnswers[i];
      if (selected != null && selected == exam.questions[i].correctAnswerIndex) {
        correctCount++;
      }
    }

    // Dynamic score percentage calculation for ANY question count (10, 20, 50, etc.)
    // E.g. 11/20 = 55%, 45/50 = 90%
    final scorePercentage = ((correctCount / totalQuestions) * 100).round().clamp(0, 100);
    final targetPassPercentage = exam.passPercentage;
    final isPassed = scorePercentage >= targetPassPercentage;

    final progressRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('courseProgress')
        .doc(course.id);

    final now = DateTime.now();

    CertificateModel? awardedCert;

    if (isPassed) {
      // 1. Update progress to completed 100%
      await progressRef.set({
        'courseId': course.id,
        'userId': uid,
        'completed': true,
        'completedAt': now,
        'lastAccessedAt': now,
        'progressPercent': 100.0,
        'bestQuizScore': scorePercentage,
        'examScore': scorePercentage,
      }, SetOptions(merge: true));

      // 2. Award or update certificate with the exact calculated exam score
      awardedCert = await _awardCertificate(
        course: course,
        userId: uid,
        userName: userName,
        scorePercentage: scorePercentage,
      );

      // 3. Friendly pass message
      return CourseExamResult(
        passed: true,
        scorePercentage: scorePercentage,
        correctCount: correctCount,
        totalQuestions: totalQuestions,
        passPercentage: targetPassPercentage,
        certificate: awardedCert,
        message: 'Congratulations! You passed the official examination with $scorePercentage% ($correctCount of $totalQuestions correct) and earned your accredited AgriBase Academy Certificate!',
      );
    } else {
      // Failed attempt: record score but DO NOT mark completed and DO NOT reveal answers
      await progressRef.set({
        'courseId': course.id,
        'userId': uid,
        'lastAccessedAt': now,
        'lastExamScore': scorePercentage,
      }, SetOptions(merge: true));

      return CourseExamResult(
        passed: false,
        scorePercentage: scorePercentage,
        correctCount: correctCount,
        totalQuestions: totalQuestions,
        passPercentage: targetPassPercentage,
        certificate: null,
        message: 'You scored $scorePercentage% ($correctCount of $totalQuestions correct). The passing mark is $targetPassPercentage%.\n\nTake time to review the course material and retake the exam when you are ready to earn your certificate.',
      );
    }
  }

  Future<CertificateModel> _awardCertificate({
    required CourseModel course,
    required String userId,
    required String userName,
    required int scorePercentage,
  }) async {
    final existingCertificateQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('academyCertificates')
        .where('courseId', isEqualTo: course.id)
        .limit(1)
        .get();

    String certId;
    String certNumber;

    if (existingCertificateQuery.docs.isNotEmpty) {
      final existingDoc = existingCertificateQuery.docs.first;
      certId = existingDoc.id;
      final existingModel = CertificateModel.fromFirestore(existingDoc);
      certNumber = existingModel.certificateNumber;
    } else {
      certId = _uuid.v4();
      final year = DateTime.now().year;
      final randomSuffix = (1000 + (certId.hashCode % 9000)).abs();
      certNumber = 'AGRI-$year-${course.categoryId.toUpperCase().replaceAll('_', '')}-$randomSuffix';
    }

    final cert = CertificateModel(
      id: certId,
      certificateNumber: certNumber,
      courseId: course.id,
      courseTitle: course.title,
      userId: userId,
      userName: userName,
      issuedAt: DateTime.now(),
      scorePercentage: scorePercentage,
      badgeName: _getBadgeNameForCourse(course),
      instructorName: course.instructorName,
    );

    // Save certificate in user's subcollection
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('academyCertificates')
        .doc(certId)
        .set(cert.toMap(), SetOptions(merge: true));

    // Save in global certificates collection for public authenticity verification
    await _firestore
        .collection('certificates')
        .doc(certId)
        .set(cert.toMap(), SetOptions(merge: true));

    // Award badge
    final badgeId = _uuid.v4();
    final badge = AcademyBadgeModel(
      id: badgeId,
      name: _getBadgeNameForCourse(course),
      icon: _getBadgeIconForCourse(course),
      description: 'Completed "${course.title}" with a $scorePercentage% pass score.',
      category: course.categoryName,
      earnedAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('academyBadges')
        .doc(badgeId)
        .set(badge.toMap(), SetOptions(merge: true));

    // Sync real live completionCount and enrolledCount on course
    AcademyService.instance.syncRealLiveStatsForCourse(course.id).catchError((_) {});

    return cert;
  }

  Future<void> _onCourseCompleted(
    CourseModel course,
    String userId,
    String userName,
    Map<String, int> quizScores,
  ) async {
    try {
      // Calculate overall score average
      int avgScore = 100;
      if (quizScores.isNotEmpty) {
        final total = quizScores.values.fold<int>(0, (acc, val) => acc + val);
        avgScore = (total / quizScores.length).round();
      }

      if (avgScore < minimumCertificateScore || avgScore > 100) {
        debugPrint(
          'ℹ️ [ACADEMY] Certificate not awarded for ${course.title}: score $avgScore%',
        );
        return;
      }

      await _awardCertificate(
        course: course,
        userId: userId,
        userName: userName,
        scorePercentage: avgScore,
      );

      debugPrint('🎉 [ACADEMY] Course completed: Certificate awarded to $userName');
    } catch (e) {
      debugPrint('⚠️ [ACADEMY] Error awarding completion certificate: $e');
    }
  }

  String _getBadgeNameForCourse(CourseModel course) {
    final cat = course.categoryId.toLowerCase();
    if (cat.contains('tomato')) return '🍅 Tomato Specialist';
    if (cat.contains('poultry')) return '🐔 Poultry Expert';
    if (cat.contains('livestock')) return '🐄 Livestock Manager';
    if (cat.contains('irrigation')) return '💧 Irrigation Pro';
    if (cat.contains('aqua')) return '🐟 Aquaculture Pro';
    if (cat.contains('business')) return '💰 Agribusiness Master';
    return '🎓 ${course.categoryName} Graduate';
  }

  String _getBadgeIconForCourse(CourseModel course) {
    final cat = course.categoryId.toLowerCase();
    if (cat.contains('tomato')) return '🍅';
    if (cat.contains('poultry')) return '🐔';
    if (cat.contains('livestock')) return '🐄';
    if (cat.contains('irrigation')) return '💧';
    if (cat.contains('aqua')) return '🐟';
    if (cat.contains('business')) return '💰';
    return '🌱';
  }

  // ----------------------------------------------------
  // CERTIFICATES & BADGES FOR PROFILE
  // ----------------------------------------------------

  /// Stream certificates for any user (for About Farmer profile screen)
  Stream<List<CertificateModel>> streamUserCertificates(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('academyCertificates')
        .orderBy('issuedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CertificateModel.fromFirestore(doc))
            .toList());
  }

  /// Stream badges for any user (for About Farmer profile screen)
  Stream<List<AcademyBadgeModel>> streamUserBadges(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('academyBadges')
        .orderBy('earnedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AcademyBadgeModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Upload external certificate (farmer uploading their own agricultural diploma/certificate)
  Future<String> addExternalCertificate({
    required String userId,
    required String courseTitle,
    required String issuer,
    required String description,
    required String? certificateUrl,
  }) async {
    final certId = _uuid.v4();
    final now = DateTime.now();
    final cert = CertificateModel(
      id: certId,
      certificateNumber: 'EXT-${now.year}-${(certId.hashCode % 9000).abs()}',
      courseId: 'external',
      courseTitle: courseTitle,
      userId: userId,
      userName: FirebaseAuth.instance.currentUser?.displayName ?? 'Farmer',
      issuedAt: now,
      scorePercentage: 100,
      badgeName: '📜 Verified Agricultural Certificate',
      certificateUrl: certificateUrl,
      isExternalUploaded: true,
      externalIssuer: issuer,
      externalDescription: description,
      instructorName: issuer,
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('academyCertificates')
        .doc(certId)
        .set(cert.toMap());

    return certId;
  }

  // ----------------------------------------------------
  // BOOKMARKS
  // ----------------------------------------------------

  Stream<List<AcademyBookmarkModel>> streamBookmarks([String? userId]) {
    final uid = userId ?? _currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('academyBookmarks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AcademyBookmarkModel.fromFirestore(doc))
            .toList());
  }

  Future<bool> isBookmarked(String courseId, [String? lessonId]) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    final docId = lessonId != null ? '${courseId}_$lessonId' : courseId;
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('academyBookmarks')
        .doc(docId)
        .get();
    return doc.exists;
  }

  Future<bool> toggleBookmark({
    required String courseId,
    String? lessonId,
    required String title,
    String? subtitle,
    String? thumbnailUrl,
  }) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    final docId = lessonId != null ? '${courseId}_$lessonId' : courseId;
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('academyBookmarks')
        .doc(docId);

    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
      return false;
    } else {
      final bookmark = AcademyBookmarkModel(
        id: docId,
        type: lessonId != null ? 'lesson' : 'course',
        courseId: courseId,
        lessonId: lessonId,
        title: title,
        subtitle: subtitle,
        thumbnailUrl: thumbnailUrl,
        createdAt: DateTime.now(),
      );
      await ref.set(bookmark.toMap());
      return true;
    }
  }
}
