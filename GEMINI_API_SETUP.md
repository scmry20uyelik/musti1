# 🔑 Google Gemini API Key Nasıl Alınır?

## Adım 1: Google AI Studio'ya Git

1. Tarayıcınızda şu adresi açın: **https://makersuite.google.com/app/apikey**
2. Google hesabınızla giriş yapın

## Adım 2: API Key Oluştur

1. **"Create API Key"** butonuna tıklayın
2. Bir proje seçin veya yeni proje oluşturun
3. API key otomatik olarak oluşturulacak

## Adım 3: API Key'i Kopyala

1. Oluşturulan API key'i kopyalayın (örnek: `AIzaSyD...`)
2. **ÖNEMLİ:** Bu key'i güvenli bir yerde saklayın!

## Adım 4: Projeye Ekle

### Yöntem 1: app_constants.dart (Test için)

`lib/core/constants/app_constants.dart` dosyasını açın:

```dart
static const String geminiApiKey = 'AIzaSyD...'; // Buraya yapıştır
```

### Yöntem 2: .env dosyası (Üretim için - Önerilen)

1. Proje klasöründe `.env` dosyası oluşturun
2. İçine şunu yazın:
```
GEMINI_API_KEY=AIzaSyD...
```

## Adım 5: Test Et

```dart
final service = GeminiApiService.instance;
final response = await service.sendMessage('Merhaba, Almanca öğrenmek istiyorum');
print(response);
```

## ⚠️ Güvenlik Notları

- API key'inizi **asla** Git'e commit etmeyin
- `.env` dosyasını `.gitignore`'a ekleyin
- API key'i paylaşmayın
- Üretim ortamında environment variables kullanın

## 📊 API Limitleri (Ücretsiz)

- **60 request / dakika**
- **1500 request / gün**
- **32,000 token / request**

## 🔗 Faydalı Linkler

- Google AI Studio: https://makersuite.google.com/
- API Dokümantasyonu: https://ai.google.dev/docs
- Dart Package: https://pub.dev/packages/google_generative_ai

---

**Not:** API key aldıktan sonra `app_constants.dart` dosyasındaki `geminiApiKey` değişkenini güncelleyin!
