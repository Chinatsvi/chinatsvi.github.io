import 'package:flutter/material.dart';
import '../../models/crop_calendar/crop_calendar_models.dart';
import '../../services/crop_calendar/crop_calendar_service.dart';
import 'crop_calendar_result_screen.dart';
import 'widgets/crop_location_picker.dart';
import 'widgets/crop_selector_widget.dart';
import 'widgets/growing_conditions_widget.dart';
import 'widgets/saved_crop_calendars_tab.dart';
import '../../widgets/ads/farm_banner_ad.dart';
import '../../widgets/ads/farm_native_ad.dart';

class CropCalendarScreen extends StatefulWidget {
  const CropCalendarScreen({super.key});

  @override
  State<CropCalendarScreen> createState() => _CropCalendarScreenState();
}

class _CropCalendarScreenState extends State<CropCalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CropCalendarService _service = CropCalendarService();

  bool _isLoading = true;
  List<HorticulturalCrop> _crops = [];

  // Form State
  late LocationAgroProfile _selectedLocation;
  late HorticulturalCrop _selectedCrop;
  CropVariety? _selectedVariety;
  ProductionSystem _productionSystem = ProductionSystem.openField;
  WaterSource _waterSource = WaterSource.irrigated;
  DateTime _plantingDate = DateTime.now();
  String? _soilType;
  bool _soilTestAvailable = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final crops = await _service.getHorticulturalCrops();
    final locations = _service.getAvailableLocations();

    setState(() {
      _crops = crops;
      _selectedLocation = locations.first; // Default e.g. Masvingo, Zimbabwe
      _selectedCrop = crops.first; // Default e.g. Tomato
      _selectedVariety =
          crops.first.varieties.isNotEmpty ? crops.first.varieties.first : null;
      _isLoading = false;
    });
  }

  void _generateRecommendation() {
    final recommendation = _service.generateRecommendation(
      crop: _selectedCrop,
      variety: _selectedVariety,
      location: _selectedLocation,
      productionSystem: _productionSystem,
      waterSource: _waterSource,
      plantingDate: _plantingDate,
      soilType: _soilType,
      soilTestAvailable: _soilTestAvailable,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CropCalendarResultScreen(recommendation: recommendation),
      ),
    ).then((saved) {
      if (saved == true) {
        _tabController.animateTo(1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      bottomNavigationBar: const FarmBannerAd(),
      appBar: AppBar(
        title: const Text(
          'Farm Calendar',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(
              icon: Icon(Icons.spa),
              text: 'Plan New Crop',
            ),
            Tab(
              icon: Icon(Icons.event_note),
              text: 'My Farm Calendars',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Plan New Crop
                _buildPlanNewCropTab(),

                // Tab 2: Saved Crops
                SavedCropCalendarsTab(
                  onStartNewPlan: () {
                    _tabController.animateTo(0);
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildPlanNewCropTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1: Location
          CropLocationPicker(
            selectedLocation: _selectedLocation,
            onLocationChanged: (loc) => setState(() => _selectedLocation = loc),
          ),

          const SizedBox(height: 14),

          // Step 2: Crop & Variety
          CropSelectorWidget(
            crops: _crops,
            selectedCrop: _selectedCrop,
            selectedVariety: _selectedVariety,
            onCropSelected: (crop) => setState(() => _selectedCrop = crop),
            onVarietySelected: (variety) =>
                setState(() => _selectedVariety = variety),
          ),

          const SizedBox(height: 14),

          // Step 3: Production System & Planting Date
          GrowingConditionsWidget(
            productionSystem: _productionSystem,
            waterSource: _waterSource,
            plantingDate: _plantingDate,
            soilType: _soilType,
            soilTestAvailable: _soilTestAvailable,
            onProductionSystemChanged: (sys) =>
                setState(() => _productionSystem = sys),
            onWaterSourceChanged: (ws) => setState(() => _waterSource = ws),
            onPlantingDateChanged: (date) =>
                setState(() => _plantingDate = date),
            onSoilTypeChanged: (st) => setState(() => _soilType = st),
            onSoilTestAvailableChanged: (sta) =>
                setState(() => _soilTestAvailable = sta),
          ),

          const SizedBox(height: 16),

          // Sponsored Native Ad
          const FarmNativeAd(),

          const SizedBox(height: 20),

          // Generate Crop Plan CTA
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _generateRecommendation,
              icon: const Icon(Icons.auto_awesome),
              label: Text(
                'Generate ${_selectedCrop.name} Crop Plan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
