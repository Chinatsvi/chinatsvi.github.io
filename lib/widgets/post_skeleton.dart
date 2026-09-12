import 'package:flutter/material.dart';

class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 120,
                height: 12,
                color: Colors.grey.shade300,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 12,
            width: double.infinity,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 6),
          Container(
            height: 12,
            width: MediaQuery.of(context).size.width * .6,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
