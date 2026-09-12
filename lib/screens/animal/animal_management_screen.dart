import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/services/animal/animal_repository_interface.dart';
import 'package:agribased/services/animal/firestore_animal_repository.dart';
import 'package:agribased/services/poultry/poultry_repository_interface.dart';
import 'package:agribased/services/poultry/firestore_poultry_repository.dart';

import 'package:agribased/widgets/animal/animal_card.dart';
import 'package:agribased/screens/animal/animal_form_screen.dart';
import 'package:agribased/models/poultry/poultry_batch.dart';

// General animal screens
import 'package:agribased/screens/animal/health_log_screen.dart';
import 'package:agribased/screens/animal/activity_log_screen.dart';
import 'package:agribased/screens/animal/breeding_screen.dart';
import 'package:agribased/screens/animal/feeding_schedule_screen.dart';
import 'package:agribased/screens/animal/growth_tracker_screen.dart';
import 'package:agribased/screens/animal/exit_log_screen.dart';
import 'package:agribased/screens/animal/vet_visit_screen.dart';
import 'package:agribased/screens/animal/reports_screen.dart';
import 'package:agribased/screens/animal/milk_production_screen.dart';
import 'package:agribased/widgets/full_screen_image_viewer.dart';
import 'package:agribased/screens/poultry/poultry_registration_screen.dart';

// Poultry screens
import 'package:agribased/screens/poultry/poultry_health_screen.dart' as health;
import 'package:agribased/screens/poultry/poultry_feeding_screen.dart';
import 'package:agribased/screens/poultry/poultry_growth_screen.dart' as growth;
import 'package:agribased/screens/poultry/poultry_exit_screen.dart';
import 'package:agribased/screens/poultry/poultry_vet_screen.dart';
import 'package:agribased/screens/poultry/poultry_egg_percentage_screen.dart';
import 'package:agribased/screens/poultry/poultry_reports_screen.dart';
import 'package:agribased/screens/poultry/poultry_mortality_screen.dart';
import 'package:agribased/screens/poultry/poultry_feed_formulation.dart';

// Ads
import 'package:agribased/widgets/ads/farm_native_ad.dart';
class AnimalManagementScreen extends StatefulWidget {
  const AnimalManagementScreen({super.key});

  @override
  State<AnimalManagementScreen> createState() => _AnimalManagementScreenState();
}

