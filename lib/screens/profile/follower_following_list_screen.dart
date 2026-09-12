import 'package:flutter/material.dart';
import 'profile_controller.dart';
import 'farmer_model.dart';
import 'farmer_profile_screen.dart';
import 'package:agribased/app/utils/formatters.dart';
import 'package:agribased/widgets/following_list_follow_button.dart';
import 'package:agribased/widgets/user_info_display.dart';

class FollowersFollowingListScreen extends StatefulWidget {
  final String userId; // Profile being viewed
  final String currentUserId; // Logged-in user
  final bool showFollowers; // true = followers, false = following

  const FollowersFollowingListScreen({
    super.key,
    required this.userId,
    required this.currentUserId,
    required this.showFollowers,
  });

  @override
  State<FollowersFollowingListScreen> createState() =>
      _FollowersFollowingListScreenState();
}

class _FollowersFollowingListScreenState
    extends State<FollowersFollowingListScreen> {
  List<String> _ids = [];

  /// Helper method to format location data properly
  String _formatLocation(dynamic location) {
    return Formatter.formatLocation(location);
  }


  @override
  void initState() {
    super.initState();
    _loadIds();
  }

  Future<void> _loadIds() async {
    final profile = await ProfileController().getFarmerById(widget.userId);
    if (profile == null) return;
    setState(() {
      _ids = (widget.showFollowers ? profile.followers : profile.following)
          .where((id) => id != null && id.trim().isNotEmpty)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.showFollowers ? "Followers" : "Following";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.green[700],
        centerTitle: true,
      ),
      body: _ids.isEmpty
          ? Center(
              child: Text(
                widget.showFollowers
                    ? "No followers yet."
                    : "Not following anyone yet.",
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : StreamBuilder<List<FarmerModel>>(
              stream: ProfileController().getFarmersByIdsStream(_ids),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      widget.showFollowers
                          ? "No followers yet."
                          : "Not following anyone yet.",
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                final farmers = snapshot.data!;
                return ListView.builder(
                  itemCount: farmers.length,
                  itemBuilder: (context, index) {
                    final farmer = farmers[index];
                    final isMe = farmer.id == widget.currentUserId;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      leading: UserProfileImage(
                        userId: farmer.id,
                        radius: 25,
                        initialImageUrl: (farmer.profilePic != null &&
                                farmer.profilePic!.isNotEmpty)
                            ? farmer.profilePic!
                            : '',
                      ),
                      title: Text(
                        farmer.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: _formatLocation(farmer.location).isNotEmpty
                          ? Text(_formatLocation(farmer.location))
                          : null,
                      trailing: isMe
                          ? const SizedBox()
                          : FollowingListFollowButton(
                              currentUserId: widget.currentUserId,
                              targetUserId: farmer.id,
                            ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FarmerProfileScreen(
                              userId: farmer.id,
                              currentUserId: widget.currentUserId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
