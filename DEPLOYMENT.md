# 🚀 Render + UptimeRobot Deployment Rehberi

## Adım 1: GitHub'a Push

```bash
cd c:\123TIP
git add .
git commit -m "Add Render deployment config"
git push origin main
```

## Adım 2: Render Kurulumu

1. [render.com](https://render.com) adresine git ve GitHub ile kayıt ol
2. **New → Web Service** tıkla
3. GitHub reponuzu bağla (`123TIP`)
4. **Root Directory**: `backend` yaz
5. Ayarları kontrol et:
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
6. **Environment Variables** bölümünde:
   - `GEMINI_API_KEY` = (Google AI Studio'dan aldığın API key)
7. **Create Web Service** tıkla

⏳ Deploy 3-5 dakika sürecek. Bitince URL alacaksın: `https://123tip-backend.onrender.com`

## Adım 3: UptimeRobot Kurulumu (Uyku Önleme)

1. [uptimerobot.com](https://uptimerobot.com) adresine git ve ücretsiz kayıt ol
2. **Add New Monitor** tıkla
3. Ayarlar:
   - **Monitor Type**: HTTP(s)
   - **Friendly Name**: 123TIP Backend
   - **URL**: `https://123tip-backend.onrender.com/health`
   - **Monitoring Interval**: 5 minutes
4. **Create Monitor** tıkla

✅ **Tamamlandı!** Artık sunucu her 5 dakikada ping alacak ve hiç uyumayacak.

## ⚠️ Önemli Notlar

- Render ücretsiz planda aylık **750 saat** limit var (1 ay = ~720 saat, yeterli)
- Flutter uygulamasında API URL'ini güncelle: `https://123tip-backend.onrender.com/api/v1`
