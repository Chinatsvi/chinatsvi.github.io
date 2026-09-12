import 'package:flutter/material.dart';
import '../../../models/academy/lesson_model.dart';

enum LessonStatus {
  completed,
  current,
  locked,
}

class LessonCard extends StatelessWidget {
  final LessonModel lesson;
  final int index;
  final LessonStatus status;
  final VoidCallback? onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.index,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = status == LessonStatus.locked;
    final isCompleted = status == LessonStatus.completed;
    final isCurrent = status == LessonStatus.current;

    return Card(
      elevation: isCurrent ? 2 : 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent
            ? BorderSide(color: Colors.green.shade600, width: 1.5)
            : BorderSide(color: Colors.grey.shade200),
      ),
      color: isLocked ? Colors.grey.shade50 : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isLocked ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Status Circle / Icon
              _buildStatusIcon(),
              const SizedBox(width: 14),

              // Title and duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.w600,
                        color: isLocked ? Colors.grey.shade600 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 13, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          lesson.duration,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (lesson.blocks.any((b) => b.type.name == 'quiz')) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.quiz_outlined,
                              size: 13, color: Colors.blue.shade700),
                          const SizedBox(width: 3),
                          Text(
                            'Includes Quiz',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Trailing Arrow or Lock
              Icon(
                isLocked
                    ? Icons.lock_outline
                    : (isCompleted
                        ? Icons.check_circle
                        : Icons.play_circle_outline),
                color: isLocked
                    ? Colors.grey.shade400
                    : (isCompleted
                        ? Colors.green.shade600
                        : Colors.green.shade700),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case LessonStatus.completed:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(Icons.check, size: 18, color: Colors.green.shade800),
          ),
        );
      case LessonStatus.current:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.green.shade700,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.play_arrow, size: 18, color: Colors.white),
          ),
        );
      case LessonStatus.locked:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        );
    }
  }
}
