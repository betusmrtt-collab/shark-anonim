-- Profil alanlarını users tablosuna ekle
ALTER TABLE users
ADD COLUMN IF NOT EXISTS bio TEXT,
ADD COLUMN IF NOT EXISTS voice_bio_url TEXT,
ADD COLUMN IF NOT EXISTS gender TEXT DEFAULT 'unspecified',
ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

-- Galeri resimleri için yeni tablo
CREATE TABLE IF NOT EXISTS user_gallery (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- İndeks
CREATE INDEX IF NOT EXISTS idx_user_gallery_user_id ON user_gallery(user_id);
CREATE INDEX IF NOT EXISTS idx_user_gallery_order ON user_gallery(user_id, display_order);

-- Row Level Security
ALTER TABLE user_gallery ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view gallery images" ON user_gallery
  FOR SELECT USING (true);

CREATE POLICY "Users can insert own gallery images" ON user_gallery
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own gallery images" ON user_gallery
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own gallery images" ON user_gallery
  FOR DELETE USING (auth.uid() = user_id);
