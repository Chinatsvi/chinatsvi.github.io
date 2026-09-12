import 'package:flutter/material.dart';
import '../../models/fertilizer/fertilizer_crop.dart';
import '../../models/fertilizer/fertilizer_product.dart';
import '../../models/fertilizer/fertilizer_recommendation.dart';
import '../../models/fertilizer/fertilizer_source.dart';
import '../../services/fertilizer/fertilizer_admin_service.dart';
import '../../services/fertilizer/fertilizer_repository.dart';
import 'farm_calculator_widgets.dart';

class FertilizerAdminScreen extends StatefulWidget {
  const FertilizerAdminScreen({super.key});

  @override
  State<FertilizerAdminScreen> createState() => _FertilizerAdminScreenState();
}

class _FertilizerAdminScreenState extends State<FertilizerAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FertilizerRepository _repo = FertilizerRepository();
  final FertilizerAdminService _adminService = FertilizerAdminService();

  bool _isLoading = true;
  List<FertilizerCrop> _crops = [];
  List<FertilizerProduct> _products = [];
  List<FertilizerRecommendation> _recommendations = [];
  List<FertilizerSource> _sources = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final crops = await _repo.getCrops(forceRefresh: true);
      final products = await _repo.getProducts(forceRefresh: true);
      final recs = await _repo.getRecommendations(forceRefresh: true);
      final sources = await _repo.getSources(forceRefresh: true);

      if (mounted) {
        setState(() {
          _crops = crops;
          _products = products;
          _recommendations = recs;
          _sources = sources;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _seedDatabase() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Seeding database to Firestore...')),
      );
      await _repo.seedInitialDatabaseIfEmpty();
      await _loadData();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Database seeded successfully! ✅'),
          backgroundColor: farmGreen,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to seed database: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fertilizer Recommendation Admin'),
        backgroundColor: farmGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Seed / Sync Database',
            onPressed: _seedDatabase,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.verified), text: 'Recommendations'),
            Tab(icon: Icon(Icons.grass), text: 'Crops'),
            Tab(icon: Icon(Icons.science), text: 'Products'),
            Tab(icon: Icon(Icons.menu_book), text: 'Sources'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: farmGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecommendationsTab(),
                _buildCropsTab(),
                _buildProductsTab(),
                _buildSourcesTab(),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: RECOMMENDATIONS
  // ---------------------------------------------------------------------------
  Widget _buildRecommendationsTab() {
    if (_recommendations.isEmpty) {
      return const Center(child: Text('No recommendations found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final rec = _recommendations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: rec.confidence ==
                                RecommendationConfidence.verified
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rec.confidence.badgeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: rec.confidence ==
                                  RecommendationConfidence.verified
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${rec.cropName} (${rec.countryName})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Switch(
                      value: rec.active,
                      activeThumbColor: farmGreen,
                      onChanged: (val) async {
                        await _adminService.toggleRecommendationStatus(
                          rec.id,
                          val,
                        );
                        _loadData();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Stage: ${rec.stageName}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (rec.regionName != null)
                  Text(
                    'Region: ${rec.regionName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('N: ${rec.nKgPerHaRec.toStringAsFixed(0)} kg/ha'),
                      Text('P₂O₅: ${rec.p2o5KgPerHaRec.toStringAsFixed(0)} kg/ha'),
                      Text('K₂O: ${rec.k2oKgPerHaRec.toStringAsFixed(0)} kg/ha'),
                    ],
                  ),
                ),
                if (rec.preferredProductName != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Product: ${rec.preferredProductName} @ ${rec.rateKgPerHaRec.toStringAsFixed(0)} ${rec.rateUnit}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: CROPS
  // ---------------------------------------------------------------------------
  Widget _buildCropsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _crops.length,
      itemBuilder: (context, index) {
        final crop = _crops[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: farmLightGreen,
              child: Text(crop.iconEmoji, style: const TextStyle(fontSize: 20)),
            ),
            title: Text(
              crop.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${crop.scientificName} • ${crop.category.displayName}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Switch(
              value: crop.active,
              activeThumbColor: farmGreen,
              onChanged: (val) async {
                await _adminService.toggleCropStatus(crop.id, val);
                _loadData();
              },
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: PRODUCTS
  // ---------------------------------------------------------------------------
  Widget _buildProductsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final p = _products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: farmLightGreen,
              child: Icon(Icons.science, color: farmGreen),
            ),
            title: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Grade: ${p.formulaGrade} | Country: ${p.countryName} | Bag: ${p.packageSize.toStringAsFixed(0)} ${p.packageUnit}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Switch(
              value: p.active,
              activeThumbColor: farmGreen,
              onChanged: (val) async {
                await _adminService.toggleProductStatus(p.id, val);
                _loadData();
              },
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: SOURCES
  // ---------------------------------------------------------------------------
  Widget _buildSourcesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _sources.length,
      itemBuilder: (context, index) {
        final s = _sources[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: farmGreen, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s.organization,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      '${s.year}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  s.title,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
                if (s.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
