import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'farm_calculator_widgets.dart';
import 'farm_calculator_history.dart';

enum CropGrowthStage {
  initial,
  development,
  midSeason,
  lateSeason,
}

class CropWaterDemandProfile {
  final String id;
  final String name;
  final String emoji;
  final double kcIni;
  final double kcDev;
  final double kcMid;
  final double kcEnd;
  final String defaultIrrigation;
  final String tip;

  const CropWaterDemandProfile({
    required this.id,
    required this.name,
    required this.emoji,
    required this.kcIni,
    required this.kcDev,
    required this.kcMid,
    required this.kcEnd,
    required this.defaultIrrigation,
    required this.tip,
  });

  double getKcForStage(CropGrowthStage stage) {
    switch (stage) {
      case CropGrowthStage.initial:
        return kcIni;
      case CropGrowthStage.development:
        return kcDev;
      case CropGrowthStage.midSeason:
        return kcMid;
      case CropGrowthStage.lateSeason:
        return kcEnd;
    }
  }

  static const List<CropWaterDemandProfile> allCrops = [
    CropWaterDemandProfile(
      id: 'tomato',
      name: 'Tomato',
      emoji: '🍅',
      kcIni: 0.60,
      kcDev: 0.85,
      kcMid: 1.15,
      kcEnd: 0.80,
      defaultIrrigation: 'Drip',
      tip: 'Maintain consistent soil moisture during flowering & fruit set to prevent blossom end rot and fruit splitting.',
    ),
    CropWaterDemandProfile(
      id: 'maize',
      name: 'Maize (Corn)',
      emoji: '🌽',
      kcIni: 0.30,
      kcDev: 0.70,
      kcMid: 1.20,
      kcEnd: 0.60,
      defaultIrrigation: 'Sprinkler',
      tip: 'Tasseling and silking are the most critical water stress periods; yield drops drastically if stressed during silking.',
    ),
    CropWaterDemandProfile(
      id: 'cabbage',
      name: 'Cabbage & Brassicas',
      emoji: '🥬',
      kcIni: 0.50,
      kcDev: 0.75,
      kcMid: 1.05,
      kcEnd: 0.95,
      defaultIrrigation: 'Sprinkler',
      tip: 'Shallow rooted; requires regular water applications during head enlargement to prevent premature bursting.',
    ),
    CropWaterDemandProfile(
      id: 'groundnut',
      name: 'Groundnut (Peanut)',
      emoji: '🥜',
      kcIni: 0.40,
      kcDev: 0.70,
      kcMid: 1.15,
      kcEnd: 0.60,
      defaultIrrigation: 'Sprinkler',
      tip: 'Pegging and pod development require adequate topsoil moisture so pegs can easily penetrate the soil bed.',
    ),
    CropWaterDemandProfile(
      id: 'beans',
      name: 'Beans (Green / Dry)',
      emoji: '🫘',
      kcIni: 0.40,
      kcDev: 0.70,
      kcMid: 1.15,
      kcEnd: 0.45,
      defaultIrrigation: 'Drip',
      tip: 'Sensitive to waterlogging and severe dry spells during flowering and pod setting.',
    ),
    CropWaterDemandProfile(
      id: 'potato',
      name: 'Potato',
      emoji: '🥔',
      kcIni: 0.50,
      kcDev: 0.75,
      kcMid: 1.15,
      kcEnd: 0.75,
      defaultIrrigation: 'Sprinkler',
      tip: 'Tuber initiation and bulking demand constant moisture to avoid deformed or hollow heart tubers.',
    ),
    CropWaterDemandProfile(
      id: 'onion',
      name: 'Onion & Garlic',
      emoji: '🧅',
      kcIni: 0.70,
      kcDev: 0.85,
      kcMid: 1.05,
      kcEnd: 0.75,
      defaultIrrigation: 'Drip',
      tip: 'Shallow root system; stop irrigation 2-3 weeks before harvest for proper bulb curing.',
    ),
    CropWaterDemandProfile(
      id: 'pepper',
      name: 'Pepper & Chilli',
      emoji: '🌶️',
      kcIni: 0.60,
      kcDev: 0.85,
      kcMid: 1.05,
      kcEnd: 0.90,
      defaultIrrigation: 'Drip',
      tip: 'Flower drop occurs if water stressed during warm weather. Keep roots consistently moist.',
    ),
    CropWaterDemandProfile(
      id: 'wheat',
      name: 'Wheat & Small Grains',
      emoji: '🌾',
      kcIni: 0.30,
      kcDev: 0.75,
      kcMid: 1.15,
      kcEnd: 0.40,
      defaultIrrigation: 'Centre Pivot',
      tip: 'Crown root initiation, booting, and grain milk stages require guaranteed irrigation.',
    ),
    CropWaterDemandProfile(
      id: 'watermelon',
      name: 'Watermelon & Melons',
      emoji: '🍉',
      kcIni: 0.40,
      kcDev: 0.70,
      kcMid: 1.00,
      kcEnd: 0.75,
      defaultIrrigation: 'Drip',
      tip: 'Reduce irrigation slightly during late ripening to increase fruit sugar content (brix).',
    ),
    CropWaterDemandProfile(
      id: 'cotton',
      name: 'Cotton',
      emoji: '🌱',
      kcIni: 0.35,
      kcDev: 0.75,
      kcMid: 1.20,
      kcEnd: 0.65,
      defaultIrrigation: 'Drip',
      tip: 'Peak water demand occurs during peak flowering and boll formation.',
    ),
    CropWaterDemandProfile(
      id: 'carrot',
      name: 'Carrot & Root Veg',
      emoji: '🥕',
      kcIni: 0.50,
      kcDev: 0.75,
      kcMid: 1.05,
      kcEnd: 0.95,
      defaultIrrigation: 'Sprinkler',
      tip: 'Irregular watering leads to cracked and forked roots. Keep top 20cm evenly moist.',
    ),
    CropWaterDemandProfile(
      id: 'citrus',
      name: 'Citrus & Fruit Trees',
      emoji: '🍊',
      kcIni: 0.70,
      kcDev: 0.70,
      kcMid: 0.65,
      kcEnd: 0.70,
      defaultIrrigation: 'Micro-Sprinkler',
      tip: 'Deep root zone irrigation; apply water beneath tree canopy drip-line.',
    ),
    CropWaterDemandProfile(
      id: 'banana',
      name: 'Banana',
      emoji: '🍌',
      kcIni: 1.00,
      kcDev: 1.10,
      kcMid: 1.20,
      kcEnd: 1.10,
      defaultIrrigation: 'Drip',
      tip: 'High water requirement year-round due to large broad leaves and rapid transpiration.',
    ),
    CropWaterDemandProfile(
      id: 'pasture',
      name: 'Pasture / Lucerne (Alfalfa)',
      emoji: '🌿',
      kcIni: 0.40,
      kcDev: 0.85,
      kcMid: 1.20,
      kcEnd: 1.15,
      defaultIrrigation: 'Sprinkler',
      tip: 'Irrigate immediately following every cut/harvest to stimulate vigorous regrowth.',
    ),
  ];
}

