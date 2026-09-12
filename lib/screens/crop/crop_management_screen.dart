import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agribased/models/crop/crop_plan.dart';
import 'package:agribased/services/crop/crop_management_service.dart';
import 'tabs/crop_plan_tab.dart';
import 'tabs/budget_planner_tab.dart';
import 'tabs/inventory_tab.dart';
import 'tabs/season_calendar_tab.dart';
import 'tabs/production_tab.dart';
import 'tabs/profit_loss_tab.dart';
import 'crop_plan_form.dart';

class CropManagementScreen extends StatelessWidget {
  const CropManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to access Crop Management')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Management'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<CropPlan>>(
        stream: CropManagementService().getCropPlans(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading crop plans: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final cropPlans = snapshot.data ?? [];

          if (cropPlans.isEmpty) {
            return _buildNoCropPlanView(context, user.uid);
          }

          return _CropPlanListView(cropPlans: cropPlans, farmerId: user.uid);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCropPlanDialog(context, user.uid),
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNoCropPlanView(BuildContext context, String farmerId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.spa, size: 80, color: Colors.green.shade200),
            const SizedBox(height: 24),
            Text(
              'No Crop Plans Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start by registering your crop plan. Define what you want to grow, when, and where.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddCropPlanDialog(context, farmerId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Create Crop Plan',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCropPlanDialog(BuildContext context, String farmerId) {
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
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return CropPlanForm(
              farmerId: farmerId,
              scrollController: scrollController,
            );
          },
        ),
      ),
    );
  }
}

class _CropPlanListView extends StatelessWidget {
  final List<CropPlan> cropPlans;
  final String farmerId;

  const _CropPlanListView({required this.cropPlans, required this.farmerId});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cropPlans.length,
      itemBuilder: (context, index) {
        final plan = cropPlans[index];
        return _CropPlanCard(
          plan: plan,
          onTap: () => _openCropPlanDetails(context, plan),
          onLongPress: (cardContext) => _showDeleteMenu(cardContext, plan),
        );
      },
    );
  }

  void _openCropPlanDetails(BuildContext context, CropPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CropPlanDetailScreen(plan: plan)),
    );
  }

  void _showDeleteMenu(BuildContext context, CropPlan plan) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red.shade700),
                title: Text(
                  'Delete Crop Plan',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                subtitle: Text('${plan.cropName} - ${plan.fieldName}'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, plan);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, CropPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Crop Plan'),
        content: Text(
          'Are you sure you want to delete "${plan.cropName}"?\n\nThis will also delete all associated budgets, activities, and production records. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _deleteCropPlan(context, plan);
            },
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCropPlan(BuildContext context, CropPlan plan) async {
    try {
      final service = CropManagementService();
      await service.deleteCropPlan(plan.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crop plan deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting crop plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _CropPlanCard extends StatelessWidget {
  final CropPlan plan;
  final VoidCallback onTap;
  final Function(BuildContext) onLongPress;

  const _CropPlanCard({
    required this.plan,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntilPlanting = plan.plantingDate
        .difference(DateTime.now())
        .inDays;
    final isUpcoming = daysUntilPlanting > 0;
    final isActive =
        daysUntilPlanting <= 0 &&
        (plan.expectedHarvestDate == null ||
            plan.expectedHarvestDate!.isAfter(DateTime.now()));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => onLongPress(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.shade100
                          : isUpcoming
                          ? Colors.orange.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.spa,
                      color: isActive
                          ? Colors.green.shade700
                          : isUpcoming
                          ? Colors.orange.shade700
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.cropName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (plan.variety != null)
                          Text(
                            plan.variety!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green
                          : isUpcoming
                          ? Colors.orange
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive
                          ? 'Active'
                          : isUpcoming
                          ? 'Upcoming'
                          : 'Completed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.location_on,
                      'Field',
                      plan.fieldName,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today,
                      'Planting',
                      _formatDate(plan.plantingDate),
                    ),
                  ),
                ],
              ),
              if (plan.fieldSize != null) ...[
                const SizedBox(height: 12),
                _buildInfoItem(
                  Icons.straighten,
                  'Field Size',
                  '${plan.fieldSize} ${plan.fieldSizeUnit ?? 'units'}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class CropPlanDetailScreen extends StatelessWidget {
  final CropPlan plan;

  const CropPlanDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const Tab(icon: Icon(Icons.spa), text: 'Crop Plan'),
      const Tab(icon: Icon(Icons.account_balance_wallet), text: 'Budget'),
      const Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
      const Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
      const Tab(icon: Icon(Icons.shopping_cart), text: 'Production'),
      const Tab(icon: Icon(Icons.trending_up), text: 'P&L'),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(plan.cropName),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          bottom: TabBar(
            isScrollable: true,
            tabs: tabs,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            CropPlanTab(plan: plan),
            BudgetPlannerTab(plan: plan),
            InventoryTab(plan: plan),
            SeasonCalendarTab(plan: plan),
            ProductionTab(plan: plan),
            ProfitLossTab(plan: plan),
          ],
        ),
      ),
    );
  }
}
