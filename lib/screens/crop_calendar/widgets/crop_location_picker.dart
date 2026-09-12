import 'package:flutter/material.dart';
import '../../../models/crop_calendar/crop_calendar_models.dart';
import '../../../services/crop_calendar/crop_calendar_service.dart';

class CropLocationPicker extends StatefulWidget {
  final LocationAgroProfile selectedLocation;
  final ValueChanged<LocationAgroProfile> onLocationChanged;

  const CropLocationPicker({
    super.key,
    required this.selectedLocation,
    required this.onLocationChanged,
  });

  @override
  State<CropLocationPicker> createState() => _CropLocationPickerState();
}

class _CropLocationPickerState extends State<CropLocationPicker> {
  final CropCalendarService _service = CropCalendarService();
  bool _isDetecting = false;
  late List<LocationAgroProfile> _allLocations;

  @override
  void initState() {
    super.initState();
    _allLocations = _service.getAvailableLocations();
  }

  Future<void> _detectGPS() async {
    setState(() => _isDetecting = true);
    try {
      final detected = await _service.detectCurrentLocation();
      if (detected != null && mounted) {
        widget.onLocationChanged(detected);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Location detected: ${detected.displayName}'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access GPS. Please select manually below.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  void _showSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _allLocations.where((loc) {
              final q = query.toLowerCase();
              return loc.country.toLowerCase().contains(q) ||
                  loc.region.toLowerCase().contains(q) ||
                  loc.district.toLowerCase().contains(q) ||
                  loc.climateZone.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Search Farming Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'e.g. Masvingo, Limpopo, Nairobi, Kano...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() => query = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No matching location found',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final loc = filtered[index];
                              final isSelected =
                                  loc.displayName == widget.selectedLocation.displayName;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? Colors.green.shade700
                                      : Colors.green.shade50,
                                  child: Icon(
                                    Icons.location_on,
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.green.shade700,
                                  ),
                                ),
                                title: Text(
                                  loc.displayName,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.green.shade800
                                        : Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  '${loc.climateZone} • ${loc.elevationMeters != null ? "${loc.elevationMeters}m" : ""}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                trailing: isSelected
                                    ? Icon(
                                        Icons.check_circle,
                                        color: Colors.green.shade700,
                                      )
                                    : null,
                                onTap: () {
                                  widget.onLocationChanged(loc);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.selectedLocation;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.green.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Where are you farming?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        loc.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Climate info banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.public,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${loc.climateZone} • ${loc.isSouthernHemisphere ? "Southern" : "Northern"} Hemisphere',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Actions row: GPS detect & Manual Search
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDetecting ? null : _detectGPS,
                    icon: _isDetecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 16),
                    label: Text(
                      _isDetecting ? 'Detecting...' : 'Current Location',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade800,
                      side: BorderSide(color: Colors.green.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showSearchModal,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text(
                      'Select Location',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
