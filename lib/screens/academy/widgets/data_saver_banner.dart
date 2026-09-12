import 'package:flutter/material.dart';
import '../../../services/academy/academy_progress_service.dart';

class DataSaverBanner extends StatefulWidget {
  final VoidCallback? onToggle;
  const DataSaverBanner({super.key, this.onToggle});

  @override
  State<DataSaverBanner> createState() => _DataSaverBannerState();
}

class _DataSaverBannerState extends State<DataSaverBanner> {
  bool _isDataSaver = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final state = await AcademyProgressService.instance.isDataSaverEnabled();
    if (mounted) setState(() => _isDataSaver = state);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _isDataSaver ? Colors.amber.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDataSaver ? Colors.amber.shade400 : Colors.green.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isDataSaver ? Icons.signal_cellular_alt_outlined : Icons.offline_bolt_outlined,
            color: _isDataSaver ? Colors.amber.shade800 : Colors.green.shade800,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isDataSaver ? '📶 Data Saver: Active' : '📶 Offline & Data Saver',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _isDataSaver ? Colors.amber.shade900 : Colors.green.shade900,
                  ),
                ),
                Text(
                  _isDataSaver
                      ? 'Videos load only on tap to save mobile bundles'
                      : 'Save data bundles while learning',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isDataSaver ? Colors.amber.shade800 : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isDataSaver,
            activeColor: Colors.amber.shade800,
            onChanged: (val) async {
              await AcademyProgressService.instance.setDataSaverEnabled(val);
              setState(() => _isDataSaver = val);
              widget.onToggle?.call();
            },
          ),
        ],
      ),
    );
  }
}
