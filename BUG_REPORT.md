# 🔴 KRİTİK BUG RAPORU

**Tarih:** 2026-10-04  
**Kapsam:** Sadece Yüksek ve Kritik Seviye Sorunlar  
**Durum:** Güncel

---

## 📊 ÖZET

| Kategori | Kritik | Yüksek | Toplam |
|----------|--------|--------|--------|
| 🔴 Fonksiyonel | 1 | 2 | 3 |
| 🔒 Güvenlik | 0 | 3 | 3 |
| ⚡ Performans | 0 | 0 | 0 |
| **TOPLAM** | **1** | **5** | **6** |

---

# 🔴 KRİTİK SORUNLAR (1)

## 1. **Ana Sayfa Boş - Uygulama Kullanılamaz**
- **Dosya:** `lib/home_screen.dart`
- **Satır:** 42-222
- **Durum:** 🔴 Aktif
- **Problem:** 
  - Sadece "Hoş Geldin" mesajı + kullanıcı bilgisi gösteriliyor
  - Post feed yok
  - Post oluşturma yok
  - Profil görüntüleme yok
  - Etkileşim özellikleri yok
- **Etki:** Sosyal medya uygulaması hiçbir sosyal özellik sunmuyor
- **Çözüm:** 
  - Post feed ekranı oluştur
  - Post oluşturma ekranı ekle
  - Profil görüntüleme ekle
  - Etkileşim özellikleri (like, comment, share) ekle

---

# ⚠️ YÜKSEK SEVİYE SORUNLAR (5)

## 2. **Supabase RLS (Row Level Security) Kontrol Edilmedi**
- **Risk Seviyesi:** 🔴 Kritik
- **Kategori:** Güvenlik
- **Durum:** ⚠️ Bilinmiyor
- **Problem:** 
  - `users` tablosu RLS politikaları test edilmedi
  - `user_gallery` tablosu RLS politikaları test edilmedi
  - Storage buckets (`avatars`, `voice_bios`, `gallery`) izinleri kontrol edilmedi
- **Etki:** 
  - RLS yoksa herkes herkesi okuyabilir/değiştirebilir
  - Kullanıcı başkasının profilini değiştirebilir
  - Başkasının fotoğraflarını silebilir
- **Test:**
```sql
-- Supabase SQL Editor'de çalıştır:
SELECT tablename, policyname, permissive, roles, cmd 
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('users', 'user_gallery');

-- Storage bucket politikaları:
SELECT * FROM storage.policies 
WHERE bucket_id IN ('avatars', 'voice_bios', 'gallery');
```
- **Beklenen RLS:**
```sql
-- users tablosu
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own data"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own data"
  ON users FOR UPDATE
  USING (auth.uid() = id);

-- user_gallery tablosu
ALTER TABLE user_gallery ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own gallery"
  ON user_gallery FOR ALL
  USING (auth.uid() = user_id);

-- Storage buckets
CREATE POLICY "Users can upload own files"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id IN ('avatars', 'voice_bios', 'gallery') 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
```

## 3. **Rate Limiting Yok - Brute Force Açık**
- **Risk Seviyesi:** 🔴 Yüksek
- **Kategori:** Güvenlik
- **Durum:** 🔴 Aktif
- **Dosyalar:** `login_screen.dart`, `giris_screen.dart`, `forgot_password_screen.dart`
- **Problem:** 
  - Sınırsız giriş denemesi
  - Sınırsız kayıt denemesi
  - Sınırsız şifre sıfırlama maili
- **Etki:**
  - Brute force şifre tahmini
  - Email/SMS bombing
  - DDoS saldırısı
- **Çözüm:** Supabase Edge Functions ile rate limit:
```typescript
// supabase/functions/rate-limit/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const rateLimits = new Map();

serve(async (req) => {
  const ip = req.headers.get('x-forwarded-for');
  const now = Date.now();
  const key = `${ip}:${req.url}`;
  
  const attempts = rateLimits.get(key) || [];
  const recentAttempts = attempts.filter(t => now - t < 60000); // 1 dakika
  
  if (recentAttempts.length >= 5) {
    return new Response('Too many requests', { status: 429 });
  }
  
  rateLimits.set(key, [...recentAttempts, now]);
  return new Response('OK');
});
```

## 4. **Session Timeout Yok - Güvenlik Riski**
- **Risk Seviyesi:** 🟡 Orta-Yüksek
- **Kategori:** Güvenlik
- **Durum:** 🔴 Aktif
- **Dosya:** `auth_service.dart`
- **Problem:** Kullanıcı süresiz oturum açık kalabiliyor
- **Etki:** 
  - Paylaşılan cihazlarda gizlilik ihlali
  - Unutulan cihazlarda hesap açık kalır