class _AnimalManagementScreenState extends State<AnimalManagementScreen> {
  final AnimalRepository _animalRepo = FirestoreAnimalRepository();
  final PoultryRepository _poultryRepo = FirestorePoultryRepository();
  List<Animal> _animals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    try {
      final list = await _animalRepo.listAnimals();
      if (mounted) {
        setState(() {
          _animals = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openAnimal(Animal animal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.92,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: _AnimalTabs(
            animal: animal,
            animalRepository: _animalRepo,
            poultryRepository: _poultryRepoPlaceholder(),
            onDeleted: _loadAnimals,
          ),
        ),
      ),
    );
  }

  // Helper to provide a PoultryRepository; use existing Firestore implementation
  PoultryRepository _poultryRepoPlaceholder() => _poultryRepo;

  void _openAnimalForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalFormScreen(repository: _animalRepo),
      ),
    ).then((_) => _loadAnimals());
  }

  void _openPoultryForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PoultryRegistrationScreen(
          poultryRepository: _poultryRepo,
          animalRepository: _animalRepo,
        ),
      ),
    ).then((_) => _loadAnimals());
  }

  void _showRegistrationChoice() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose registration type',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.pets, color: Colors.green),
                  title: const Text('Register animal'),
                  subtitle: const Text('Cattle, goats, sheep, or other livestock'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openAnimalForm();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.egg_outlined, color: Colors.green),
                  title: const Text('Register poultry'),
                  subtitle: const Text('Chickens, layers, broilers, and batches'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openPoultryForm();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon/huku.png', width: 96),
            const SizedBox(height: 20),
            Text(
              'No animals registered yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button below to register your first animal or poultry batch, and start tracking their health, feeding, and growth.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showRegistrationChoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Register now'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animal Management'),
        backgroundColor: Colors.green.shade700,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _animals.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _animals.length,
                  itemBuilder: (_, i) {
                    final animal = _animals[i];
                    return AnimalCard(
                      animal: animal,
                      onTap: () => _openAnimal(animal),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        onPressed: _showRegistrationChoice,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─────────────────────────── ANIMAL TABS (Custom Order) ───────────────────────────

// NOTE: The original file defined _AnimalTabs next. Restoring below.

class _AnimalTabs extends StatefulWidget {
  final Animal animal;
  final AnimalRepository animalRepository;
  final PoultryRepository poultryRepository;
  final VoidCallback onDeleted;

  const _AnimalTabs({
    required this.animal,
    required this.animalRepository,
    required this.poultryRepository,
    required this.onDeleted,
  });

  @override
  State<_AnimalTabs> createState() => _AnimalTabsState();
}

class _AnimalTabsState extends State<_AnimalTabs> {
  late Animal animal = widget.animal;
  bool _showEggTab = true;
  Timer? _ageRefreshTimer;

  bool get isPoultry => animal.species.toLowerCase() == 'poultry';
  bool get isMilkProduction => !isPoultry && animal.isDairyPurpose;

  @override
  void initState() {
    super.initState();
    _ageRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });

    // Default based on animal.purpose (registered batches set this)
    final p = animal.purpose?.toLowerCase() ?? '';
    if (p.contains('meat')) _showEggTab = false;

    // Additionally fetch the poultry batch document (if present) and
    // hide the egg tab when the batch purpose is meat.
    if (isPoultry) {
      FirebaseFirestore.instance
          .collection('poultry_batches')
          .doc(animal.id)
          .get()
          .then((doc) {
            if (!mounted) return;
            if (doc.exists) {
              try {
                final batch = doc.data() as Map<String, dynamic>;
                final bp = (batch['purpose'] as String?)?.toLowerCase() ?? '';
                if (bp.contains('meat')) {
                  setState(() => _showEggTab = false);
                }
              } catch (_) {}
            }
          })
          .catchError((_) {});
    }
  }

  @override
  void dispose() {
    _ageRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ────────────── Tabs in custom order ──────────────
    final tabs = <Tab>[
      const Tab(text: 'Profile'),
      const Tab(text: 'Vet'),
      const Tab(text: 'Health'),
      if (!isPoultry) const Tab(text: 'Activity Log'),
      if (isPoultry) const Tab(text: 'Farmer Activity'), // Only for poultry
      if (isPoultry) const Tab(text: 'Mortality'), // Only for poultry
      const Tab(text: 'Feeding'),
      if (isPoultry) const Tab(text: 'Feed Formulation'), // Only for poultry
      if (!isPoultry) const Tab(text: 'Breeding'), // Only for non-poultry
      const Tab(text: 'Growth'),
      if (isPoultry && _showEggTab)
        const Tab(text: 'Egg %'), // Only for egg-laying poultry
      if (isMilkProduction)
        const Tab(text: 'Milk Production'), // Only for dairy/milk livestock
      const Tab(text: 'Exit'),
      const Tab(text: 'Reports'),
    ];

    // ────────────── Views in same order ──────────────
    final views = <Widget>[
      _ProfileTab(
        animal: animal,
        repository: widget.animalRepository,
        onDeleted: widget.onDeleted,
      ),
      // Vet Visits
      isPoultry
          ? PoultryVetScreen(
              animal: animal,
              repository: widget.poultryRepository,
            )
          : VetVisitScreen(animal: animal, repository: widget.animalRepository),

      // Health
      isPoultry
          ? health.PoultryHealthScreen(
              animal: animal,
              repository: widget.poultryRepository,
            )
          : HealthLogScreen(
              animal: animal,
              repository: widget.animalRepository,
            ),

      // Activity Log (only for non-poultry)
      if (!isPoultry)
        ActivityLogScreen(
          animal: animal,
          repository: widget.animalRepository,
          onAnimalUpdated: (updatedAnimal) {
            if (mounted) {
              setState(() => animal = updatedAnimal);
              widget.onDeleted();
            }
          },
        ),

      // Farmer activity (only for poultry)
      if (isPoultry)
        ActivityLogScreen(
          animal: animal,
          repository: widget.animalRepository,
          title: 'Farmer Activity',
          quantityLabel: 'Flock added (optional)',
          onAnimalUpdated: (updatedAnimal) {
            if (mounted) {
              setState(() => animal = updatedAnimal);
              widget.onDeleted();
            }
          },
          onActivityRecorded: (record, updatedAnimal) async {
            if (!isPoultry) return;
            if (record.animalsAdded != null && record.animalsAdded! > 0) {
              await FirebaseFirestore.instance
                  .collection('poultry_batches')
                  .doc(animal.id)
                  .update({
                    'currentCount': FieldValue.increment(record.animalsAdded!),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
            }
          },
        ),

      // Mortality (only for poultry) - attempt to read canonical batch to get flock size
      if (isPoultry)
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('poultry_batches')
              .doc(animal.id)
              .get(),
          builder: (context, snap) {
            int flockSize = animal.initialFlockSize ?? 0;
            if (snap.hasData && snap.data!.exists) {
              try {
                final batch = PoultryBatch.fromDocument(snap.data!);
                flockSize = batch.initialCount;
              } catch (_) {}
            }
            return PoultryMortalityScreen(
              batchId: animal.id,
              repository: widget.poultryRepository,
              flockSize: flockSize,
            );
          },
        ),

      // Feeding Schedule
      isPoultry
          ? FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('poultry_batches')
                  .doc(animal.id)
                  .get(),
              builder: (context, snap) {
                int? flockSize = animal.totalCount > 0 ? animal.totalCount : animal.initialFlockSize;
                if (snap.hasData && snap.data!.exists) {
                  try {
                    final batch = PoultryBatch.fromDocument(snap.data!);
                    flockSize = batch.currentCount > 0 ? batch.currentCount : batch.initialCount;
                  } catch (_) {}
                }
                return PoultryFeedingScreen(
                  batchId: animal.id,
                  repository: widget.poultryRepository,
                  startDate: animal.createdAt,
                  flockType: animal.species.toLowerCase().contains('layer')
                      ? FlockType.layer
                      : FlockType.broiler,
                  flockSize: flockSize,
                );
              },
            )
          : FeedingScheduleScreen(
              animal: animal,
              repository: widget.animalRepository,
            ),

      // Feed Formulation (only for poultry)
      if (isPoultry) SmartFeedFormulationScreen(batchId: animal.id),

      // Breeding (only for non-poultry animals)
      if (!isPoultry)
        BreedingScreen(animal: animal, repository: widget.animalRepository),

      // Growth Tracking
      isPoultry
          ? growth.PoultryGrowthScreen(
              animal: animal,
              repository: widget.poultryRepository,
            )
          : GrowthTrackerScreen(
              animal: animal,
              repository: widget.animalRepository,
              targetWeight: animal.targetWeightKg ?? 400,
            ),

      // Egg Percentage (only for egg-laying poultry)
      if (isPoultry && _showEggTab)
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('poultry_batches')
              .doc(animal.id)
              .get(),
          builder: (context, snap) {
            if (snap.hasData && snap.data!.exists) {
              try {
                PoultryBatch.fromDocument(snap.data!);
              } catch (_) {}
            }
            return PoultryEggPercentageScreen(
              animal: animal,
              repository: widget.poultryRepository,
            );
          },
        ),

      // Milk Production (only for dairy/milk livestock)
      if (isMilkProduction)
        MilkProductionScreen(
          animal: animal,
          repository: widget.animalRepository,
        ),

      // Exit
      isPoultry
          ? PoultryExitScreen(
              animal: animal,
              repository: widget.poultryRepository,
            )
          : ExitLogScreen(
              animal: animal,
              repository: widget.animalRepository,
              onAnimalUpdated: (updatedAnimal) {
                if (mounted) setState(() => animal = updatedAnimal);
              },
            ),

      // Reports
      isPoultry
          ? PoultryReportsScreen(
              animal: animal,
              repository: widget.poultryRepository,
            )
          : ReportsScreen(animal: animal, repository: widget.animalRepository),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          title: Text(
            '${animal.species} • ${animal.breed}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: tabs,
          ),
        ),
        body: TabBarView(children: views),
      ),
    );
  }
}

