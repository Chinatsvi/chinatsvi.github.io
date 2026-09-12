import 'package:flutter/material.dart';
import 'package:agribased/services/marketplace/rating_service.dart';
import 'package:agribased/models/marketplace/seller_rating.dart';

class RatingsPage extends StatefulWidget {
  final RatingService ratingService;
  final String sellerId;

  const RatingsPage({
    super.key,
    required this.ratingService,
    required this.sellerId,
  });

  @override
  State<RatingsPage> createState() => _RatingsPageState();
}

class _RatingsPageState extends State<RatingsPage> {
  List<SellerRating> ratings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    setState(() => loading = true);
    try {
      ratings = await widget.ratingService.getRatingsForSeller(widget.sellerId);
    } catch (e) {
      ratings = [];
    } finally {
      setState(() => loading = false);
    }
  }

  Widget _ratingTile(SellerRating r) {
    return ListTile(
      leading: CircleAvatar(child: Text(r.stars.toString())),
      title: Text(r.comment.isNotEmpty ? r.comment : 'No comment'),
      subtitle: Text('By ${r.buyerId} • ${r.createdAt.toLocal()}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ratings'),
        backgroundColor: Colors.green[700],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ratings.isEmpty
          ? const Center(child: Text('No ratings yet.'))
          : ListView.builder(
              itemCount: ratings.length,
              itemBuilder: (_, i) => _ratingTile(ratings[i]),
            ),
    );
  }
}
