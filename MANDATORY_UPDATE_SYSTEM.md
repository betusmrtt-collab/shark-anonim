# Zorunlu Güncelleme Sistemi

## 📋 Genel Bakış

Kullanıcıların her zaman en güncel versiyonu kullanmasını sağlayan, performansı etkilemeyen zorunlu güncelleme sistemi.

## ✨ Özellikler

### 1. ⚡ Performanslı Kontrol
- **Cache Sistemi:** 5 dakikalık akıllı cache ile GitHub API'ye gereksiz istekler yapılmaz
- **Timeout Koruması:** 5 saniye içinde cevap gelmezse cache'den devam eder
- **Arka Plan Çalışma:** UI thread'i bloklamadan güncelleme kontrolü yapar
- **Optimizasyon:** İlk açılışta 1-2 saniye gecikmeyle kontrol - uygulama anında açılır

### 2. 🚨 Zorunlu Güncelleme
- **Kapatılamaz Dialog:** Kullanıcı geri tuşu ile kapatamaz
- **Versiyon Kontrolü:** Mevcut versiyon != GitHub versiyonu ise zorunlu güncelleme
- **Uygulama Kilitleme:** Güncelleme yapmadan hiçbir özellik kullanılamaz
- **Anında Tespit:** Uygulama açılır açılmaz kontrol edilir

### 3. 📱 Her Ekranda Kontrol
- **Splash Screen:** İlk açılışta kontrol
- **Login Screen:** 2 saniye sonra arka planda kontrol
- **Home Screen:** 1 saniye sonra arka planda kontrol
- **Manuel Kontrol:** Kullanıcı buton ile manuel kontrol edebilir

## 🔧 Teknik Detaylar

### UpdateService Yapısı

```dart
class UpdateService {
  // Cache süresi: 5 dakika
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  // Hızlı kontrol - cache veya API
  Future<Map<String, dynamic>?> checkForUpdate({bool forceCheck = false})
  
  // Güncelleme indir
  Future<String?> downloadUpdate(String url, Function(double) onProgress)
  
  // APK'yı yükle
  Future<bool> installApk(String filePath)
}
```

### Güncelleme Bilgisi Formatı

```dart
{
  'version': '1.0.5',              // Yeni versiyon
  'currentVersion': '1.0.4',       // Mevcut versiyon
  'downloadUrl': 'https://...',    // APK indirme linki
  'releaseNotes': 'Yenilikler...', // Sürüm notları
  'publishedAt': '2024-10-07...',  // Yayın tarihi
  'isMandatory': true,             // ⭐ ZORUNLU MU?
  'fileSize': 52428800,            // Dosya boyutu (byte)
}
```

### Cache Mekanizması

1. **İlk Kontrol:** GitHub API'den veri al, cache'e kaydet
2. **Sonraki Kontroller:** Cache'den oku (5 dakika geçerliliği var)
3. **Cache Geçersiz:** 5 dakika sonra tekrar API'den al
4. **Hata Durumu:** API hata verirse cache'den devam et

### Performans Optimizasyonları

```dart
// ✅ Timeout ile hızlı yanıt
final response = await http.get(url).timeout(
  const Duration(seconds: 5),
  onTimeout: () => throw TimeoutException('Timeout'),
);

// ✅ Cache kontrolü - gereksiz API çağrısı yok
if (!forceCheck) {
  final cached = await _getCachedUpdate();
  if (cached != null) return cached;
}

// ✅ Arka planda kontrol - UI bloklamaz
await Future.delayed(const Duration(seconds: 2));
final updateInfo = await _updateService.checkForUpdate();
```

## 📦 Dialog Yapısı

### MandatoryUpdateDialog
- **Kapatılamaz:** `barrierDismissible: false`
- **Geri tuşu devre dışı:** `PopScope(canPop: false)`
- **2 Seçenek:**
  1. **Güncelle:** İndirme başlatır ve kurulum ekranı açar
  2. **Çıkış:** Uygulamadan tamamen çıkar

### Görsel Özellikler
- 🎨 Gradient kırmızı-turuncu arka plan
- ⚠️ Uyarı ikonu
- 📊 İndirme progress bar
- 📝 Versiyon bilgileri
- 📦 Dosya boyutu
- 📄 Sürüm notları

## 🔄 Kullanım Senaryoları

### Senaryo 1: İlk Açılış - Güncelleme Var
```
1. Kullanıcı uygulamayı açar
2. Splash screen görünür (~300ms)
3. Arka planda güncelleme kontrolü yapılır
4. Güncelleme tespit edilir
5. ❌ ZORUNLU GÜNCELLEME DİALOG açılır
6. Kullanıcı güncellemeden uygulamaya giremez
```

### Senaryo 2: Login Ekranında - Güncelleme Geldi
```
1. Kullanıcı login ekranında
2. 2 saniye sonra arka planda kontrol
3. Yeni güncelleme yayınlandı
4. ❌ ZORUNLU GÜNCELLEME DİALOG açılır
5. Cache'e kaydedilir (5 dakika geçerli)
```