/* ─────────────────────────── PROFILE TAB (DOUBLE TAP DELETE) ─────────────────────────── */

class _ProfileTab extends StatefulWidget {
  final Animal animal;
  final AnimalRepository repository;
  final VoidCallback onDeleted;

  const _ProfileTab({
    required this.animal,
    required this.repository,
    required this.onDeleted,
  });

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late Animal _animal;
  final ImagePicker _picker = ImagePicker();

  bool get isPoultry => _animal.species.toLowerCase() == 'poultry';

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
    _loadExitRecords();
  }

  @override
  void didUpdateWidget(covariant _ProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animal != widget.animal) {
      setState(() => _animal = widget.animal);
      _loadExitRecords();
    }
  }

  Future<void> _editPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final updated = _animal.copyWith(photoUrl: picked.path);
    await widget.repository.updateAnimal(updated);
    if (mounted) setState(() => _animal = updated);
  }

  Future<void> _deleteAnimal() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Animal'),
        content: const Text('Are you sure you want to remove this animal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await widget.repository.deleteAnimal(_animal.id);
      widget.onDeleted();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _loadExitRecords() async {
    await widget.repository.listExitRecords(_animal.id);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _deleteAnimal,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_animal.photoUrl != null && _animal.photoUrl!.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(
                        imageUrls: [_animal.photoUrl!],
                        heroTag: 'animal_profile_${_animal.id}',
                      ),
                    ),
                  );
                },
                onDoubleTap: _editPhoto,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _animal.photoUrl!,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/icon/huku.png', width: 72),
                      const SizedBox(height: 8),
                      const Text('No photo added yet'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              '${_animal.species} • ${_animal.breed}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (!isPoultry)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Age: ${_animal.ageDisplayLabel}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Sex: ${_animal.sex ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Total: ${_animal.totalCount}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (_animal.totalCost > 0)
                      Text(
                        'Cost: ${_animal.formatMoney(_animal.totalCost)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    if (_animal.purpose != null && _animal.purpose!.isNotEmpty)
                      Text(
                        'Purpose: ${_animal.purpose}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              )
            else
              Text(
                'Age : ${_animal.ageDisplayLabel} | Sex : ${_animal.sex ?? 'N/A'}${_animal.totalCost > 0 ? " | Cost: ${_animal.formatMoney(_animal.totalCost)}" : ""}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            if (!isPoultry) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sticky_note_2, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Notes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _animal.notes?.isNotEmpty == true
                            ? _animal.notes!
                            : 'No notes added yet',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // ── Native Ad: sponsor placed at profile bottom ──
            const FarmNativeAd(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

