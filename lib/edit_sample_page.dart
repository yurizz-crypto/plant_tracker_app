import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class Researcher {
  final int id;
  final String name;
  Researcher({required this.id, required this.name});
}

class EditSamplePage extends StatefulWidget {
  final int sampleId;
  const EditSamplePage({super.key, required this.sampleId});

  @override
  State<EditSamplePage> createState() => _EditSamplePageState();
}

class _EditSamplePageState extends State<EditSamplePage> {
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
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Fetching researchers...';
    });
    await _fetchResearchers();
    
    if (_researcherList.isNotEmpty) {
      setState(() { _loadingMessage = 'Fetching sample data...'; });
      await _fetchSampleData();
    }
    
    setState(() { _isLoading = false; });
  }

  @override
  void dispose() {
    _heightController.dispose();
    _soilPhController.dispose();
    _humidityController.dispose();
    super.dispose();
  }

  Future<void> _fetchResearchers() async {
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
      });
    } catch (e) {
      _showError('Error fetching researchers: ${e.toString()}');
    }
  }

  Future<void> _fetchSampleData() async {
    try {
      final data = await supabase
          .from('plant_sample_details')
          .select('''
            details,
            conditions,
            sample_researcher ( researcher_id )
          ''')
          .eq('sample_id', widget.sampleId)
          .single();

      final details = data['details'];
      final conditions = data['conditions'];
      
      if (data['sample_researcher'] == null || (data['sample_researcher'] as List).isEmpty) {
        throw Exception('No researcher linked to this sample.');
      }
      final int researcherId = data['sample_researcher'][0]['researcher_id'];

      _heightController.text = (details?['height_cm'] ?? '').toString();
      _soilPhController.text = (conditions?['soil_ph'] ?? '').toString();
      _humidityController.text = conditions?['humidity'] ?? '';
      _selectedSpecies = details?['species'];

      _selectedResearcher = _researcherList.firstWhere(
        (r) => r.id == researcherId,
      );

    } catch (e) {
      _showError('Error fetching sample data: ${e.toString()}');
    }
  }

  Future<void> _updateData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Updating data...';
    });

    try {
      final int selectedResearcherId = _selectedResearcher!.id;
      final double? height = double.tryParse(_heightController.text);
      final double? soilPh = double.tryParse(_soilPhController.text);
      final String humidity = _humidityController.text;

      final Map<String, dynamic> detailsMap = {
        'species': _selectedSpecies,
        'height_cm': height,
      };
      final Map<String, dynamic> conditionsMap = {
        'soil_ph': soilPh,
        'humidity': humidity,
      };

      setState(() { _loadingMessage = 'Updating sample...'; });
      await supabase
          .from('plant_sample_details')
          .update({
            'details': detailsMap,
            'conditions': conditionsMap,
          })
          .eq('sample_id', widget.sampleId);
          
      setState(() { _loadingMessage = 'Updating researcher link...'; });
      await supabase
        .from('sample_researcher')
        .update({ 'researcher_id': selectedResearcherId })
        .eq('sample_id', widget.sampleId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully updated Sample ID: ${widget.sampleId}'),
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
        title: const Text('Edit Sample'),
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
                        onPressed: _updateData,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Submit Update',
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