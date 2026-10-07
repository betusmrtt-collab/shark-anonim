import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // ✅ Production-ready credentials (Anon key is public by design)
  static const String supabaseUrl = 'https://itgecaihhbyyrdwlmwoq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0Z2VjYWloaGJ5eXJkd2xtd29xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA4ODkwOTgsImV4cCI6MjEwNjQ2NTA5OH0.-fS7KSz1cv8VYzjm0L-CRxapBB4MknRZoACNCm97-lM';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
