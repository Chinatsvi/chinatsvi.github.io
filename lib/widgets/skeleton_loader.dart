import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({super.key, this.width, this.height, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      period: const Duration(milliseconds: 1100),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            Row(
              children: [
                SkeletonLoader(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(width: double.infinity, height: 16),
                      const SizedBox(height: 4),
                      SkeletonLoader(width: 100, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content skeleton
            SkeletonLoader(width: double.infinity, height: 14),
            const SizedBox(height: 4),
            SkeletonLoader(width: double.infinity, height: 14),
            const SizedBox(height: 4),
            SkeletonLoader(width: 200, height: 14),
            const SizedBox(height: 12),
            // Image skeleton
            SkeletonLoader(width: double.infinity, height: 200),
            const SizedBox(height: 12),
            // Stats skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SkeletonLoader(width: 24, height: 24),
                SkeletonLoader(width: 24, height: 24),
                SkeletonLoader(width: 24, height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FeedSkeleton extends StatelessWidget {
  final int itemCount;

  const FeedSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => const PostSkeleton(),
    );
  }
}
