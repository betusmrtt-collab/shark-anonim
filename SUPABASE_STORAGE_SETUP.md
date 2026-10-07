# Supabase Storage Kurulumu

Bu uygulama kullanıcı içeriklerini (avatar, sesli biyografi, galeri resimleri) Supabase Storage'da saklar. Uygulamanın düzgün çalışması için aşağıdaki bucket'ların oluşturulması **zorunludur**.

## Gerekli Bucket'lar

Supabase Dashboard → Storage → New Bucket'dan aşağıdaki bucket'ları oluşturun:

### 1. avatars (Public)
- **İsim:** `avatars`
- **Public:** ✅ Evet
- **File size limit:** 5 MB
- **Allowed MIME types:** `image/jpeg`, `image/png`, `image/webp`
- **Açıklama:** Kullanıcı profil fotoğrafları

### 2. voice_bios (Public)
- **İsim:** `voice_bios`
- **Public:** ✅ Evet
- **File size limit:** 10 MB
- **Allowed MIME types:** `audio/mp4`, `audio/m4a`, `audio/mpeg`
- **Açıklama:** Sesli biyografi kayıtları

### 3. gallery (Public)
- **İsim:** `gallery`
- **Public:** ✅ Evet
- **File size limit:** 5 MB
- **Allowed MIME types:** `image/jpeg`, `image/png`, `image/webp`
- **Açıklama:** Kullanıcı galeri resimleri

## Hızlı Kurulum (SQL ile)

Alternatif olarak, Supabase SQL Editor'da aşağıdaki komutları çalıştırabilirsiniz:

```sql
-- Bucket'ları oluştur
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('voice_bios', 'voice_bios', true, 10485760, ARRAY['audio/mp4', 'audio/m4a', 'audio/mpeg']),
  ('gallery', 'gallery', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

-- Storage politikalarını ayarla (herkes okuyabilir, sadece sahip yükleyebilir)
CREATE POLICY "Public Access" ON storage.objects
  FOR SELECT USING (bucket_id IN ('avatars', 'voice_bios', 'gallery'));

CREATE POLICY "Authenticated users can upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id IN ('avatars', 'voice_bios', 'gallery') 
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "Users can update own files" ON storage.objects
  FOR UPDATE USING (
    bucket_id IN ('avatars', 'voice_bios', 'gallery')
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete own files" ON storage.objects
  FOR DELETE USING (
    bucket_id IN ('avatars', 'voice_bios', 'gallery')
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
```

## Doğrulama

Kurulumun başarılı olduğunu doğrulamak için:

1. Supabase Dashboard → Storage'a gidin
2. `avatars`, `voice_bios`, `gallery` bucket'larını görmelisiniz
3. Her birinin üzerine tıklayıp Public olduğunu kontrol edin

## Hata Ayıklama

Eğer "**Bucket not found, statusCode: 404**" hatası alıyorsanız:

1. Bucket'ların oluşturulduğunu kontrol edin
2. Bucket isimlerinin doğru olduğunu doğrulayın (küçük harf, tire ile)
3. Public ayarının aktif olduğunu kontrol edin
4. Storage politikalarının doğru şekilde ayarlandığını kontrol edin

## Güvenlik Notları

- Tüm bucket'lar **public** olarak ayarlanmıştır (görüntülemeler için)
- Sadece **authenticated** kullanıcılar dosya yükleyebilir
- Kullanıcılar sadece **kendi dosyalarını** silebilir/güncelleyebilir
- Dosya boyutu limitleri avatar ve galeri için **5 MB**, ses dosyaları için **10 MB**'dir
- MIME type kontrolü ile yalnızca belirtilen dosya tipleri kabul edilir

## İletişim

Sorunlarınız için lütfen teknik ekiple iletişime geçin.
