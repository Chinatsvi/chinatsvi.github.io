import 'package:flutter/material.dart';
import 'package:agribased/models/job_model.dart';
import 'package:agribased/app/utils/formatters.dart';
import 'package:agribased/widgets/user_info_display.dart';

class JobCard extends StatelessWidget {
  final JobPost job;
  final VoidCallback onTap;
  final bool showStatus;
  final VoidCallback? onDelete;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.showStatus = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isFarmerJob = job.postType == JobPostType.farmerJob;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with type and status badges
              Row(
                children: [
                  _buildTypeChip(isFarmerJob),
                  const SizedBox(width: 8),
                  if (showStatus) ...[
                    _buildStatusChip(job.status),
                    const SizedBox(width: 8),
                  ],
                  _buildCategoryChip(job.category),
                  if (job.isExpired) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'EXPIRED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                job.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Description preview
              Text(
                job.description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Location and stats row
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.location,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Bottom row with salary, views, and posted date
              Row(
                children: [
                  if (isFarmerJob && job.salary != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '\$${job.salary!.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (!isFarmerJob && job.expectedSalary != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        job.expectedSalary!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(Icons.visibility, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    '${job.viewCount}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.people, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    '${job.applicationCount}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const Spacer(),
                  Text(
                    Formatter.timeAgo(job.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),

              // Posted by (only for local jobs)
              if (!job.isApiJob) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    UserProfileImage(
                      userId: job.userId,
                      radius: 14,
                      initialImageUrl: job.userProfilePic ?? '', // Fallback to job's stored avatar for instant display
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UserNameDisplay(
                            userId: job.userId,
                            initialName: job.userName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (job.farmName != null)
                            Text(
                              job.farmName!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(bool isFarmerJob) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFarmerJob ? Colors.green.shade100 : Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFarmerJob ? Icons.work : Icons.person_search,
            size: 12,
            color: isFarmerJob ? Colors.green.shade700 : Colors.blue.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isFarmerJob ? 'HIRING' : 'SEEKING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isFarmerJob ? Colors.green.shade700 : Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(JobStatus status) {
    Color color;
    String label;
    switch (status) {
      case JobStatus.approved:
        color = Colors.green;
        label = 'ACTIVE';
        break;
      case JobStatus.pending:
        color = Colors.orange;
        label = 'PENDING';
        break;
      case JobStatus.rejected:
        color = Colors.red;
        label = 'REJECTED';
        break;
      case JobStatus.expired:
        color = Colors.grey;
        label = 'EXPIRED';
        break;
      case JobStatus.filled:
        color = Colors.blue;
        label = 'FILLED';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(JobCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.name[0].toUpperCase() + category.name.substring(1),
        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
      ),
    );
  }
}