### Senaryo 3: Home Ekranında - Cache Kullanımı
```
1. Kullanıcı home screen'de
2. 1 saniye sonra arka planda kontrol
3. Cache'de güncelleme bilgisi var (5 dk geçerli)
4. API'ye istek atılmaz - cache kullanılır
5. ❌ ZORUNLU GÜNCELLEME DİALOG açılır
```

### Senaryo 4: Manuel Kontrol
```
1. Kullanıcı güncelleme butonuna basar
2. forceCheck=true ile API'den kontrol
3. Cache bypass edilir
4. Güncel ise "Uygulamanız güncel" mesajı
5. Güncelleme varsa dialog açılır
```

## 📱 Ekran Akışı

```
main() 
  ↓
SplashScreen (300ms)
  ↓
checkForUpdate() [Cache veya API]
  ↓
  ├─ Güncelleme VAR → MandatoryUpdateDialog (ZORUNLU)
  │                      ↓
  │                   ├─ Güncelle → Download → Install
  │                   └─ Çıkış → App kapatılır
  │
  └─ Güncelleme YOK → LoginScreen / HomeScreen
                        ↓
                     Arka planda periyodik kontrol (Cache'li)
```

## 🎯 Kullanıcı Deneyimi

### Önceki Sistem (❌)
- Her açılışta 2-3 saniye bekleme
- Opsiyonel güncelleme - kullanıcı atlayabiliyor
- Performans sorunu
- Eski versiyonlar kullanılabiliyor

### Yeni Sistem (✅)
- Anında açılır (~300ms)
- Cache ile hızlı kontrol
- Zorunlu güncelleme - kimse eski versiyon kullanamaz
- Performans etkisi YOK
- Her ekranda arka planda kontrol

## 📊 Performans Metrikleri

| Metrik | Değer |
|--------|-------|
| İlk kontrol süresi | 1-5 saniye (API'ye bağlı) |
| Cache kontrol süresi | <50ms |
| Cache geçerlilik | 5 dakika |
| Timeout süresi | 5 saniye |
| UI beklemesi | 0ms (arka planda) |

## 🔐 Güvenlik

- API anahtarı gerektirmez (public GitHub API)
- HTTPS ile güvenli bağlantı
- SHA-256 hash ile dosya doğrulama (opsiyonel)
- APK signature doğrulaması Android tarafından

## 🧪 Test Senaryoları

### 1. Güncelleme Yayınla
```bash
# GitHub'da yeni release oluştur
# Tag: v1.0.5
# APK dosyasını ekle
# Uygulama otomatik tespit eder
```

### 2. Cache Testi
```
1. İlk kontrol → API'den al (5 saniye)
2. 2 dakika sonra → Cache'den al (<50ms)
3. 6 dakika sonra → Tekrar API'den al
```

### 3. Offline Test
```
1. İnterneti kapat
2. Uygulamayı aç
3. Cache varsa gösterir, yoksa sessizce devam
4. Kullanıcı deneyimi aksama YOK
```

### 4. Zorunlu Güncelleme Testi
```
1. GitHub'da v1.0.5 yayınla
2. Uygulamayı aç (v1.0.4)
3. ❌ Zorunlu güncelleme dialog açılır
4. Geri tuşu çalışmaz
5. Sadece "Güncelle" veya "Çıkış" seçenekleri
```

## 📝 Yapılacaklar (Gelecek)

- [ ] Background service ile periyodik kontrol (her 30 dakikada)
- [ ] Push notification ile güncelleme bildirimi
- [ ] In-app güncelleme (Google Play Core Library)
- [ ] Delta güncelleme (sadece değişen dosyalar)
- [ ] Rollback özelliği (eski versiyona dön)
- [ ] A/B testing (bazı kullanıcılara önce ver)

## 🐛 Bilinen Sorunlar

1. **GitHub API rate limit:** Saatte 60 istek sınırı var (cache ile çözülüyor)
2. **APK boyutu:** Büyük APK'lar yavaş indirilir (progress bar ile kullanıcı bilgilendiriliyor)
3. **Android 10+ izinleri:** Bazı cihazlarda manuel izin gerekebilir

## 💡 Öneriler

1. **Versiyonlama:** Semantic versioning kullan (v1.0.0)
2. **Release Notes:** Her güncellemeye açıklama yaz
3. **Test:** Her release'den önce farklı Android versiyonlarında test et
4. **Beta Program:** Kritik güncellemeleri önce beta'da dene
5. **Rollback Planı:** Sorun çıkarsa hızlıca eski versiyona dön

## 📞 Destek

Sorun yaşarsanız:
1. Debug log'larını kontrol edin (`debugPrint` mesajları)
2. GitHub release'i kontrol edin (APK var mı?)
3. İnternet bağlantısını kontrol edin
4. Cache'i temizleyin (uygulamayı sil-yükle)