class IrrigationSystemProfile {
  final String id;
  final String name;
  final int defaultEfficiency; // Percentage
  final String description;

  const IrrigationSystemProfile({
    required this.id,
    required this.name,
    required this.defaultEfficiency,
    required this.description,
  });

  static const List<IrrigationSystemProfile> allSystems = [
    IrrigationSystemProfile(
      id: 'drip',
      name: 'Drip / Micro-Drip',
      defaultEfficiency: 90,
      description: 'High precision, minimal evaporation & runoff loss.',
    ),
    IrrigationSystemProfile(
      id: 'micro_sprinkler',
      name: 'Micro-Sprinkler / Jet',
      defaultEfficiency: 85,
      description: 'Under-canopy spray with low wind drift.',
    ),
    IrrigationSystemProfile(
      id: 'centre_pivot',
      name: 'Centre Pivot / Linear',
      defaultEfficiency: 85,
      description: 'Uniform mechanized spray application.',
    ),
    IrrigationSystemProfile(
      id: 'overhead_sprinkler',
      name: 'Overhead Sprinkler',
      defaultEfficiency: 75,
      description: 'Portable or solid-set impact sprinklers.',
    ),
    IrrigationSystemProfile(
      id: 'basin',
      name: 'Basin / Bed Flooding',
      defaultEfficiency: 65,
      description: 'Level beds enclosed by bunds.',
    ),
    IrrigationSystemProfile(
      id: 'furrow',
      name: 'Furrow / Ridge Irrigation',
      defaultEfficiency: 55,
      description: 'Water flows along gravity trenches between ridges.',
    ),
    IrrigationSystemProfile(
      id: 'manual',
      name: 'Manual / Watering Can',
      defaultEfficiency: 65,
      description: 'Hand watering with bucket or hose.',
    ),
  ];
}

