# 🔒 Güvenli Gemini API Kurulumu (Supabase Edge Functions)

## Neden Supabase Edge Functions?

✅ **Güvenlik:** API key hiçbir zaman client-side'da olmaz  
✅ **Gizlilik:** Kullanıcılar API key'i göremez  
✅ **Kontrol:** Backend'de rate limiting ve logging yapabilirsiniz  
✅ **Ücretsiz:** Supabase'in ücretsiz planında 500K request/ay  

---

## 📋 Kurulum Adımları

### 1️⃣ Supabase CLI Kurulumu

**Windows için:**
```powershell
# Scoop ile
scoop install supabase

# Veya NPM ile
npm install -g supabase
```

**Kurulumu kontrol edin:**
```bash
supabase --version
```

### 2️⃣ Supabase'e Giriş Yapın

```bash
supabase login
```

Tarayıcı açılacak, Supabase hesabınızla giriş yapın.

### 3️⃣ Projeyi Supabase'e Bağlayın

```bash
cd "C:\Users\Mustafa\Desktop\Mirmir App"
supabase link --project-ref gohrxehnreohljgsxlig
```

### 4️⃣ Gemini API Key Alın

1. https://makersuite.google.com/app/apikey adresine gidin
2. "Create API Key" butonuna tıklayın
3. API key'i kopyalayın (örn: `AIzaSyD...`)

### 5️⃣ Edge Function'a Secret Ekleyin

**Komut satırından:**
```bash
supabase secrets set GEMINI_API_KEY=AIzaSyD_BURAYA_API_KEYINIZI_YAPIŞTIRIN
```

**Veya Supabase Dashboard'dan:**
1. https://supabase.com/dashboard/project/gohrxehnreohljgsxlig sayfasına gidin
2. Sol menüden **"Edge Functions"** → **"Secrets"** sekmesine gidin
3. **"Add new secret"** butonuna tıklayın
4. Name: `GEMINI_API_KEY`
5. Value: API key'inizi yapıştırın
6. **"Save"** butonuna tıklayın

### 6️⃣ Edge Function'ı Deploy Edin

```bash
supabase functions deploy gemini-chat
```

**Başarılı olursa:**
```
Deployed Function gemini-chat version 1.0.0
Function URL: https://gohrxehnreohljgsxlig.supabase.co/functions/v1/gemini-chat
```

---

## ✅ Test Edin

### Terminal'den Test:

```bash
curl -L -X POST 'https://gohrxehnreohljgsxlig.supabase.co/functions/v1/gemini-chat' \
-H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
-H "Content-Type: application/json" \
--data '{"message":"Hallo nasıl söylenir?","userLevel":"A1.1","topic":"Tanışma"}'
```

### Flutter App'ten Test:

```bash
flutter run
```

1. Uygulamayı açın
2. Sol menüden bir konu seçin (örn: A1.1 → Tanışma)
3. Alt chat bar'a "Hallo nasıl söylenir?" yazın
4. Send butonuna basın
5. Cevap gelecek! 🎉

---

## 🔍 Hata Ayıklama

### Log'ları Görüntüleme:

```bash
supabase functions logs gemini-chat
```

### Function'ı Lokal Test Etme:

```bash
supabase functions serve gemini-chat
```

---

## 📁 Dosya Yapısı

```
Mirmir App/
├── supabase/
│   └── functions/
│       └── gemini-chat/
│           └── index.ts          ← Edge Function kodu
├── lib/
│   └── core/
│       └── network/
│           └── gemini_api_service.dart  ← Flutter client
```

---

## 🎯 Özet

✅ **API Key:** Supabase Edge Function'da güvenli  
✅ **Flutter App:** Edge Function'ı çağırıyor  
✅ **Güvenlik:** Client-side'da hiçbir secret yok  
✅ **Test:** `flutter run` ile çalışıyor  

---

## 🆘 Sorun mu Yaşıyorsunuz?

**Edge Function deploy olmadıysa:**
```bash
# CLI'ın doğru versiyonda olduğunu kontrol edin
supabase --version

# Tekrar login deneyin
supabase logout
supabase login
```

**Secret ekleyemediyseniz:**
- Dashboard'dan manuel ekleyin: https://supabase.com/dashboard/project/gohrxehnreohljgsxlig/settings/functions

**Function çalışmıyorsa:**
```bash
# Log'lara bakın
supabase functions logs gemini-chat --follow
```

---

**Artık API key'iniz güvenli! 🔒**
