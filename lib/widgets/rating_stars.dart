import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor =
        color ??
        (theme.brightness == Brightness.dark
            ? Colors.amber.shade300
            : Colors.amber.shade700);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starRating = index + 1.0;
        return Icon(
          starRating <= rating
              ? Icons.star
              : (starRating - rating < 1.0
                    ? Icons.star_half
                    : Icons.star_border),
          color: activeColor,
          size: size,
        );
      }),
    );
  }
}
