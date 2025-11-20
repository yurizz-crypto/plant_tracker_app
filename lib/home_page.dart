import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_sample_page.dart';
import 'edit_sample_page.dart';

// Access the global Supabase client
final supabase = Supabase.instance.client;

/// The Dashboard/Home Screen.
/// 
/// Allows the user to:
/// 1. Navigate to Add Sample page.
/// 2. Input a Sample ID.
/// 3. Query details (Read).
/// 4. Navigate to Update page.
/// 5. Delete a sample.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Controller for the Sample ID input field.
  final _sampleIdController = TextEditingController();
  
  /// Stores feedback messages (errors, success, or query results) shown to the user.
  String _statusMessage = 'Enter a Sample ID to fetch, update, or delete.';

  /// Fetches a specific sample and its associated researcher.
  /// 
  /// Uses PostgREST syntax to perform a JOIN on 'researcher_info'.
  Future<void> querySample() async {
    final id = int.tryParse(_sampleIdController.text);
    if (id == null) {
      setState(() {
        _statusMessage = 'Please enter a valid number for Sample ID.';
      });
      return;
    }

    try {
      setState(() {
        _statusMessage = 'Querying...';
      });

      // Selecting specific columns and performing a relational join.
      // Syntax: 'researcher_info ( name, affiliation )' fetches related data 
      // from the foreign table.
      final data = await supabase
          .from('plant_sample_details')
          .select('''
            sample_id,
            date_of_sampling,
            details,
            location,
            researcher_info ( name, affiliation )
          ''')
          .eq('sample_id', id) // Filter by ID
          .single(); // Expecting exactly one result

      setState(() {
        _statusMessage = 'Found Sample: \n${data.toString()}';
      });
    } on PostgrestException catch (e) {
      // Handle Database specific errors (e.g., Not Found, Permission Denied)
      setState(() {
        _statusMessage = 'Error querying: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'An unknown error occurred: $e';
      });
    }
  }

  /// Validates ID and navigates to the Edit Page.
  Future<void> updateSample() async {
    final id = int.tryParse(_sampleIdController.text);
    if (id == null) {
      setState(() {
        _statusMessage = 'Please enter a valid number for Sample ID.';
      });
      return;
    }

    if (mounted) {
      // Pass the sampleID to the Edit page so it knows what to fetch
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditSamplePage(sampleId: id)),
      );
    }
  }

  /// Deletes a record from 'plant_sample_details'.
  /// 
  /// Note: Due to Cascade rules in the DB (if set), this might also delete
  /// entries in the 'sample_researcher' junction table.
  Future<void> deleteSample() async {
    final id = int.tryParse(_sampleIdController.text);
    if (id == null) {
      setState(() {
        _statusMessage = 'Please enter a valid number for Sample ID.';
      });
      return;
    }

    try {
      setState(() {
        _statusMessage = 'Deleting...';
      });

      await supabase
          .from('plant_sample_details')
          .delete()
          .eq('sample_id', id);

      setState(() {
        _statusMessage = 'Successfully deleted Sample ID: $id';
      });
    } on PostgrestException catch (e) {
      setState(() {
        _statusMessage = 'Error deleting: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'An unknown error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const double maxWidth = 600.0;
  
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Sample Tracker'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Navigation to Create Page ---
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    backgroundColor: Colors.lightGreen,
                    foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddSamplePage()),
                    );
                  },
                  child: const Text('Add New Sample'),
                ),
                const Divider(height: 30),
                
                // --- ID Input ---
                TextField(
                  controller: _sampleIdController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Sample ID',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                
                // --- Action Buttons (Query, Update, Delete) ---
                Wrap(
                  spacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: ElevatedButton(
                        onPressed: querySample,
                        style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black),
                        child: const Text('Query'),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: ElevatedButton(
                        onPressed: updateSample,
                        style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor:
                                const Color.fromARGB(255, 255, 179, 0)),
                        child: const Text('Update'),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: ElevatedButton(
                        onPressed: deleteSample,
                        style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor:
                                const Color.fromARGB(255, 240, 106, 97)),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // --- Status/Result Display ---
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}