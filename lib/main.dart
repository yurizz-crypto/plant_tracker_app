import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_page.dart'; 

/// The entry point of the application.
/// 
/// This function ensures Flutter bindings are initialized and establishes
/// the connection to the Supabase backend before running the UI.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize Supabase with Project URL and Anon Key.
  /// 
  /// Note: In production, keys are usually stored in environment variables (.env)
  /// rather than hardcoded.
  await Supabase.initialize(
    url: 'https://szwhtbhwbrenvgaoegpi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6d2h0Ymh3YnJlbnZnYW9lZ3BpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMyOTY5NjUsImV4cCI6MjA3ODg3Mjk2NX0.mmdCTM5wzsdnZviunsQMX2Hn8oR1j6zbF-c4jNOycDs',
  );
  
  runApp(const MyApp());
}

/// Global Supabase client instance used throughout the app.
final supabase = Supabase.instance.client;

/// The Root Widget.
/// 
/// Sets the application title, applies the Material 3 theme with a Green swatch
/// (fitting for a plant tracker), and sets the [HomePage] as the initial route.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Sample Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomePage(), 
    );
  }
}