import 'dart:async';

import 'package:flutter/material.dart';
import 'package:agribased/app/utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agribased/providers/livestock_provider.dart';
import 'package:agribased/providers/enhanced_animal_provider.dart';
import 'package:agribased/providers/enhanced_poultry_provider.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/animal/health_record.dart';
import 'package:agribased/models/animal/feeding_entry.dart';
import 'package:agribased/models/animal/growth_record.dart';
import 'package:agribased/models/animal/vet_visit.dart';
import 'package:agribased/models/poultry/poultry_batch.dart';
import 'package:agribased/models/poultry/poultry_health_record.dart';
import 'package:agribased/models/poultry/poultry_feeding_record.dart';
import 'package:agribased/models/poultry/poultry_growth_record.dart';
import 'package:agribased/models/poultry/poultry_vet_record.dart';

// Enhanced Animal Management Screen with State Management
class EnhancedAnimalManagementScreen extends ConsumerStatefulWidget {
  const EnhancedAnimalManagementScreen({super.key});

  @override
  ConsumerState<EnhancedAnimalManagementScreen> createState() =>
      _EnhancedAnimalManagementScreenState();
}

class _EnhancedAnimalManagementScreenState
    extends ConsumerState<EnhancedAnimalManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final animalsAsync = ref.watch(animalsProvider);
    final poultryBatchesAsync = ref.watch(poultryBatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Animal Management'),
        backgroundColor: Colors.green,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(animalsProvider);
              ref.invalidate(poultryBatchesProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics cards
          _buildStatisticsRow(animalsAsync, poultryBatchesAsync),
          const SizedBox(height: 16),

          // Animals list
          Expanded(
            child: animalsAsync.when(
              data: (animals) {
                if (animals.isEmpty) {
                  return const Center(
                    child: Text(
                      'No animals registered yet. Tap + to add your first animal!',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: animals.length,
                  itemBuilder: (context, index) {
                    final animal = animals[index];
                    return _AnimalCard(
                      animal: animal,
                      onTap: () => _openAnimalDetails(animal),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text('Error loading animals: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(animalsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: _openRegisterMenu,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatisticsRow(
    AsyncValue<List<Animal>> animalsAsync,
    AsyncValue<List<PoultryBatch>> poultryBatchesAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Total Animals',
              value: animalsAsync.when(
                data: (animals) => animals.length.toString(),
                loading: () => '...',
                error: (_, __) => '0',
              ),
              icon: Icons.pets,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCard(
              title: 'Poultry Batches',
              value: poultryBatchesAsync.when(
                data: (batches) => batches.length.toString(),
                loading: () => '...',
                error: (_, __) => '0',
              ),
              icon: Icons.egg,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  void _openAnimalDetails(Animal animal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _AnimalDetailsScreen(animalId: animal.id),
      ),
    );
  }

  void _openRegisterMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.egg, color: Colors.green),
            title: const Text('Register Poultry'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to poultry registration
              _showComingSoon('Poultry Registration');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.pets, color: Colors.green),
            title: const Text('Register Other Animal'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to animal registration
              _showComingSoon('Animal Registration');
            },
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature - Coming Soon!')));
  }
}

class _AnimalCard extends StatelessWidget {
  final Animal animal;
  final VoidCallback onTap;

  const _AnimalCard({required this.animal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: animal.photoUrl != null
              ? NetworkImage(animal.photoUrl!)
              : null,
          child: animal.photoUrl == null
              ? Image.asset('assets/icon/huku.png', width: 28)
              : null,
        ),
        title: Text('${animal.species} • ${animal.breed}'),
        subtitle: Text(
          'Age: ${animal.ageDisplayLabel} | Sex: ${animal.sex ?? 'N/A'}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// Animal Details Screen with Reactive Tabs
class _AnimalDetailsScreen extends ConsumerStatefulWidget {
  final String animalId;

  const _AnimalDetailsScreen({required this.animalId});

  @override
  ConsumerState<_AnimalDetailsScreen> createState() =>
      _AnimalDetailsScreenState();
}

class _AnimalDetailsScreenState extends ConsumerState<_AnimalDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _ageRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _ageRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ageRefreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final livestockDataAsync = ref.watch(
      livestockDataProvider(widget.animalId),
    );

    return Scaffold(
      body: livestockDataAsync.when(
        data: (livestockData) {
          final animal = livestockData.animal!;
          final isPoultry = livestockData.isPoultry;
          final isLayer = livestockData.isLayer;

          // Update tabs based on animal type
          final tabs = _getTabsForAnimal(isPoultry, isLayer);

          return DefaultTabController(
            length: tabs.length,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.green,
                title: Text('${animal.species} • ${animal.breed}'),
                bottom: TabBar(tabs: tabs, isScrollable: true),
              ),
              body: TabBarView(children: _getTabViewsForAnimal(livestockData)),
            ),
          );
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stack) => Scaffold(
          appBar: AppBar(
            title: const Text('Animal Details'),
            backgroundColor: Colors.green,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error loading animal data: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(livestockDataProvider(widget.animalId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Tab> _getTabsForAnimal(bool isPoultry, bool isLayer) {
    final tabs = <Tab>[
      const Tab(text: 'Profile'),
      const Tab(text: 'Health'),
      const Tab(text: 'Feeding'),
      const Tab(text: 'Growth'),
      const Tab(text: 'Vet'),
      const Tab(text: 'Reports'),
    ];

    if (isPoultry) {
      tabs.insert(4, const Tab(text: 'Mortality'));
      tabs.insert(6, const Tab(text: 'Ration Plan'));
      if (isLayer) {
        tabs.insert(7, const Tab(text: 'Egg %'));
      }
    } else {
      tabs.insert(5, const Tab(text: 'Breeding'));
      tabs.insert(6, const Tab(text: 'Exit'));
    }

    return tabs;
  }

  List<Widget> _getTabViewsForAnimal(LivestockData livestockData) {
    final views = <Widget>[
      _ProfileTab(livestockData: livestockData),
      _HealthTab(livestockData: livestockData),
      _FeedingTab(livestockData: livestockData),
      _GrowthTab(livestockData: livestockData),
      _VetTab(livestockData: livestockData),
      _ReportsTab(livestockData: livestockData),
    ];

    if (livestockData.isPoultry) {
      views.insert(4, _MortalityTab(livestockData: livestockData));
      views.insert(6, _RationPlanTab(livestockData: livestockData));
      if (livestockData.isLayer) {
        views.insert(7, _EggProductionTab(livestockData: livestockData));
      }
    } else {
      views.insert(5, _BreedingTab(livestockData: livestockData));
      views.insert(6, _ExitTab(livestockData: livestockData));
    }

    return views;
  }
}

// Tab widgets (simplified for demonstration)
class _ProfileTab extends StatelessWidget {
  final LivestockData livestockData;

  const _ProfileTab({required this.livestockData});

  @override
  Widget build(BuildContext context) {
    final animal = livestockData.animal!;
    final batch = livestockData.poultryBatch;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (animal.photoUrl != null)
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(animal.photoUrl!),
              ),
            ),
          const SizedBox(height: 16),
          _InfoRow('Species', animal.species),
          _InfoRow('Breed', animal.breed),
          _InfoRow('Age', animal.ageDisplayLabel),
          if (animal.sex != null) _InfoRow('Sex', animal.sex!),
          if (animal.purpose != null) _InfoRow('Purpose', animal.purpose!),
          if (batch != null) ...[
            const Divider(height: 32),
            Text(
              'Batch Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow('Batch Name', batch.name),
            _InfoRow('Initial Birds', '${batch.initialCount}'),
            _InfoRow(
              'Current Birds',
              '${batch.currentCount}',
              valueColor: batch.currentCount > 0 ? Colors.green : Colors.red,
            ),
            _InfoRow(
              'Mortality Rate',
              '${batch.mortalityRate.toStringAsFixed(1)}%',
              valueColor: batch.mortalityRate > 10 ? Colors.red : Colors.green,
            ),
            if (batch.chickCost != null)
              _InfoRow(
                'Batch Cost',
                Formatter.formatCurrency(batch.chickCost!, includeSymbol: false),
                valueColor: Colors.blue,
              ),
            _InfoRow('Age in Days', '${batch.ageInDays}'),
            _InfoRow('Age in Weeks', '${batch.ageInWeeks}'),
            if (batch.type.name.isNotEmpty) _InfoRow('Type', batch.type.name),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueColor != null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthTab extends StatelessWidget {
  final LivestockData livestockData;

  const _HealthTab({required this.livestockData});

  @override
  Widget build(BuildContext context) {
    final records = livestockData.isPoultry
        ? livestockData.poultryHealthRecords.cast<Object>()
        : livestockData.healthRecords.cast<Object>();

    if (records.isEmpty) {
      return const Center(child: Text('No health records found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        String type = 'Unknown';
        DateTime date = DateTime.now();
        String? product;
        double? cost;

        // Handle different record types
        if (livestockData.isPoultry && record is PoultryHealthRecord) {
          type = record.type;
          date = record.date;
          product = record.product;
          cost = record.cost;
        } else if (!livestockData.isPoultry && record is HealthRecord) {
          type = record.type;
          date = record.date;
          product = record.product;
          cost = record.cost;
        }

        return Card(
          child: ListTile(
            title: Text(type),
            subtitle: Text(
              '${date.toString().split(' ')[0]}${product != null ? ' • $product' : ''}',
            ),
            trailing: cost != null
                ? Text(Formatter.formatCurrency(cost, includeSymbol: false))
                : null,
          ),
        );
      },
    );
  }
}

class _FeedingTab extends StatelessWidget {
  final LivestockData livestockData;

  const _FeedingTab({required this.livestockData});

  @override
  Widget build(BuildContext context) {
    final records = livestockData.isPoultry
        ? livestockData.poultryFeedingRecords.cast<Object>()
        : livestockData.feedingEntries.cast<Object>();

    if (records.isEmpty) {
      return const Center(child: Text('No feeding records found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        String feedType = 'Unknown';
        DateTime date = DateTime.now();
        double quantityKg = 0.0;
        double? cost;

        // Handle different record types
        if (livestockData.isPoultry && record is PoultryFeedingRecord) {
          feedType = record.feedType;
          date = record.date;
          quantityKg = record.quantityKg;
          cost = record.cost;
        } else if (!livestockData.isPoultry && record is FeedingEntry) {
          feedType = record.feedType;
          date = record.date;
          quantityKg = record.quantityKg;
          cost = record.cost;
        }

        return Card(
          child: ListTile(
            title: Text(feedType),
            subtitle: Text(
              '${date.toString().split(' ')[0]} • ${quantityKg}kg',
            ),
            trailing: cost != null
                ? Text(Formatter.formatCurrency(cost, includeSymbol: false))
                : null,
          ),
        );
      },
    );
  }
}

class _GrowthTab extends StatelessWidget {
  final LivestockData livestockData;

  const _GrowthTab({required this.livestockData});

  @override
  Widget build(BuildContext context) {
    final records = livestockData.isPoultry
        ? livestockData.poultryGrowthRecords.cast<Object>()
        : livestockData.growthRecords.cast<Object>();

    if (records.isEmpty) {
      return const Center(child: Text('No growth records found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        double weightKg = 0.0;
        DateTime date = DateTime.now();

        // Handle different record types
        if (livestockData.isPoultry && record is PoultryGrowthRecord) {
          weightKg =
              record.averageWeightKg; // Use 'averageWeightKg' for poultry
          date = record.date;
        } else if (!livestockData.isPoultry && record is GrowthRecord) {
          weightKg = record.weightKg;
          date = record.date;
        }

        return Card(
          child: ListTile(
            title: Text('Weight: ${weightKg}kg'),
            subtitle: Text(date.toString().split(' ')[0]),
          ),
        );
      },
    );
  }
}

class _VetTab extends StatelessWidget {
  final LivestockData livestockData;

  const _VetTab({required this.livestockData});

  @override
  Widget build(BuildContext context) {
    final records = livestockData.isPoultry
        ? livestockData.poultryVetRecords.cast<Object>()
        : livestockData.vetVisits.cast<Object>();

    if (records.isEmpty) {
      return const Center(child: Text('No vet records found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        String? vetName;
        DateTime date = DateTime.now();
        double? cost;

        // Handle different record types
        if (livestockData.isPoultry && record is PoultryVetRecord) {
          vetName = record.reason; // Use 'reason' for poultry vet records
          date = record.visitDate;
          cost = record.cost;
        } else if (!livestockData.isPoultry && record is VetVisit) {
          vetName = record.vetName;
          date = record.visitDate;
          cost = record.cost;
        }

        return Card(
          child: ListTile(
            title: Text(vetName ?? 'Vet Visit'),
            subtitle: Text(date.toString().split(' ')[0]),
            trailing: cost != null
                ? Text(Formatter.formatCurrency(cost, includeSymbol: false))
                : null,
          ),
        );
      },
    );
  }
}

class _MortalityTab extends StatelessWidget {
  final LivestockData livestockData;

  const _MortalityTab({required this.livestockData});

  @override
  Widget build(BuildContext context) {
    final records = livestockData.poultryMortalityRecords;

    if (records.isEmpty) {
      return const Center(child: Text('No mortality records found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Card(
          child: ListTile(
            title: Text('Deaths: ${record.deaths}'),
            subtitle: Text(
              '${record.date.toString().split(' ')[0]}${record.notes != null ? ' • ${record.notes}' : ''}',
            ),
          ),
        );
      },
    );
  }
}

class _RationPlanTab extends StatelessWidget {
  final LivestockData livestockData;

  const _RationPlanTab({required this.livestockData});

  @override
  Widget build(BuildContext context) {
    final plans = livestockData.poultryRationPlans;

    if (plans.isEmpty) {
      return const Center(child: Text('No ration plans found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return Card(
          child: ListTile(
            title: Text('Ration Plan ${index + 1}'),
            subtitle: Text(
              'Created: ${plan.createdAt.toString().split(' ')[0]}',
            ),
          ),
        );
      },
    );
  }
}

class _EggProductionTab extends StatelessWidget {
  final LivestockData livestockData;

  const _EggProductionTab({required this.livestockData});

  @override
  Widget build(BuildContext context) {
    final records = livestockData.poultryProductionRecords;
    final batch = livestockData.poultryBatch;

    if (records.isEmpty) {
      return const Center(child: Text('No production records found.'));
    }

    // Calculate total eggs for today
    final today = DateTime.now();
    final todayRecords = records
        .where(
          (record) =>
              record.date.year == today.year &&
              record.date.month == today.month &&
              record.date.day == today.day,
        )
        .toList();

    final todayEggs = todayRecords.fold<int>(
      0,
      (sum, record) => sum + record.eggsCollected,
    );

    // Calculate egg percentage
    final currentBirdCount = batch?.currentCount ?? 0;
    final eggPercentage = currentBirdCount > 0
        ? (todayEggs / currentBirdCount) * 100
        : 0.0;

    return Column(
      children: [
        // Summary card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: 'Today\'s Eggs',
                    value: todayEggs.toString(),
                    icon: Icons.egg,
                    color: Colors.orange,
                  ),
                  _StatItem(
                    label: 'Current Birds',
                    value: currentBirdCount.toString(),
                    icon: Icons.pets,
                    color: Colors.blue,
                  ),
                  _StatItem(
                    label: 'Egg %',
                    value: '${eggPercentage.toStringAsFixed(1)}%',
                    icon: Icons.percent,
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Production records list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final isToday =
                  record.date.year == today.year &&
                  record.date.month == today.month &&
                  record.date.day == today.day;

              return Card(
                color: isToday ? Colors.orange.withValues(alpha: 0.05) : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isToday ? Colors.orange : Colors.grey,
                    child: const Icon(Icons.egg, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    'Eggs: ${record.eggsCollected}',
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${record.date.toString().split(' ')[0]}${isToday ? ' (Today)' : ''}',
                  ),
                  trailing: record.revenue != null
                      ? Text(
                          Formatter.formatCurrency(record.revenue!, includeSymbol: false),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _BreedingTab extends StatelessWidget {
  final LivestockData livestockData;

  const _BreedingTab({required this.livestockData});

  @override
  Widget build(BuildContext context) {
    final records = livestockData.breedingRecords;

    if (records.isEmpty) {
      return const Center(child: Text('No breeding records found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Card(
          child: ListTile(
            title: Text(record.method),
            subtitle: Text(
              '${record.date.toString().split(' ')[0]}${record.sireName != null ? ' • ${record.sireName}' : ''}',
            ),
          ),
        );
      },
    );
  }
}

class _ExitTab extends StatelessWidget {
  final LivestockData livestockData;

  const _ExitTab({required this.livestockData});

  @override
  Widget build(BuildContext context) {
    final records = livestockData.exitRecords;

    if (records.isEmpty) {
      return const Center(child: Text('No exit records found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Card(
          child: ListTile(
            title: Text(record.reason),
            subtitle: Text(
              '${record.date.toString().split(' ')[0]}${record.salePrice != null ? ' • ${Formatter.formatCurrency(record.salePrice!, includeSymbol: false)}' : ''}',
            ),
          ),
        );
      },
    );
  }
}

class _ReportsTab extends StatelessWidget {
  final LivestockData livestockData;

  const _ReportsTab({required this.livestockData});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Reports coming soon!'));
  }
}
