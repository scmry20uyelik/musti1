# Edge Functions Redesign — Gemini Migration

Kapsam
- Mevcut: `ai-chat`, `vocabulary-enricher` (zaten Gemini kullanıyor)
- Eklenecek/Güncellenecek: `adaptive-quiz` (yeni fonksiyon) — Gemini modeline geçiş

Özet hedefler
1. Tüm Groq referanslarını kaldırmak veya Gemini ile değiştirmek.
2. `adaptive-quiz` fonksiyonunu Gemini (`gemini-2.5-flash`) ile yeniden yazmak.
3. Edge Function'larda hata yönetimi, retry (kısa) ve açık JSON şeması sağlamak.
4. Flutter istemcisinde `AiApiService.getAdaptiveQuiz`'i schema ile uyumlu hale getirmek.
5. Unit ve entegrasyon testleri ekleyip CI için hazır hale getirmek.

Adaptive-Quiz API Şeması (Öneri)
```
{
  "quizId": "string",
  "level": "A1.1",
  "topic": "Artikel",
  "questions": [
    {
      "id":"q1",
      "type":"multiple_choice",
      "question":"Metin...",
      "options":[{"id":"a","text":"...","correct":false}, ...],
      "difficulty":1
    }
  ],
  "meta": { "generatedBy":"gemini-2.5-flash", "timestamp":"ISO8601" }
}
```

Güvenlik
- `GEMINI_API_KEY` Supabase secrets olarak saklanacak. Deploy işlemi için robust dokümantasyon eklenecek.

Testler
- Fonksiyon için: birim testi (girdi/çıktı şeması), hata durumları simülasyonu.
- Flutter için: integration test adaptif quiz akışını doğrulayacak.

İş akışı (yüksek seviye)
1. `adaptive-quiz` fonksiyon dosyasını oluştur (Deno/TypeScript) — Gemini çağrısını ekle.
2. Fonksiyon birim testlerini ekle.
3. Flutter `AiApiService` varsa schema doğrulama/yenileme yap.
4. Entegrasyon testlerini çalıştır, hata/edge-case senaryoları ekle.
5. PR hazırla, doküman ve deploy yönergelerini güncelle.

Not: Deploy yapmayı siz tercih ettiniz (ben PR + yönergeleri hazırlarım).