- **Çözüm:**
```dart
// auth_service.dart
class AuthService {
  Timer? _sessionTimer;
  static const _sessionTimeout = Duration(minutes: 30);

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_sessionTimeout, () {
      signOut();
      // Show timeout dialog
    });
  }

  void _resetSessionTimer() {
    _startSessionTimer();
  }

  // Her user interaction'da çağır
  void keepAlive() {
    _resetSessionTimer();
  }
}
```

## 5. **Loading State Eksik - Çift Tıklama**
- **Risk Seviyesi:** 🟡 Orta-Yüksek
- **Kategori:** Fonksiyonel
- **Durum:** 🔴 Aktif
- **Dosyalar:** 
  - `create_profile_screen.dart:236` (Kaydet butonu)
  - `giris_screen.dart:987` (Kayıt butonu)
  - `login_screen.dart:51` (Giriş butonu)
- **Problem:** Butonlara çift tıklanabilir
- **Etki:**
  - Duplicate kayıt (aynı kullanıcı 2 kez)
  - Storage'da duplicate dosyalar (avatar/galeri 2 kez yüklenir)
  - Veritabanında duplicate data
- **Çözüm:**
```dart
bool _isLoading = false;

Future<void> _saveProfile() async {
  if (_isLoading) return; // ✅ Çift tıklamayı engelle
  
  setState(() => _isLoading = true);
  
  try {
    // ... işlemler
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

// Button
ElevatedButton(
  onPressed: _isLoading ? null : _saveProfile, // ✅ Disable when loading
  child: _isLoading 
      ? CircularProgressIndicator() 
      : Text('Kaydet'),
)
```

## 6. **Back Button - Data Loss**
- **Risk Seviyesi:** 🟡 Orta-Yüksek
- **Kategori:** Fonksiyonel
- **Durum:** 🔴 Aktif
- **Dosya:** `create_profile_screen.dart`
- **Problem:** 
  - Profil oluştururken geri tuşuna basınca veri kayboluyor
  - Onay dialog yok
  - `WillPopScope` yok
- **Etki:** 
  - Kullanıcı yanlışlıkla geri basınca tüm değişiklikler kaybolur
  - Yeniden doldurmak zorunda kalır
- **Çözüm:**
```dart
@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      // Değişiklik var mı kontrol et
      bool hasChanges = _avatarImage != null || 
                        _galleryImages.isNotEmpty || 
                        _bioController.text.trim().isNotEmpty;
      
      if (!hasChanges) return true;
      
      // Onay dialog göster
      return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Değişiklikler Kaydedilmedi'),
          content: Text('Çıkmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              child: Text('Hayır'),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: Text('Evet, Çık'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ) ?? false;
    },
    child: Scaffold(...),
  );
}
```

---

# ✅ ÇÖZÜLMÜŞ SORUNLAR

Aşağıdaki kritik sorunlar daha önce çözülmüştür:

- ✅ SQL Injection (Username, Email, Bio, Hashtag)
- ✅ XSS (Biyografi, Hashtag)
- ✅ Zararlı Dosya Yükleme (Avatar, Galeri)
- ✅ MIME Type Spoofing
- ✅ Large File DoS
- ✅ PII (Personally Identifiable Information) Loglama
- ✅ Galeri Paralel Upload (Performans)

---

# 📋 ÖNCELİK SIRASI

## 🔴 Acil (Bu Hafta)
1. **Supabase RLS kontrol et ve aktifleştir** (#2)
2. **Loading states ekle** (#5)
3. **Back button protection ekle** (#6)

## 🟡 Yüksek (Bu Ay)
4. **Ana sayfa post feed oluştur** (#1)
5. **Rate limiting ekle** (#3)
6. **Session timeout ekle** (#4)

---

# 🎯 HIZLI AKSİYON PLANI

## Adım 1: RLS Kontrol (10 dakika)
```bash
# Supabase Dashboard → SQL Editor
# Yukarıdaki SQL komutlarını çalıştır
# Eğer boş dönerse RLS YOK → Acil aktifleştir
```

## Adım 2: Loading States (30 dakika)
```dart
// 3 dosyada bool _isLoading = false; ekle
// Button'larda onPressed: _isLoading ? null : _handler kullan
```

## Adım 3: Back Button (20 dakika)
```dart
// WillPopScope ekle
// Dialog ekle
```

---

**SON GÜNCELLEME:** 2026-10-04  
**TOPLAM KRİTİK/YÜKSEK:** 6 sorun  
**ÇÖZÜM SÜRESİ:** ~1 saat (RLS hariç)
