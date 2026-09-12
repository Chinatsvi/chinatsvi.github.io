import 'package:flutter/material.dart';
import 'package:agribased/widgets/safe_network_image.dart';

class ProductImageSlider extends StatelessWidget {
  final List<String> images;

  const ProductImageSlider({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (_, index) {
          return SafeNetworkImage(
            imageUrl: images[index],
            fit: BoxFit.cover,
            errorWidget: Container(color: Colors.grey.shade300),
          );
        },
      ),
    );
  }
}
