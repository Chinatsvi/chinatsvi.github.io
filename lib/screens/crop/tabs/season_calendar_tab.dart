import 'package:flutter/material.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/models/crop/crop_plan.dart';
import 'package:agribased/models/crop/season_activity.dart';
import 'package:agribased/services/crop/crop_management_service.dart';
import 'package:agribased/screens/farm_works/irrigation_calculator.dart';

class SeasonCalendarTab extends StatelessWidget {
  final CropPlan plan;
  final CropManagementService _service = CropManagementService();

  SeasonCalendarTab({super.key, required this.plan});

  String get _currency => plan.currency ?? r'$';
  String _formatMoney(double amount) =>
      '$_currency${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SeasonActivity>>(
      stream: _service.getActivitiesForCropPlan(plan.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = snapshot.data ?? [];

        return Scaffold(
          bottomNavigationBar: const FarmBannerAd(),
          body: activities.isEmpty
              ? _buildEmptyView(context)
              : _buildCalendarView(context, activities),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddActivityDialog(context),
            backgroundColor: Colors.green.shade700,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildIrrigationIntelligenceBanner(
    BuildContext context,
    List<SeasonActivity> activities,
  ) {
    // Find completed or logged irrigation activities
    final irrigationActivities = activities
        .where((a) => a.activityType == 'irrigation')
        .toList()
      ..sort((a, b) => b.plannedDate.compareTo(a.plannedDate));

    final SeasonActivity? lastIrrigation = irrigationActivities.isNotEmpty
        ? irrigationActivities.first
        : null;

    final now = DateTime.now();
    int? daysSinceLastIrrigation;
    if (lastIrrigation != null) {
      daysSinceLastIrrigation = now.difference(lastIrrigation.plannedDate).inDays;
    }

    // Determine urgency & advice
    Color bannerBg = Colors.blue.shade50;
    Color borderCol = Colors.blue.shade200;
    Color textCol = Colors.blue.shade900;
    IconData icon = Icons.water_drop;
    String statusTitle;
    String statusSubtitle;

    if (lastIrrigation == null) {
      statusTitle = 'No Irrigation Logged Yet';
      statusSubtitle =
          'Keep track of watering for ${plan.cropName} to maintain root moisture and get accurate advice.';
    } else if (daysSinceLastIrrigation != null && daysSinceLastIrrigation >= 4) {
      bannerBg = Colors.amber.shade50;
      borderCol = Colors.amber.shade300;
      textCol = Colors.amber.shade900;
      icon = Icons.warning_amber_rounded;
      statusTitle = 'Last Irrigated $daysSinceLastIrrigation Days Ago';
      statusSubtitle =
          'Field soil may be depleting root zone moisture. Check crop stage and calculate water requirements.';
    } else {
      statusTitle = daysSinceLastIrrigation == 0
          ? 'Irrigated Today'
          : 'Last Irrigated $daysSinceLastIrrigation ${daysSinceLastIrrigation == 1 ? "day" : "days"} ago';
      statusSubtitle =
          'Regular watering logged. Tap below to estimate the next cycle based on live weather and crop stage.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textCol, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            statusSubtitle,
            style: TextStyle(
              fontSize: 12,
              color: textCol.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IrrigationCalculator(
                          initialCropName: plan.cropName,
                          initialArea: plan.fieldSize,
                          initialAreaUnit: plan.fieldSizeUnit,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calculate, size: 16),
                  label: const Text(
                    'Calculate Water Need',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showAddActivityDialog(context, initialType: 'irrigation'),
                icon: const Icon(Icons.add_task, size: 16),
                label: const Text('Log Irrigation', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade800,
                  side: BorderSide(color: Colors.blue.shade300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildIrrigationIntelligenceBanner(context, []),
          const SizedBox(height: 16),
          Icon(Icons.calendar_month, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Season Activities',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add land preparation, planting, weeding, fertilizing, harvesting and other activities.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          const FarmNativeAd(),
        ],
      ),
    );
  }

  Widget _buildCalendarView(
    BuildContext context,
    List<SeasonActivity> activities,
  ) {
    // Sort by date
    activities.sort((a, b) => a.plannedDate.compareTo(b.plannedDate));

    // Group by month
    final Map<String, List<SeasonActivity>> grouped = {};
    for (final activity in activities) {
      final key = '${activity.plannedDate.month}/${activity.plannedDate.year}';
      grouped.putIfAbsent(key, () => []).add(activity);
    }

    final monthKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: monthKeys.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildIrrigationIntelligenceBanner(context, activities);
        }
        if (index == monthKeys.length + 1) {
          return const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 60),
            child: FarmNativeAd(),
          );
        }
        final monthKey = monthKeys[index - 1];
        final monthActivities = grouped[monthKey]!;
        return _buildMonthSection(monthKey, monthActivities);
      },
    );
  }

