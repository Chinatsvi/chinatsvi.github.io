import 'package:flutter/material.dart';
import 'package:agribased/models/job_model.dart';

class ApiJobCard extends StatelessWidget {
  final JobPost job;
  final VoidCallback onTap;

  const ApiJobCard({
    super.key,
    required this.job,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              // External source badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.public, size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          job.apiSource ?? 'External',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip(job.category),
                ],
              ),
              const SizedBox(height: 12),

              // Job title
              Text(
                job.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Company name
              if (job.farmName != null) ...[
                Text(
                  job.farmName!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Location
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.location,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description preview
              if (job.description.isNotEmpty) ...[
                Text(
                  job.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Salary if available
              if (job.salary != null) ...[
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '\$${job.salary!.toStringAsFixed(0)} ${job.salaryPeriod ?? 'per month'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // View external link indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View on external site',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new, size: 14, color: Colors.orange.shade700),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(JobCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _getCategoryDisplay(category),
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  String _getCategoryDisplay(JobCategory category) {
    switch (category) {
      case JobCategory.generalLabor:
        return 'General Labor';
      case JobCategory.harvesting:
        return 'Harvesting';
      case JobCategory.planting:
        return 'Planting';
      case JobCategory.irrigation:
        return 'Irrigation';
      case JobCategory.livestock:
        return 'Livestock';
      case JobCategory.machinery:
        return 'Machinery';
      case JobCategory.technical:
        return 'Technical';
      case JobCategory.management:
        return 'Management';
      case JobCategory.sales:
        return 'Sales';
      case JobCategory.other:
        return 'Other';
    }
  }
}
