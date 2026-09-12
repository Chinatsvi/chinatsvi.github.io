import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../models/academy/course_model.dart';
import '../../../models/academy/course_progress_model.dart';
import '../course_details_screen.dart';

class CourseCard extends StatelessWidget {
  final CourseModel course;
  final CourseProgressModel? progress;
  final bool isHorizontal;
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.course,
    this.progress,
    this.isHorizontal = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return _buildHorizontalCard(context);
    }
    return _buildVerticalCard(context);
  }

  Widget _buildVerticalCard(BuildContext context) {
    final double percent = progress?.progressPercent ?? 0.0;
    final bool isCompleted = progress?.completed ?? false;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseDetailsScreen(courseId: course.id),
                ),
              );
            },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with Badges
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  color: Colors.green.shade100,
                  child: course.thumbnailUrl != null &&
                          course.thumbnailUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: course.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.green.shade600,
                            ),
                          ),
                          errorWidget: (_, __, ___) => _buildFallbackHeader(),
                        )
                      : _buildFallbackHeader(),
                ),

                // Difficulty badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getDifficultyIcon(course.difficulty),
                          color: _getDifficultyColor(course.difficulty),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          course.difficulty,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Free / Premium / Completed badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: isCompleted
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Completed',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: course.isFree
                                ? Colors.teal.shade700
                                : Colors.amber.shade800,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            course.isFree ? 'FREE' : '🔒 PREMIUM',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          course.categoryName,
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time, size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 3),
                      Text(
                        course.estimatedDuration,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.menu_book, size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 3),
                      Text(
                        '${course.lessonCount} Lessons',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.25,
                    ),
                  ),
                  if (progress != null && percent > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent / 100,
                              backgroundColor: Colors.grey.shade200,
                              color: isCompleted
                                  ? Colors.green
                                  : Colors.orange.shade700,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${percent.toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context) {
    final double percent = progress?.progressPercent ?? 0.0;
    final bool isCompleted = progress?.completed ?? false;

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 14),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseDetailsScreen(courseId: course.id),
                  ),
                );
              },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 110,
                    width: double.infinity,
                    color: Colors.green.shade100,
                    child: course.thumbnailUrl != null &&
                            course.thumbnailUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: course.thumbnailUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.green.shade600,
                              ),
                            ),
                            errorWidget: (_, __, ___) => _buildFallbackHeader(),
                          )
                        : _buildFallbackHeader(),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.shade700
                            : (course.isFree
                                ? Colors.teal.shade700
                                : Colors.amber.shade800),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCompleted
                            ? 'Done'
                            : (course.isFree ? 'FREE' : 'PREMIUM'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          course.estimatedDuration,
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        const Text(' • ', style: TextStyle(color: Colors.grey)),
                        Text(
                          '${course.lessonCount} Lessons',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          backgroundColor: Colors.grey.shade200,
                          color:
                              isCompleted ? Colors.green : Colors.green.shade700,
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackHeader() {
    return Center(
      child: Icon(
        Icons.agriculture,
        size: 48,
        color: Colors.green.shade300,
      ),
    );
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'intermediate':
        return Icons.trending_up;
      case 'advanced':
        return Icons.star;
      case 'beginner':
      default:
        return Icons.eco;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'intermediate':
        return Colors.amber;
      case 'advanced':
        return Colors.orangeAccent;
      case 'beginner':
      default:
        return Colors.greenAccent;
    }
  }
}
