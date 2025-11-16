import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class Researcher {
  final int id;
  final String name;
  Researcher({required this.id, required this.name});
}

class AddSamplePage extends StatefulWidget {
  const AddSamplePage({super.key});

  @override
  State<AddSamplePage> createState() => _AddSamplePageState();
}

class _AddSamplePageState extends State<AddSamplePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _loadingMessage = 'Loading...';

  final _heightController = TextEditingController();
  final _soilPhController = TextEditingController();
  final _humidityController = TextEditingController();

  Researcher? _selectedResearcher;
  String? _selectedSpecies;

  List<Researcher> _researcherList = [];
  final List<String> _speciesList = [
    'Acacia', 'Mahogany', 'Narra', 'Oak', 'Pine',
    'Maple', 'Gmelina', 'Eucalyptus', 'Teak', 'Bamboo'
  ];

  @override
  void initState() {
    super.initState();
    _fetchResearchers();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _soilPhController.dispose();
    _humidityController.dispose();
    super.dispose();
  }

  Future<void> _fetchResearchers() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Fetching researchers...';
    });
    try {
      final data = await supabase
          .from('researcher_info')
          .select('researcher_id, name');

      final List<Researcher> loadedResearchers = data.map((item) {
        return Researcher(
          id: item['researcher_id'],
          name: item['name'],
        );
      }).toList();

      setState(() {
        _researcherList = loadedResearchers;
        _isLoading = false;
      });
    } catch (e) {
      _showError('Error fetching researchers: ${e.toString()}');
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Saving data...';
    });

    try {
      setState(() { _loadingMessage = 'Getting location...'; });
      final Position position = await _getCurrentLocation();

      final int selectedResearcherId = _selectedResearcher!.id;
      final String currentDate = DateTime.now().toIso8601String();
      final double? height = double.tryParse(_heightController.text);
      final double? soilPh = double.tryParse(_soilPhController.text);
      final String humidity = _humidityController.text;

      final Map<String, dynamic> detailsMap = {
        'species': _selectedSpecies,
        'height_cm': height,
      };
      final Map<String, dynamic> locationMap = {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
      final Map<String, dynamic> conditionsMap = {
        'soil_ph': soilPh,
        'humidity': humidity,
      };

      setState(() { _loadingMessage = 'Inserting sample...'; });
      final sample = await supabase
          .from('plant_sample_details')
          .insert({
            'date_of_sampling': currentDate,
            'details': detailsMap,
            'location': locationMap,
            'conditions': conditionsMap,
          })
          .select()
          .single();
          
      final int newSampleId = sample['sample_id'];

      setState(() { _loadingMessage = 'Linking researcher...'; });
      await supabase.from('sample_researcher').insert({
        'sample_id': newSampleId,
        'researcher_id': selectedResearcherId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added Sample ID: $newSampleId'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const double maxWidth = 600.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Sample'),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  Text(_loadingMessage ?? 'Loading...'),
                ],
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxWidth),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      DropdownButtonFormField<Researcher>(
                        initialValue: _selectedResearcher,
                        decoration: const InputDecoration(
                          labelText: 'Researcher',
                          border: OutlineInputBorder(),
                        ),
                        items: _researcherList.map((researcher) {
                          return DropdownMenuItem(
                            value: researcher,
                            child: Text(researcher.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedResearcher = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a researcher.' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSpecies,
                        decoration: const InputDecoration(
                          labelText: 'Species',
                          border: OutlineInputBorder(),
                        ),
                        items: _speciesList.map((species) {
                          return DropdownMenuItem(
                            value: species,
                            child: Text(species),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSpecies = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a species.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _heightController,
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
                        ],
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Please enter a height.' : null,
                      ),
                      const SizedBox(height: 16),
                      Text('Sample Conditions',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _soilPhController,
                        decoration: const InputDecoration(
                          labelText: 'Soil pH',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _humidityController,
                        decoration: const InputDecoration(
                          labelText: 'Humidity (e.g., 80%)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _submitData,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.lightGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Submit Sample',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}