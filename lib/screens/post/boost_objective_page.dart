import 'package:flutter/material.dart';

import '../../models/post_model.dart';
import 'boost_post_page.dart';

class BoostObjective {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const BoostObjective({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const List<BoostObjective> kBoostObjectives = [
  BoostObjective(
    id: 'reach',
    title: 'More Reach',
    description: 'Show your post to more people in their feed',
    icon: Icons.visibility,
    color: Colors.blue,
  ),
  BoostObjective(
    id: 'engagement',
    title: 'More Engagement',
    description: 'Get more likes, comments and shares',
    icon: Icons.favorite,
    color: Colors.pink,
  ),
  BoostObjective(
    id: 'followers',
    title: 'More Followers',
    description: 'Attract new followers to your profile',
    icon: Icons.person_add,
    color: Colors.green,
  ),
  BoostObjective(
    id: 'profile_visits',
    title: 'More Profile Visits',
    description: 'Drive more traffic to your profile page',
    icon: Icons.storefront,
    color: Colors.orange,
  ),
];

class BoostObjectivePage extends StatelessWidget {
  final Post post;

  const BoostObjectivePage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boost Post'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'What do you want to boost?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Choose a goal and we'll optimize your boost for it.",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ...kBoostObjectives.map(
            (objective) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ObjectiveCard(
                objective: objective,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BoostPostPage(post: post, objective: objective),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectiveCard extends StatelessWidget {
  final BoostObjective objective;
  final VoidCallback onTap;

  const _ObjectiveCard({required this.objective, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: objective.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(objective.icon, color: objective.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      objective.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      objective.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
