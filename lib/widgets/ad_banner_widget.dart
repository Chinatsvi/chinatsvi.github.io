import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBannerWidget extends StatefulWidget {
  final BannerAd? ad;

  const AdBannerWidget({super.key, this.ad});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  @override
  Widget build(BuildContext context) {
    final adHeight = widget.ad?.size.height.toDouble() ?? 50;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 3),
            child: Text(
              'Sponsored',
              style: TextStyle(
                color: Colors.black45,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            height: adHeight,
            child: widget.ad == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FractionallySizedBox(
                          widthFactor: 0.7,
                          alignment: Alignment.centerLeft,
                          child: _skeletonLine(height: 8),
                        ),
                        const SizedBox(height: 7),
                        FractionallySizedBox(
                          widthFactor: 0.45,
                          alignment: Alignment.centerLeft,
                          child: _skeletonLine(height: 6),
                        ),
                      ],
                    ),
                  )
                : AdWidget(ad: widget.ad!),
          ),
        ],
      ),
    );
  }

  Widget _skeletonLine({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
