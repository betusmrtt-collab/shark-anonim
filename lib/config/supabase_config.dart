import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // ✅ VDS Self-hosted Supabase credentials (Updated: Oct 12, 2026)
  static const String supabaseUrl = 'http://130.110.246.162:8000';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzkxNzIyNDA0LCJleHAiOjE5NDk0MDI0MDR9.cblJHv1F4HPqMYIqcSOF7HxOAUXZ4gSmfZ-NYVsouYo';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
