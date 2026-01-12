---
name: 'Server secret / Gemini key missing'
about: 'Server-side issue: Supabase Edge Function Gemini API key missing or invalid (causes 500 Unauthorized)'
---

**Özet**
Sunucu tarafı `adaptive-quiz` ve diğer Gemini kullanan Edge Function'lar (ör. `ai-chat`, `vocabulary-enricher`) için `GEMINI_API_KEY` secret'ı veya ilgili yetkilendirme düzgün ayarlı değil; bu durum 500 ve 'Unauthorized' hatalarına yol açıyor.

**Yapılması gerekenler**
1. Supabase projesinde `GEMINI_API_KEY` secret'ını ekle: `supabase secrets set GEMINI_API_KEY=<key>`
2. Edge Function'ları yeniden deploy et (`supabase functions deploy <name>`).
3. Fonksiyon loglarını kontrol ederek 200 döndüğünü doğrula: `supabase functions logs <name> --follow`.
4. (Opsiyonel) CI/CD pipeline'ına secrets eklenip deploy adımı otomatikleştirilsin.

**Etkilenen Fonksiyonlar**
- ai-chat
- vocabulary-enricher
- adaptive-quiz (yeni) — eğer deploy edildiyse

**Önem seviyesi**: Yüksek

**Atanacak kişi**: @ops veya proje sahibi

**Notlar**
Ben client tarafında geri kazanım (fallback) ekledim; fakat gerçek üretim dataları için sunucu secret'ı düzeltilmeli.