-- Users tablosuna INSERT politikası ekle
CREATE POLICY "Users can insert own profile" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Alternatif: Eğer yukarıdaki çalışmazsa, authenticated kullanıcıların insert yapmasına izin ver
-- CREATE POLICY "Authenticated users can insert profile" ON users
--   FOR INSERT WITH CHECK (auth.role() = 'authenticated');