  Widget _buildMonthSection(String monthKey, List<SeasonActivity> activities) {
    final parts = monthKey.split('/');
    final monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthName = monthNames[int.parse(parts[0])];
    final year = parts[1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$monthName $year',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...activities.map((activity) => _buildActivityCard(activity)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildActivityCard(SeasonActivity activity) {
    final isCompleted = activity.isCompleted;
    final isOverdue =
        !isCompleted && activity.plannedDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isCompleted
          ? Colors.green.shade50
          : isOverdue
          ? Colors.red.shade50
          : null,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getActivityColor(activity.activityType).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getActivityIcon(activity.activityType),
            color: _getActivityColor(activity.activityType),
          ),
        ),
        title: Text(
          activity.activityTypeDisplay,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(activity.plannedDate),
                  style: TextStyle(
                    color: isOverdue ? Colors.red : Colors.grey.shade600,
                    fontWeight: isOverdue ? FontWeight.bold : null,
                  ),
                ),
                if (activity.cost != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.attach_money,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(_formatMoney(activity.cost!)),
                ],
              ],
            ),
          ],
        ),
        trailing: isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : isOverdue
            ? const Icon(Icons.warning, color: Colors.orange)
            : const Icon(Icons.chevron_right),
        isThreeLine: true,
        onTap: () {}, // TODO: Show activity details
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'land_preparation':
        return Colors.brown;
      case 'planting':
        return Colors.green;
      case 'weeding':
        return Colors.orange;
      case 'fertilizing':
        return Colors.blue;
      case 'pest_control':
        return Colors.red;
      case 'irrigation':
        return Colors.cyan;
      case 'harvesting':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'land_preparation':
        return Icons.agriculture;
      case 'planting':
        return Icons.spa;
      case 'weeding':
        return Icons.grass;
      case 'fertilizing':
        return Icons.local_florist;
      case 'pest_control':
        return Icons.bug_report;
      case 'irrigation':
        return Icons.water;
      case 'harvesting':
        return Icons.shopping_basket;
      default:
        return Icons.event;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddActivityDialog(BuildContext context, {String? initialType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddActivityDialog(
          plan: plan,
          initialType: initialType,
          onActivityAdded: () {},
        ),
      ),
    );
  }
}

class AddActivityDialog extends StatefulWidget {
  final CropPlan plan;
  final String? initialType;
  final VoidCallback onActivityAdded;

  const AddActivityDialog({
    super.key,
    required this.plan,
    this.initialType,
    required this.onActivityAdded,
  });

  @override
  State<AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<AddActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _laborHoursController = TextEditingController();
  final _notesController = TextEditingController();
  late String _activityType;
  DateTime _plannedDate = DateTime.now();
  String _status = 'planned';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _activityType = widget.initialType ?? 'other';
    if (_activityType == 'irrigation') {
      _descriptionController.text = 'Scheduled field irrigation';
    }
  }

  final _service = CropManagementService();

  final List<Map<String, dynamic>> _activityTypes = [
    {'value': 'land_preparation', 'label': 'Land Preparation', 'icon': Icons.agriculture},
    {'value': 'planting', 'label': 'Planting', 'icon': Icons.spa},
    {'value': 'weeding', 'label': 'Weeding', 'icon': Icons.grass},
    {'value': 'fertilizing', 'label': 'Fertilizing', 'icon': Icons.local_florist},
    {'value': 'pest_control', 'label': 'Pest Control', 'icon': Icons.bug_report},
    {'value': 'irrigation', 'label': 'Irrigation', 'icon': Icons.water},
    {'value': 'harvesting', 'label': 'Harvesting', 'icon': Icons.shopping_basket},
    {'value': 'other', 'label': 'Other Activity', 'icon': Icons.event},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
    _laborHoursController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plannedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _plannedDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cost = double.tryParse(_costController.text);
      final laborHours = double.tryParse(_laborHoursController.text);

      final activity = SeasonActivity(
        id: '',
        farmerId: widget.plan.farmerId,
        cropPlanId: widget.plan.id,
        activityType: _activityType,
        description: _descriptionController.text.trim(),
        plannedDate: _plannedDate,
        status: _status,
        cost: cost,
        laborHours: laborHours,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: DateTime.now(),
      );

      await _service.createActivity(activity);
      widget.onActivityAdded();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
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
              Row(
                children: [
                  Icon(Icons.calendar_month, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Add Season Activity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Text(
                        'Activity Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _activityTypes.map((type) {
                          final isSelected = _activityType == type['value'];
                          return ChoiceChip(
                            avatar: Icon(type['icon'] as IconData, size: 18),
                            label: Text(type['label'] as String),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _activityType = type['value'] as String);
                              }
                            },
                            selectedColor: Colors.green.shade100,
                            checkmarkColor: Colors.green.shade700,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          prefixIcon: Icon(Icons.description),
                          hintText: 'e.g., Apply basal fertilizer, Remove weeds',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter activity description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.calendar_today, color: Colors.green.shade700),
                        title: const Text('Planned Date *'),
                        subtitle: Text('${_plannedDate.day}/${_plannedDate.month}/${_plannedDate.year}'),
                        trailing: TextButton(
                          onPressed: _selectDate,
                          child: const Text('Change'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.flag),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'planned', child: Text('Planned')),
                          DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                          DropdownMenuItem(value: 'completed', child: Text('Completed')),
                          DropdownMenuItem(value: 'delayed', child: Text('Delayed')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _status = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _costController,
                              decoration: const InputDecoration(
                                labelText: 'Cost (Optional)',
                                prefixIcon: Icon(Icons.payments_outlined),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _laborHoursController,
                              decoration: const InputDecoration(
                                labelText: 'Labor Hours (Optional)',
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Save Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

