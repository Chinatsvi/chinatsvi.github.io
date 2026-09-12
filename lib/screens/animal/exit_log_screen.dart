import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/animal/exit_record.dart';
import 'package:agribased/services/animal/animal_repository_interface.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';

class ExitLogScreen extends StatefulWidget {
  final Animal animal;
  final AnimalRepository repository;
  final ValueChanged<Animal>? onAnimalUpdated;
  const ExitLogScreen({
    super.key,
    required this.animal,
    required this.repository,
    this.onAnimalUpdated,
  });

  @override
  State<ExitLogScreen> createState() => _ExitLogScreenState();
}

class _ExitLogScreenState extends State<ExitLogScreen> {
  List<ExitRecord> _records = [];
  List<String> _knownTags = [];
  late Animal _currentAnimal;

  @override
  void initState() {
    super.initState();
    _currentAnimal = widget.animal;
    _load();
  }

  @override
  void didUpdateWidget(covariant ExitLogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animal != widget.animal) {
      _currentAnimal = widget.animal;
    }
  }

  Future<void> _load() async {
    final list = await widget.repository.listExitRecords(_currentAnimal.id);
    final milkList = await widget.repository.listMilkProductionRecords(_currentAnimal.id);
    final tagSet = <String>{};
    for (final m in milkList) {
      if (m.cowIdentifier != null && m.cowIdentifier!.isNotEmpty && m.cowIdentifier != 'Herd') {
        tagSet.add(m.cowIdentifier!);
      }
    }
    for (final e in list) {
      if (e.animalTag != null && e.animalTag!.isNotEmpty) {
        tagSet.add(e.animalTag!);
      }
    }
    if (tagSet.isEmpty) {
      tagSet.addAll(['Cattle A', 'Cattle B', 'Cattle 1', 'Cattle 2']);
    }

    if (mounted) {
      setState(() {
        _records = list;
        _knownTags = tagSet.toList();
      });
    }
  }

  Future<void> _addExitRecord() async {
    String selectedReason = 'sale';
    String selectedSex = _currentAnimal.sex?.toLowerCase() == 'male'
        ? 'Male'
        : (_currentAnimal.sex?.toLowerCase() == 'female'
            ? 'Female'
            : (_currentAnimal.totalMales > 0 && _currentAnimal.totalFemales == 0
                ? 'Male'
                : (_currentAnimal.totalFemales > 0 && _currentAnimal.totalMales == 0
                    ? 'Female'
                    : 'Female')));

    final tagCtrl = TextEditingController();
    final quantityCtrl = TextEditingController(text: '1');
    final femaleQtyCtrl = TextEditingController(text: '1');
    final maleQtyCtrl = TextEditingController(text: '0');
    final priceCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<ExitRecord>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasBothGenders = _currentAnimal.totalMales > 0 && _currentAnimal.totalFemales > 0;

            return AlertDialog(
              title: const Text('Add Exit / Mortality Record'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Cattle / Animal Tag
                      TextFormField(
                        controller: tagCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Animal Tag / Cattle Name (e.g. Cattle A)',
                          hintText: 'e.g. Cattle A, Cattle 1, Cow #12',
                          helperText: 'Identifies which individual cow is removed',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tag, color: Colors.amber),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 6),
                      if (_knownTags.isNotEmpty) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const Text('Suggestions: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ..._knownTags.map(
                                (tag) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ActionChip(
                                    label: Text(tag, style: const TextStyle(fontSize: 11)),
                                    onPressed: () {
                                      setDialogState(() {
                                        tagCtrl.text = tag;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      DropdownButtonFormField<String>(
                        initialValue: selectedReason,
                        items: const [
                          DropdownMenuItem(value: 'sale', child: Text('Sale')),
                          DropdownMenuItem(value: 'mortality', child: Text('Mortality (Death)')),
                          DropdownMenuItem(value: 'slaughter', child: Text('Slaughter / Meat')),
                          DropdownMenuItem(value: 'transfer', child: Text('Transferred / Gifted')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedReason = val);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Reason for Exit',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      /// Gender / Type of animal removed
                      DropdownButtonFormField<String>(
                        initialValue: selectedSex,
                        items: [
                          const DropdownMenuItem(value: 'Female', child: Text('Female')),
                          const DropdownMenuItem(value: 'Male', child: Text('Male')),
                          if (hasBothGenders || _currentAnimal.sex == 'Mixed')
                            const DropdownMenuItem(value: 'Mixed', child: Text('Mixed (Males & Females)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedSex = val;
                              if (val == 'Female') {
                                femaleQtyCtrl.text = quantityCtrl.text;
                                maleQtyCtrl.text = '0';
                              } else if (val == 'Male') {
                                maleQtyCtrl.text = quantityCtrl.text;
                                femaleQtyCtrl.text = '0';
                              }
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Animal Type / Sex Removed',
                          border: OutlineInputBorder(),
                          helperText: 'Maintains accuracy for milk production',
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (selectedSex == 'Mixed') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: maleQtyCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Males Removed',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.male, color: Colors.blue),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                onChanged: (_) {
                                  final m = int.tryParse(maleQtyCtrl.text) ?? 0;
                                  final f = int.tryParse(femaleQtyCtrl.text) ?? 0;
                                  quantityCtrl.text = (m + f).toString();
                                },
                                validator: (v) {
                                  final val = int.tryParse(v ?? '') ?? 0;
                                  if (val < 0) return 'Invalid';
                                  if (val > _currentAnimal.totalMales) {
                                    return 'Max ${_currentAnimal.totalMales}';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: femaleQtyCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Females Removed',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.female, color: Colors.pink),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                onChanged: (_) {
                                  final m = int.tryParse(maleQtyCtrl.text) ?? 0;
                                  final f = int.tryParse(femaleQtyCtrl.text) ?? 0;
                                  quantityCtrl.text = (m + f).toString();
                                },
                                validator: (v) {
                                  final val = int.tryParse(v ?? '') ?? 0;
                                  if (val < 0) return 'Invalid';
                                  if (val > _currentAnimal.totalFemales) {
                                    return 'Max ${_currentAnimal.totalFemales}';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        TextFormField(
                          controller: quantityCtrl,
                          decoration: InputDecoration(
                            labelText: 'Number of ${selectedSex.toLowerCase()} animals removed',
                            border: const OutlineInputBorder(),
                            helperText: selectedSex == 'Female'
                                ? 'Available females: ${_currentAnimal.totalFemales}'
                                : 'Available males: ${_currentAnimal.totalMales}',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            final val = int.tryParse(value ?? '');
                            if (val == null || val <= 0) return 'Enter quantity > 0';
                            if (selectedSex == 'Female' && val > _currentAnimal.totalFemales) {
                              return 'Exceeds female count (${_currentAnimal.totalFemales})';
                            }
                            if (selectedSex == 'Male' && val > _currentAnimal.totalMales) {
                              return 'Exceeds male count (${_currentAnimal.totalMales})';
                            }
                            if (val > _currentAnimal.totalCount) {
                              return 'Exceeds total count (${_currentAnimal.totalCount})';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (selectedReason == 'sale') ...[
                        TextField(
                          controller: priceCtrl,
                          decoration: InputDecoration(
                            labelText: 'Total Sale Price (${_currentAnimal.currencySymbol})',
                            border: const OutlineInputBorder(),
                            helperText: 'Revenue will be counted in Profit tab',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      TextField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;

                    int totalQty = 1;
                    int? maleQty;
                    int? femaleQty;

                    if (selectedSex == 'Mixed') {
                      maleQty = int.tryParse(maleQtyCtrl.text.trim()) ?? 0;
                      femaleQty = int.tryParse(femaleQtyCtrl.text.trim()) ?? 0;
                      totalQty = maleQty + femaleQty;
                      if (totalQty <= 0) return;
                    } else if (selectedSex == 'Female') {
                      totalQty = int.tryParse(quantityCtrl.text.trim()) ?? 1;
                      femaleQty = totalQty;
                      maleQty = 0;
                    } else if (selectedSex == 'Male') {
                      totalQty = int.tryParse(quantityCtrl.text.trim()) ?? 1;
                      maleQty = totalQty;
                      femaleQty = 0;
                    }

                    final record = ExitRecord(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      animalId: _currentAnimal.id,
                      date: DateTime.now(),
                      reason: selectedReason,
                      quantity: totalQty,
                      animalTag: tagCtrl.text.trim().isNotEmpty ? tagCtrl.text.trim() : null,
                      sex: selectedSex,
                      maleQuantity: maleQty,
                      femaleQuantity: femaleQty,
                      salePrice: priceCtrl.text.isNotEmpty
                          ? double.tryParse(priceCtrl.text.trim())
                          : null,
                      notes: notesCtrl.text.isNotEmpty ? notesCtrl.text.trim() : null,
                    );
                    Navigator.pop(context, record);
                  },
                  child: const Text('Save Record', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await widget.repository.addExitRecord(result);

      final tag = result.animalTag?.trim();
      if (tag != null && tag.isNotEmpty) {
        final milkRecords = await widget.repository
            .listMilkProductionRecords(result.animalId);
        final normalizedTag = tag.toLowerCase();
        final matchingRecords = milkRecords.where(
          (record) =>
              record.cowIdentifier?.trim().toLowerCase() == normalizedTag,
        );
        await Future.wait(
          matchingRecords.map(
            (record) => widget.repository.deleteMilkProductionRecord(
              result.animalId,
              record.id,
            ),
          ),
        );
      }

      final updatedAnimal = _currentAnimal.applyExit(
        quantity: result.quantity,
        maleQuantity: result.maleQuantity,
        femaleQuantity: result.femaleQuantity,
        removedSex: result.sex,
      );

      await widget.repository.updateAnimal(updatedAnimal);

      if (mounted) {
        setState(() => _currentAnimal = updatedAnimal);
        widget.onAnimalUpdated?.call(updatedAnimal);
        final tagText = result.animalTag != null ? ' [${result.animalTag}]' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.reason.toUpperCase()}$tagText recorded (${result.quantity} ${result.sex ?? ''} removed). Remaining: ${updatedAnimal.totalCount} (Females: ${updatedAnimal.totalFemales})',
            ),
          ),
        );
      }
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const FarmBannerAd(),
      body: _records.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.output, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No exit records yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      'Total Animals: ${_currentAnimal.totalCount} (Females: ${_currentAnimal.totalFemales}, Males: ${_currentAnimal.totalMales})',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    const FarmNativeAd(),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _records.length + 1,
              itemBuilder: (context, i) {
                if (i == _records.length) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 60),
                    child: FarmNativeAd(),
                  );
                }
                final r = _records[i];
                final isMortality = r.reason.toLowerCase().contains('mortality');
                final sexLabel = r.sex != null ? ' • ${r.sex}' : '';
                final breakdown = (r.femaleQuantity != null || r.maleQuantity != null)
                    ? ' (${r.femaleQuantity ?? 0}F, ${r.maleQuantity ?? 0}M)'
                    : '';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isMortality ? Colors.red.shade100 : Colors.green.shade100,
                      child: Icon(
                        isMortality ? Icons.close : Icons.sell,
                        color: isMortality ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${r.reason.toUpperCase()} - ${r.quantity} animal(s)$breakdown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (r.animalTag != null && r.animalTag!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber.shade400),
                            ),
                            child: Text(
                              r.animalTag!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      '${r.date.toLocal().toString().split(" ").first}$sexLabel${r.notes != null ? '\n${r.notes}' : ''}',
                    ),
                    trailing: r.salePrice != null
                        ? Text(
                            '${_currentAnimal.currencySymbol}${r.salePrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExitRecord,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

