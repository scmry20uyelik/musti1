# Mirmir App - Almanca Öğrenme Uygulaması

**Basamak 1 Tamamlandı ✅**
**Basamak 2 Tamamlandı ✅**

Premium Material 3 tabanlı, Riverpod state management ve Clean Architecture prensiplerine göre yapılandırılmış bir Almanca öğrenme uygulaması.

## 🏗️ Proje Yapısı

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # Uygulama sabitleri
│   ├── errors/
│   │   └── exceptions.dart            # Custom exception sınıfları
│   ├── network/
│   │   └── gemini_api_service.dart    # Gemini API servis taslağı
│   └── theme/
│       └── app_theme.dart             # Material 3 tema tanımları
├── features/
│   ├── auth/
│   │   ├── data/                      # Data layer
│   │   ├── domain/                    # Domain layer
│   │   └── presentation/              # Presentation layer
│   └── home/
│       └── presentation/
│           ├── pages/
│           │   └── main_screen.dart   # Ana ekran
│           ├── providers/
│           │   └── selected_topic_provider.dart  # State management
│           └── widgets/
│               └── custom_drawer.dart # Premium navigasyon menüsü
├── product/
│   ├── components/                    # Reusable components
│   └── models/                        # Data models
└── main.dart                          # App entry point
```

## 🎨 Tema Özellikleri

### Renkler
- **Primary:** #089992 (Derin Mavi/İndigo)
- **Accent:** #c22382 (Pembe/Magenta)
- **Background:** #9fcbf7 (Açık Gri)
- **Success:** #012e26 (Turkuaz)

### Tipografi
- **Başlıklar:** Roboto Slab (Premium, serif görünüm)
- **Gövde Metinleri:** Lato (Modern, okunabilir)

### UI Özellikleri
- Material 3 standartları
- Rounded corners (12dp)
- Minimalist padding
- Dark/Light tema desteği

## 📦 Kurulu Paketler

### Production Dependencies
- `flutter_riverpod: ^2.6.1` - State management
- `supabase_flutter: ^2.12.0` - Backend & Database
- `google_fonts: ^6.3.3` - Tipografi
- `flutter_svg: ^2.2.3` - SVG desteği

### Development Dependencies
- `build_runner: ^2.5.4` - Code generation
- `freezed: ^2.5.8` - Immutable model generator
- `json_serializable: ^6.9.5` - JSON serialization
- `freezed_annotation: ^2.4.4` - Freezed annotations

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler
- Flutter SDK 3.38.6+
- Dart 3.10.7+
- Android Studio (Android için)
- Xcode (iOS için)

### Paketleri Yükle
```bash
flutter pub get
```

### Uygulamayı Çalıştır
```bash
flutter run
```

### Build Runner (Gelecekte kullanılacak)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📱 Desteklenen Platformlar
- ✅ Android
- ✅ iOS
- ⏳ Web (Planlı)
- ⏳ Desktop (Planlı)

## ✨ Basamak 2: Navigasyon ve UI İskeleti

### Tamamlanan Özellikler

**1. Ana Ekran (Main Screen)**
- Scaffold yapısı ile tam ekran düzeni
- `resizeToAvoidBottomInset: true` ile klavye yönetimi
- Dinamik AppBar (konu seçimine göre güncellenen başlık)
- Boş durum için premium logo ve mesaj

**2. State Management**
- `SelectedTopic` model (Freezed ile immutable)
- `selectedTopicProvider` - Riverpod StateProvider
- Seçili seviye ve konu takibi

**3. Premium Drawer (Sol Menü)**
- 8 ana seviye kategorisi: A1.1, A1.2, A2.1, A2.2, B1.1, B1.2, B2.1, B2.2
- Her seviyede 10 konu başlığı (toplam 80 konu)
- ExpansionTile ile açılır/kapanır tasarım
- Deep Indigo (#2E3192) arka plan
- Magenta (#EC008C) vurgular
- Seçili konu için checkmark göstergesi

**4. Persistent Chat Bar**
- Alt kısımda sabit sohbet barı
- BackdropFilter ile blur efekti (sigma: 5.0)
- Üst kenarda ince Magenta çizgi
- "Hocam neden?" placeholder
- Modern TextField (border yok)
- Send ikonu ile gönder butonu
- SafeArea ile güvenli alan koruması

**5. Curriculum Data**
- Her seviye için özenle hazırlanmış konu listesi
- A1: Temel tanışma, sayılar, günlük rutinler
- A2: Seyahat, sağlık, iş
- B1: Formal yazışma, ekonomi, politika
- B2: Akademik yazım, kompleks gramer

## 🔜 Sonraki Adımlar (Basamak 3)

1. **Gemini API Entegrasyonu**
   - API key yapılandırması
   - Chat service implementasyonu
   - Konuşma context yönetimi

2. **Test Ekranı**
   - Çoktan seçmeli sorular
   - Cümle tamamlama
   - Kelime eşleştirme
   - İlerleme takibi

3. **Environment Configuration**
   - `.env` dosyası kurulumu
   - Supabase credentials entegrasyonu
   - Güvenli API key yönetimi

4. **Authentication Flow**
   - Google Sign-In implementasyonu
   - Supabase auth entegrasyonu
   - User state management

## 🛠️ Geliştirici Notları

### Clean Architecture Katmanları

**Core Layer:**
- Constants, theme, utilities
- Network services
- Error handling

**Feature Layer:**
- **Data:** Repository implementations, data sources
- **Domain:** Entities, use cases, repository interfaces  
- **Presentation:** UI, state management, widgets

**Product Layer:**
- Shared components
- Common models
- Utilities

### Kod Standartları
- Material 3 kullanımı zorunlu
- Riverpod for state management
- Clean Architecture prensiplerine uygun
- Tüm custom widgetlar `const` constructor kullanmalı
- Freezed ile immutable modeller
- BackdropFilter ile premium blur efektleri

### UI/UX Prensipler
- Tutarlı border radius (12dp - 16dp)
- Premium color scheme (Indigo + Magenta)
- Minimalist ve sade tasarım
- Blur efektleri ile depth hissi
- Responsive ve keyboard-aware layout

## 📝 Lisans
MIT License

---

**Durum:** Ana navigasyon ve UI iskeleti tamamlandı. Gemini API entegrasyonu için hazır. ✅
