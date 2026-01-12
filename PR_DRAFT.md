# PR: Edge Functions — Gemini Migration & adaptive-quiz addition

## Özet
- Yeni: `adaptive-quiz` Edge Function (Gemini `gemini-2.5-flash`) eklendi.
- Güncelleme: `AiApiService.getAdaptiveQuiz` artık yeni Gemini JSON şemasını destekliyor (geri uyumluluk ile eski `quiz` şekli de destekleniyor).
- Dokümantasyon: `docs/EDGE_FUNCTIONS_REDESIGN.md` ve `SUPABASE_EDGE_FUNCTION_SETUP.md` güncellendi.
- Test: adaptive-quiz fonksiyonu için test scaffold eklendi ve Flutter birim testi `manual_enrich_quiz_test.dart` mevcut davranışını doğruluyor.

## Yapılması gerekenler (deploy / secret)
- Supabase secrets: `GEMINI_API_KEY` eklenmeli.
- Deployment: `supabase functions deploy adaptive-quiz` (ve varsa güncellenen diğer fonksiyonlar).

## Notlar
- `AiApiService` içinde gömülü anonim anahtar kaldırıldı (gizlilik açısından).
- Sunucu tarafı yetkilendirme düzeltildikten sonra fallback davranışı kaldırılabilir.

Lütfen inceleyip onay verin; deploy talimatlarını PR açıklamasına ekleyip hazır hale getireceğim.