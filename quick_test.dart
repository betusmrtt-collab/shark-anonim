import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  print('🔍 Supabase VDS Bağlantı Testi\n');
  
  const url = 'http://130.110.246.162:8000';
  const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzkxNzIyNDA0LCJleHAiOjE5NDk0MDI0MDR9.cblJHv1F4HPqMYIqcSOF7HxOAUXZ4gSmfZ-NYVsouYo';
  
  print('URL: $url');
  print('Key: ${key.substring(0, 50)}...\n');
  
  try {
    await Supabase.initialize(url: url, anonKey: key);
    print('✅ Supabase initialize başarılı\n');
    
    final client = Supabase.instance.client;
    
    // Test 1: Users sorgusu
    print('📋 Test 1: Users tablosu sorgulanıyor...');
    final users = await client.from('users').select('username, email').limit(3);
    print('✅ ${users.length} kullanıcı bulundu:');
    for (var user in users) {
      print('   • ${user['username']} - ${user['email']}');
    }
    
    // Test 2: User gallery sorgusu
    print('\n📋 Test 2: User Gallery sorgulanıyor...');
    final gallery = await client.from('user_gallery').select('image_url').limit(2);
    print('✅ ${gallery.length} galeri resmi bulundu');
    
    // Test 3: Auth durumu
    print('\n📋 Test 3: Auth durumu...');
    final session = client.auth.currentSession;
    if (session == null) {
      print('✅ Kullanıcı çıkış yapmış (normal)');
    } else {
      print('✅ Kullanıcı giriş yapmış: ${session.user.email}');
    }
    
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎉 TÜM TESTLER BAŞARILI!');
    print('✅ Uygulamanız VDS Supabase\'e bağlanmaya HAZIR!');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
  } catch (e) {
    print('\n❌ HATA OLUŞTU:');
    print('$e\n');
    print('Lütfen VDS Supabase\'in çalıştığından emin olun.');
  }
}
