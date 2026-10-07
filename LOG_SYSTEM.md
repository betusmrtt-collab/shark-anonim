# Log Sistemi Dokümantasyonu

## ✅ Kurulum Tamamlandı

Merkezi log yönetim sistemi **AppLogger** oluşturuldu ve tüm proje genelinde entegre edildi.

## 📋 Özellikler

### Log Seviyeleri
- **DEBUG** 🔍 - Geliştirme aşamasında detaylı bilgiler
- **INFO** ℹ️ - Genel bilgilendirme mesajları  
- **WARNING** ⚠️ - Uyarılar
- **ERROR** ❌ - Hatalar (stack trace ile)
- **SUCCESS** ✅ - Başarılı işlemler

### Kategori Bazlı Logger'lar
```dart
AppLogger.auth       // Kimlik doğrulama işlemleri
AppLogger.database   // Veritabanı işlemleri
AppLogger.ui         // UI olayları
AppLogger.network    // Ağ istekleri
AppLogger.storage    // Dosya yükleme/indirme
```

## 📝 Kullanım Örnekleri

### Basit Kullanım
```dart
import '../utils/logger.dart';

// Debug log
AppLogger.debug('Kullanıcı verisi yükleniyor...');

// Info log
AppLogger.info('Uygulama başlatıldı');

// Warning log
AppLogger.warning('API yanıt süresi yavaş');

// Error log
AppLogger.error('Veri yüklenemedi', 'TAG', error, stackTrace);

// Success log
AppLogger.success('Profil kaydedildi');
```

### Kategori ile Kullanım
```dart
// Auth işlemleri
AppLogger.auth.success('Kullanıcı girişi başarılı: user@example.com');
AppLogger.auth.error('Giriş hatası', error);

// Database işlemleri
AppLogger.database.info('Profil kaydetme işlemi başlatıldı');
AppLogger.database.success('Profil başarıyla kaydedildi');

// Storage işlemleri
AppLogger.storage.info('Avatar yükleniyor...');
AppLogger.storage.success('Avatar yüklendi: avatar_123.jpg');

// UI işlemleri
AppLogger.ui.warning('Profil kaydedilemedi: Boş biyografi');
AppLogger.ui.success('Kullanıcı bilgisi yüklendi: @username');
```

## 🔧 İleri Seviye Özellikler

### Log Geçmişi
```dart
// Tüm logları getir
final logs = AppLogger.getHistory();

// Log geçmişini temizle
AppLogger.clearHistory();

// Logları dosyaya kaydet
final filePath = await AppLogger.exportLogs();
// Dosya: /tmp/anonim_logs_2026-10-04T08-12-21.txt
```

### Log Boyutu
- Otomatik olarak son **1000 log** saklanır
- Eski loglar otomatik silinir

### Production Modu
```dart
// logger.dart içinde
static const bool _enableLogs = false; // Production'da false
```

## 📍 Entegre Edilen Dosyalar

### 1. Auth Service (`lib/services/auth_service.dart`)
- ✅ Kayıt işlemleri
- ✅ Giriş işlemleri
- ✅ Çıkış işlemleri
- ✅ Şifre sıfırlama

**Loglar:**
```
✅ SUCCESS [AUTH] Kullanıcı kaydı başarılı: username
✅ SUCCESS [AUTH] Kullanıcı girişi başarılı: user@example.com
❌ ERROR [AUTH] Giriş hatası
  Error: Invalid credentials
```

### 2. Create Profile Screen (`lib/screens/create_profile_screen.dart`)
- ✅ Profil yükleme
- ✅ Avatar yükleme
- ✅ Sesli biyografi yükleme
- ✅ Galeri yükleme
- ✅ Profil kaydetme

**Loglar:**
```
ℹ️ INFO [DATABASE] Profil kaydetme işlemi başlatıldı
🔍 DEBUG [DATABASE] User ID: abc-123-def
ℹ️ INFO [STORAGE] Avatar yükleniyor...
✅ SUCCESS [STORAGE] Avatar yüklendi: avatar_abc-123-def.jpg
ℹ️ INFO [STORAGE] Galeri resimleri yükleniyor: 3 adet
✅ SUCCESS [STORAGE] Galeri resimleri yüklendi: 3 adet
✅ SUCCESS [DATABASE] Profil başarıyla kaydedildi
```

## 🎯 Örnek Console Çıktısı

```
08:12:21.123 ℹ️ INFO [AUTH] Kullanıcı kaydı başlıyor
08:12:21.456 ✅ SUCCESS [AUTH] Kullanıcı kaydı başarılı: johndoe
08:12:22.789 ℹ️ INFO [UI] Kullanıcı bilgisi yükleniyor
08:12:23.012 ✅ SUCCESS [UI] Kullanıcı bilgisi yüklendi: @johndoe
08:12:25.345 ℹ️ INFO [DATABASE] Profil kaydetme işlemi başlatıldı
08:12:25.456 ℹ️ INFO [STORAGE] Avatar yükleniyor...
08:12:26.789 ✅ SUCCESS [STORAGE] Avatar yüklendi: avatar_123.jpg
08:12:27.012 ✅ SUCCESS [DATABASE] Profil başarıyla kaydedildi
```

## 🚀 Performans

- **Zero overhead** production modda (kDebugMode kontrolü)
- Asenkron olmayan log yazma (blocking değil)
- Maksimum 1000 log bellekte tutulur
- Timestamp formatı: `HH:MM:SS.mmm`

## 📦 Dosya Yapısı

```
lib/
  utils/
    logger.dart          # Ana log sistemi
  services/
    auth_service.dart    # ✅ Logger entegre
  screens/
    create_profile_screen.dart  # ✅ Logger entegre
```

## ⚡ Hızlı Başlangıç

1. **Import et:**
```dart
import '../utils/logger.dart';
```

2. **Kullan:**
```dart
AppLogger.info('İşlem başlatıldı');
AppLogger.auth.success('Başarılı!');
AppLogger.error('Hata oluştu', 'TAG', error);
```

3. **Test et:**
```bash
flutter run
# Console'da renkli logları göreceksin
```

---

**Oluşturulma Tarihi:** 2026-10-04  
**Versiyon:** 1.0.0  
**Durum:** ✅ Aktif ve Çalışıyor