class IrrigationCalculator extends StatefulWidget {
  final String? initialCropName;
  final CropGrowthStage? initialGrowthStage;
  final double? initialArea;
  final String? initialAreaUnit;

  const IrrigationCalculator({
    super.key,
    this.initialCropName,
    this.initialGrowthStage,
    this.initialArea,
    this.initialAreaUnit,
  });

  @override
  State<IrrigationCalculator> createState() => _IrrigationCalculatorState();
}

class _IrrigationCalculatorState extends State<IrrigationCalculator> {
  // Mode: 0 = Crop Water Requirement (FAO-56 Guided), 1 = Manual Depth Mode
  int _selectedMode = 0;

  // Guided Mode State
  late CropWaterDemandProfile _selectedCrop;
  late CropGrowthStage _selectedStage;
  IrrigationSystemProfile _selectedSystem = IrrigationSystemProfile.allSystems.first;

  late final TextEditingController _etoController;
  late final TextEditingController _rainfallController;
  late final TextEditingController _guidedAreaController;
  late final TextEditingController _guidedEfficiencyController;
  int _intervalDays = 1; // Daily, 2 days, 3 days, etc.
  late String _guidedAreaUnit;

  // Manual Mode State
  late final TextEditingController _manualAreaController;
  late final TextEditingController _manualDepthController;
  late final TextEditingController _manualEfficiencyController;
  String _manualAreaUnit = 'Hectares';

  // Weather fetch status
  bool _isFetchingWeather = false;
  String? _weatherLocationNote;

  // Results State
  String? _result;
  String? _details;
  Map<String, String>? _exportReportData;

