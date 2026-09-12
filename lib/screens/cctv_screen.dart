import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/screens/profile/farmer_model.dart';
import 'package:agribased/screens/cctv/cctv_players.dart';

class CCTVScreen extends StatefulWidget {
  final FarmerModel farmer;

  const CCTVScreen({super.key, required this.farmer});

  @override
  State<CCTVScreen> createState() => _CCTVScreenState();
}

class _CCTVScreenState extends State<CCTVScreen> {
  final Set<int> _deleteVisible = {};

  Future<void> removeCameraFromFarmer(String farmerId, dynamic camera) async {
    try {
      // Convert camera to map safely
      final cameraMap = camera is CameraEntry
          ? camera.toMap()
          : (camera as dynamic).toMap();

      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(farmerId)
          .update({
            'cameras': FieldValue.arrayRemove([cameraMap]),
          });
    } catch (e) {
      // Re-throw the error to be caught by the caller
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("Field CCTV", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ✅ REAL-TIME LISTENING TO FIRESTORE
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('farmers')
            .doc(widget.farmer.id)
            .snapshots(includeMetadataChanges: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final updatedFarmer = FarmerModel.fromMap(data, widget.farmer.id);

          if (updatedFarmer.cameras.isEmpty) {
            return const Center(
              child: Text(
                "No CCTV cameras registered for this farmer",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: updatedFarmer.cameras.length <= 2
                    ? 1
                    : updatedFarmer.cameras.length <= 4
                    ? 2
                    : 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: updatedFarmer.cameras.length,
              itemBuilder: (context, index) {
                final camera = updatedFarmer.cameras[index];
                final deleteVisible = _deleteVisible.contains(index);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Camera name + delete button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onDoubleTap: () {
                            setState(() {
                              if (deleteVisible) {
                                _deleteVisible.remove(index);
                              } else {
                                _deleteVisible.add(index);
                              }
                            });
                          },
                          child: Text(
                            camera.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (deleteVisible)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              final scaffoldContext = context;
                              final messenger = ScaffoldMessenger.of(
                                scaffoldContext,
                              );

                              removeCameraFromFarmer(widget.farmer.id, camera)
                                  .then((_) {
                                    if (!mounted) return;

                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Camera deleted successfully",
                                        ),
                                      ),
                                    );
                                  })
                                  .catchError((e) {
                                    if (!mounted) return;

                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Error deleting camera: $e",
                                        ),
                                      ),
                                    );
                                  });
                            },
                          ),
                      ],
                    ),

                    // CCTV Preview (HLS-only)
                    Expanded(
                      child: CCTVPreviewPlayer(hlsUrl: camera.streamUrl),
                    ),

                    // View recordings button
                    ElevatedButton(
                      child: const Text("View Previous Recordings"),
                      onPressed: () {
                        _showRecordingsDialog(context, updatedFarmer);
                      },
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showRecordingsDialog(BuildContext context, FarmerModel farmer) {
    final messenger = ScaffoldMessenger.of(context);

    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime.now(),
    ).then((picked) {
      if (picked == null || !context.mounted) return;

      try {
        final recording = farmer.recordings.firstWhere(
          (r) =>
              r.date.year == picked.year &&
              r.date.month == picked.month &&
              r.date.day == picked.day,
          orElse: () => RecordingEntry(
            date: picked,
            url: "",
            id: 'temp-${picked.millisecondsSinceEpoch}',
            duration: Duration.zero,
            fileSize: 0,
          ),
        );

        if (!context.mounted) return;

        if (recording.url.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecordingPlayer(url: recording.url),
            ),
          );
        } else {
          if (context.mounted) {
            messenger.showSnackBar(
              const SnackBar(content: Text("No recording found for that date")),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text("Error accessing recordings: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }
}