  @override
  void initState() {
    super.initState();
    _selectedCrop = _matchCropProfile(widget.initialCropName);
    _selectedStage = widget.initialGrowthStage ?? CropGrowthStage.midSeason;

    final initialAreaStr = widget.initialArea != null ? widget.initialArea!.toString() : '1.0';
    _guidedAreaUnit = widget.initialAreaUnit ?? 'Hectares';
    _manualAreaUnit = _guidedAreaUnit;

    _etoController = TextEditingController(text: '5.0');
    _rainfallController = TextEditingController(text: '0.0');
    _guidedAreaController = TextEditingController(text: initialAreaStr);
    _guidedEfficiencyController = TextEditingController(text: _selectedSystem.defaultEfficiency.toString());

    _manualAreaController = TextEditingController(text: initialAreaStr);
    _manualDepthController = TextEditingController();
    _manualEfficiencyController = TextEditingController(text: '80');

    // Auto calculate if initial parameters were provided
    if (widget.initialCropName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateGuided();
      });
    }
  }

  CropWaterDemandProfile _matchCropProfile(String? cropName) {
    if (cropName == null || cropName.trim().isEmpty) {
      return CropWaterDemandProfile.allCrops.first;
    }
    final clean = cropName.toLowerCase().trim();
    for (final crop in CropWaterDemandProfile.allCrops) {
      if (crop.name.toLowerCase().contains(clean) || clean.contains(crop.name.toLowerCase()) || clean.contains(crop.id)) {
        return crop;
      }
    }
    return CropWaterDemandProfile.allCrops.first;
  }

  @override
  void dispose() {
    _etoController.dispose();
    _rainfallController.dispose();
    _guidedAreaController.dispose();
    _guidedEfficiencyController.dispose();
    _manualAreaController.dispose();
    _manualDepthController.dispose();
    _manualEfficiencyController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveWeatherETo() async {
    setState(() {
      _isFetchingWeather = true;
      _weatherLocationNote = null;
    });

    try {
      Position? position;
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
            ).timeout(const Duration(seconds: 6));
          }
        }
      } catch (e) {
        debugPrint('Geolocator notice: $e');
      }

      final lat = position?.latitude ?? -17.8248;
      final lon = position?.longitude ?? 31.0530;

      final meteoUrl =
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=et0_fao_evapotranspiration,precipitation_sum&current=temperature_2m,relative_humidity_2m&timezone=auto';

      final response = await http
          .get(Uri.parse(meteoUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final daily = data['daily'];
        final current = data['current'];

        final et0List = daily?['et0_fao_evapotranspiration'] as List?;
        final rainList = daily?['precipitation_sum'] as List?;

        final double rawEt0 = (et0List != null && et0List.isNotEmpty)
            ? (et0List[0] as num).toDouble()
            : 4.8;
        final double rawRain = (rainList != null && rainList.isNotEmpty)
            ? (rainList[0] as num).toDouble()
            : 0.0;

        final double temp = (current?['temperature_2m'] as num?)?.toDouble() ?? 24.0;
        final int hum = (current?['relative_humidity_2m'] as num?)?.toInt() ?? 55;

        // Effective rainfall formula (80% if > 5mm, 50% if <= 5mm)
        final double effectiveRain = rawRain > 5.0
            ? (rawRain * 0.8)
            : (rawRain > 0 ? rawRain * 0.5 : 0.0);

        setState(() {
          _etoController.text = rawEt0.toStringAsFixed(2);
          _rainfallController.text = effectiveRain.toStringAsFixed(2);
          _weatherLocationNote = position != null
              ? '📍 GPS Synced: ${temp.toStringAsFixed(1)}°C, $hum% RH • Daily ETo: ${rawEt0.toStringAsFixed(2)} mm • Rain: ${rawRain.toStringAsFixed(1)} mm'
              : '🌦️ Regional Baseline: ${temp.toStringAsFixed(1)}°C • Daily ETo: ${rawEt0.toStringAsFixed(2)} mm • Rain: ${rawRain.toStringAsFixed(1)} mm';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Live agro-weather & FAO-56 ETo synced successfully! 🌦️'),
              backgroundColor: farmGreen,
            ),
          );
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Fallback
      setState(() {
        _etoController.text = '5.0';
        _rainfallController.text = '0.0';
        _weatherLocationNote = '☀️ Standard seasonal baseline: 5.0 mm/day ETo (Sunny/Warm)';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Used seasonal agricultural baseline (5.0 mm/day ETo). Note: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingWeather = false);
      }
    }
  }

  void _calculateGuided() {
    dismissCalculatorKeyboard();

    final eto = farmNumber(_etoController);
    final rain = farmNumber(_rainfallController) ?? 0.0;
    final area = farmNumber(_guidedAreaController);
    final eff = farmNumber(_guidedEfficiencyController);

    if (eto == null || eto <= 0 || area == null || area <= 0 || eff == null || eff <= 0 || eff > 100) {
      setState(() {
        _result = 'Please enter valid numbers for ETo, area, and efficiency';
        _details = null;
      });
      return;
    }

    final kc = _selectedCrop.getKcForStage(_selectedStage);
    final etc = eto * kc; // Crop water use in mm/day
    final netDailyDemand = (etc - rain).clamp(0.0, 50.0);
    final netCycleDemand = netDailyDemand * _intervalDays;
    final grossCycleDepth = netCycleDemand / (eff / 100.0);

    final hectares = _guidedAreaUnit == 'Acres' ? area * 0.404686 : area;
    final totalLitres = grossCycleDepth * hectares * 10000.0;
    final totalM3 = totalLitres / 1000.0;

    final stageName = _getStageName(_selectedStage);

    setState(() {
      _result = '${farmFormatNumber(totalLitres.round())} Litres (${totalM3.toStringAsFixed(1)} m³)';
      _details =
          '🌱 Crop: ${_selectedCrop.emoji} ${_selectedCrop.name} ($stageName, Kc = ${kc.toStringAsFixed(2)})\n'
          '☀️ Reference ETo: ${eto.toStringAsFixed(2)} mm/day\n'
          '🌿 Crop Water Use (ETc): ${etc.toStringAsFixed(2)} mm/day (${eto.toStringAsFixed(2)} × ${kc.toStringAsFixed(2)})\n'
          '🌧️ Effective Rainfall Credit: ${rain.toStringAsFixed(2)} mm\n'
          '💧 Net Water Deficit: ${netDailyDemand.toStringAsFixed(2)} mm/day\n'
          '📅 Irrigation Cycle: ${_intervalDays == 1 ? "Daily" : "Every $_intervalDays days"} → ${netCycleDemand.toStringAsFixed(2)} mm net\n'
          '🚿 System Application (${eff.toStringAsFixed(0)}% ${_selectedSystem.name}): ${grossCycleDepth.toStringAsFixed(2)} mm gross\n'
          '🪣 Field Requirement: ${farmFormatNumber(totalLitres.round())} L for ${farmFormatNumber(area)} $_guidedAreaUnit (${grossCycleDepth.toStringAsFixed(2)} L/m²)\n\n'
          '💡 Agronomic Note: ${_selectedCrop.tip}';

      _exportReportData = {
        'Calculator Mode': 'Crop Water Requirement (FAO-56 Guided)',
        'Crop': '${_selectedCrop.emoji} ${_selectedCrop.name}',
        'Growth Stage': '$stageName (Kc = ${kc.toStringAsFixed(2)})',
        'Reference ETo': '${eto.toStringAsFixed(2)} mm/day',
        'Crop Water Use (ETc)': '${etc.toStringAsFixed(2)} mm/day',
        'Effective Rainfall': '${rain.toStringAsFixed(2)} mm',
        'Net Irrigation Demand': '${netDailyDemand.toStringAsFixed(2)} mm/day',
        'Irrigation Interval': '$_intervalDays day(s)',
        'Irrigation System': '${_selectedSystem.name} (${eff.toStringAsFixed(0)}% eff)',
        'Gross Depth to Apply': '${grossCycleDepth.toStringAsFixed(2)} mm (${grossCycleDepth.toStringAsFixed(2)} L/m²)',
        'Field Size': '${_guidedAreaController.text} $_guidedAreaUnit',
        'Total Water Volume': '${farmFormatNumber(totalLitres.round())} Litres (${totalM3.toStringAsFixed(1)} m³)',
      };
    });

    unawaited(
      FarmCalculatorHistoryService.save(
        calculatorType: 'irrigation',
        title: 'Crop Water Requirement (${_selectedCrop.name})',
        inputs: _exportReportData!,
        result: _result!,
        details: _details,
      ),
    );
  }

  void _calculateManual() {
    dismissCalculatorKeyboard();

    final area = farmNumber(_manualAreaController);
    final depth = farmNumber(_manualDepthController);
    final eff = farmNumber(_manualEfficiencyController);

    if (area == null || area <= 0 || depth == null || depth <= 0 || eff == null || eff <= 0 || eff > 100) {
      setState(() {
        _result = 'Enter valid values for field area, depth, and efficiency';
        _details = null;
      });
      return;
    }

    final hectares = _manualAreaUnit == 'Acres' ? area * 0.404686 : area;
    final netLitres = hectares * 10000.0 * depth;
    final requiredLitres = netLitres / (eff / 100.0);
    final requiredM3 = requiredLitres / 1000.0;

    setState(() {
      _result = '${farmFormatNumber(requiredLitres.round())} Litres (${requiredM3.toStringAsFixed(1)} m³)';
      _details =
          '📐 Specified Depth: ${depth.toStringAsFixed(2)} mm\n'
          '💧 Net Water Volume: ${farmFormatNumber(netLitres.round())} litres\n'
          '🚿 Gross Volume (${eff.toStringAsFixed(0)}% efficiency): ${farmFormatNumber(requiredLitres.round())} litres (${requiredM3.toStringAsFixed(1)} m³)\n'
          'Field Size: ${farmFormatNumber(area)} $_manualAreaUnit (${farmFormatNumber(hectares)} ha)';

      _exportReportData = {
        'Calculator Mode': 'Direct Depth → Volume (Manual)',
        'Field Size': '${_manualAreaController.text} $_manualAreaUnit',
        'Irrigation Depth': '${depth.toStringAsFixed(2)} mm',
        'System Efficiency': '${eff.toStringAsFixed(0)}%',
        'Total Gross Volume': '${farmFormatNumber(requiredLitres.round())} Litres (${requiredM3.toStringAsFixed(1)} m³)',
      };
    });

    unawaited(
      FarmCalculatorHistoryService.save(
        calculatorType: 'irrigation',
        title: 'Irrigation Volume (Manual Depth)',
        inputs: _exportReportData!,
        result: _result!,
        details: _details,
      ),
    );
  }

  void _export() {
    if (_exportReportData == null || _result == null) return;
    exportFarmReport(
      'Crop Water & Irrigation Report',
      _exportReportData!,
      _result!,
      _details,
    );
  }

  String _getStageName(CropGrowthStage stage) {
    switch (stage) {
      case CropGrowthStage.initial:
        return 'Initial / Seedling';
      case CropGrowthStage.development:
        return 'Vegetative Development';
      case CropGrowthStage.midSeason:
        return 'Mid-Season (Flowering/Fruiting)';
      case CropGrowthStage.lateSeason:
        return 'Late-Season (Ripening/Harvest)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FarmCalculatorLayout(
      calculatorType: 'irrigation',
      title: 'Crop Water & Irrigation',
      description:
          'Estimate daily crop water consumption (ETc) from live weather (ETo), FAO-56 crop factors, and rainfall offset.',
      note: 'Based on FAO-56 Irrigation and Drainage Paper guidelines for agricultural water requirements.',
      icon: Icons.water_drop,
      fields: [
        // Mode Selector Tabs
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMode = 0;
                      _result = null;
                      _details = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedMode == 0 ? farmGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '🌱 Crop Water (FAO-56)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedMode == 0 ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMode = 1;
                      _result = null;
                      _details = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedMode == 1 ? farmGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '📏 Manual Depth',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedMode == 1 ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // GUIDED MODE FIELDS
        if (_selectedMode == 0) ...[
          // Step 1: Crop Selection
          DropdownButtonFormField<CropWaterDemandProfile>(
            value: _selectedCrop,
            decoration: const InputDecoration(
              labelText: 'Step 1: Select Crop *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.grass, color: farmGreen),
            ),
            items: CropWaterDemandProfile.allCrops.map((c) {
              return DropdownMenuItem(
                value: c,
                child: Text('${c.emoji} ${c.name}'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedCrop = val;
                  // Set default recommended irrigation system
                  final matchingSystem = IrrigationSystemProfile.allSystems.firstWhere(
                    (s) => s.name.toLowerCase().contains(val.defaultIrrigation.toLowerCase()),
                    orElse: () => _selectedSystem,
                  );
                  _selectedSystem = matchingSystem;
                  _guidedEfficiencyController.text = matchingSystem.defaultEfficiency.toString();
                });
              }
            },
          ),
          const SizedBox(height: 12),

          // Step 2: Growth Stage Selection
          DropdownButtonFormField<CropGrowthStage>(
            value: _selectedStage,
            decoration: InputDecoration(
              labelText: 'Step 2: Growth Stage (Kc = ${_selectedCrop.getKcForStage(_selectedStage).toStringAsFixed(2)}) *',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.timeline, color: farmGreen),
            ),
            items: [
              DropdownMenuItem(
                value: CropGrowthStage.initial,
                child: Text('🌱 Initial / Seedling (Kc: ${_selectedCrop.kcIni.toStringAsFixed(2)})'),
              ),
              DropdownMenuItem(
                value: CropGrowthStage.development,
                child: Text('🌿 Vegetative Dev (Kc: ${_selectedCrop.kcDev.toStringAsFixed(2)})'),
              ),
              DropdownMenuItem(
                value: CropGrowthStage.midSeason,
                child: Text('🌸 Mid-Season Peak (Kc: ${_selectedCrop.kcMid.toStringAsFixed(2)})'),
              ),
              DropdownMenuItem(
                value: CropGrowthStage.lateSeason,
                child: Text('🍂 Late / Ripening (Kc: ${_selectedCrop.kcEnd.toStringAsFixed(2)})'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedStage = val);
            },
          ),
          const SizedBox(height: 12),

          // Step 3: Weather & ETo Sync Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.wb_sunny_outlined, color: Colors.blue.shade800, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Step 3: Weather & ETo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: _isFetchingWeather
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5),
                            )
                          : const Icon(Icons.my_location, size: 14),
                      label: Text(
                        _isFetchingWeather ? 'Syncing...' : 'Sync GPS Weather',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onPressed: _isFetchingWeather ? null : _fetchLiveWeatherETo,
                    ),
                  ],
                ),
                if (_weatherLocationNote != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _weatherLocationNote!,
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _etoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Reference ETo (mm/day)',
                          hintText: '5.0',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _rainfallController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Rainfall (mm)',
                          hintText: '0.0',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Step 4: Irrigation System & Efficiency
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<IrrigationSystemProfile>(
                  value: _selectedSystem,
                  decoration: const InputDecoration(
                    labelText: 'Step 4: Irrigation Method',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  items: IrrigationSystemProfile.allSystems.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.name, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedSystem = val;
                        _guidedEfficiencyController.text = val.defaultEfficiency.toString();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _guidedEfficiencyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Efficiency %',
                    hintText: '90',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Step 5: Field Area & Interval
          Row(
            children: [
              Expanded(
                flex: 3,
                child: FarmField(
                  label: 'Step 5: Field Size ($_guidedAreaUnit)',
                  controller: _guidedAreaController,
                  hint: 'e.g. 1.0',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    value: _guidedAreaUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Hectares', child: Text('Hectares')),
                      DropdownMenuItem(value: 'Acres', child: Text('Acres')),
                    ],
                    onChanged: (v) => setState(() => _guidedAreaUnit = v ?? 'Hectares'),
                  ),
                ),
              ),
            ],
          ),

          // Irrigation Interval Selector
          DropdownButtonFormField<int>(
            value: _intervalDays,
            decoration: const InputDecoration(
              labelText: 'Irrigation Interval / Frequency',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.repeat, color: farmGreen),
            ),
            items: const [
              DropdownMenuItem(value: 1, child: Text('Daily (Every 1 day)')),
              DropdownMenuItem(value: 2, child: Text('Every 2 days')),
              DropdownMenuItem(value: 3, child: Text('Every 3 days')),
              DropdownMenuItem(value: 5, child: Text('Every 5 days')),
              DropdownMenuItem(value: 7, child: Text('Weekly (Every 7 days)')),
            ],
            onChanged: (v) => setState(() => _intervalDays = v ?? 1),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _calculateGuided,
            icon: const Icon(Icons.calculate),
            label: const Text('Calculate Crop Water Requirement'),
            style: farmButtonStyle(),
          ),
        ] else ...[
          // MANUAL DEPTH MODE FIELDS
          FarmField(
            label: 'Field Size ($_manualAreaUnit)',
            controller: _manualAreaController,
            hint: 'e.g. 1.0',
          ),
          DropdownButtonFormField<String>(
            value: _manualAreaUnit,
            decoration: const InputDecoration(
              labelText: 'Area Unit',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Hectares', child: Text('Hectares')),
              DropdownMenuItem(value: 'Acres', child: Text('Acres')),
            ],
            onChanged: (v) => setState(() => _manualAreaUnit = v ?? 'Hectares'),
          ),
          const SizedBox(height: 12),
          FarmField(
            label: 'Irrigation Depth per Application (mm)',
            controller: _manualDepthController,
            hint: 'e.g. 25',
          ),
          FarmField(
            label: 'System Efficiency (%)',
            controller: _manualEfficiencyController,
            hint: 'e.g. 80',
          ),
          ElevatedButton.icon(
            onPressed: _calculateManual,
            icon: const Icon(Icons.calculate),
            label: const Text('Calculate Volume from Depth'),
            style: farmButtonStyle(),
          ),
        ],
      ],
      result: _result,
      resultDetails: _details,
      onExport: _result == null ? null : _export,
      exportLabel: 'Watch Ad & Export Irrigation PDF Report',
    );
  }
}

