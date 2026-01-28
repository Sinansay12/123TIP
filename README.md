# Medical Study App 📚

Tıp fakültesi öğrencileri için kişiselleştirilmiş çalışma ve soru çözme mobil uygulaması.

## 🏗️ Proje Yapısı

```
123TIP/
├── backend/          # FastAPI Backend
│   ├── app/
│   │   ├── main.py           # Ana uygulama
│   │   ├── config.py         # Konfigürasyon
│   │   ├── database.py       # Veritabanı bağlantısı
│   │   ├── models.py         # SQLAlchemy modelleri
│   │   ├── schemas.py        # Pydantic şemaları
│   │   ├── routers/          # API rotaları
│   │   └── services/         # İş mantığı servisleri
│   ├── requirements.txt
│   ├── .env
│   └── run.py                # Sunucu başlatma dosyası
│
└── frontend/         # Flutter Mobile App
    ├── lib/
    │   ├── main.dart
    │   ├── core/             # Router, theme, network
    │   └── features/         # Özellik modülleri
    ├── assets/               # Görseller ve animasyonlar
    └── pubspec.yaml
```

## ✨ Özellikler

- **🔐 Kimlik Doğrulama**: Dönem ve staj grubu seçimi ile kayıt/giriş
- **📄 Doküman Yükleme**: PDF/PPTX dosyalarından otomatik soru üretimi
- **🧠 Akıllı İpuçları**: RAG tabanlı semantik ipuçları (cevabı direkt vermez)
- **📊 7 Gün Mantığı**: Sınava yaklaştıkça zorluk artar
- **📍 Slayda Git**: Yanlış cevaplarda ilgili slayta deep link

## 🚀 Çalıştırma Adımları

### 1. Backend (FastAPI)

```powershell
# Backend dizinine git
cd backend

# Sanal ortam oluştur (ilk kez)
python -m venv venv

# Sanal ortamı aktifleştir
.\venv\Scripts\Activate

# Bağımlılıkları yükle
pip install -r requirements.txt

# .env dosyasını düzenle (API anahtarları vb.)
# DATABASE_URL ve OPENAI_API_KEY ayarlarını güncelle

# Sunucuyu başlat
python run.py
# veya
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Backend şu adreste çalışacak: `http://localhost:8000`
API Docs: `http://localhost:8000/docs`

### 2. PostgreSQL Veritabanı

```powershell
# pgvector eklentisi ile PostgreSQL gerekli
# Docker ile kullanabilirsiniz:
docker run -d --name medical-db \
  -e POSTGRES_USER=user \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=medical_study_db \
  -p 5432:5432 \
  ankane/pgvector
```

### 3. Frontend (Flutter)

```powershell
# Frontend dizinine git
cd frontend

# Bağımlılıkları yükle
flutter pub get

# Android için
flutter run -d android

# iOS için
flutter run -d ios

# Web için
flutter run -d chrome
```

## ⚙️ Konfigürasyon

### Backend `.env` Dosyası

```env
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/medical_study_db
OPENAI_API_KEY=sk-your-openai-api-key
JWT_SECRET_KEY=your-super-secret-jwt-key
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
UPLOAD_DIR=./uploads
```

### Frontend API URL

`frontend/lib/core/network/api_client.dart` dosyasında:
```dart
const String baseUrl = 'http://localhost:8000/api/v1';
// Android emülatör için: 'http://10.0.2.2:8000/api/v1'
```

## 📝 API Endpoints

| Endpoint | Method | Açıklama |
|----------|--------|----------|
| `/api/v1/auth/register` | POST | Kullanıcı kaydı |
| `/api/v1/auth/login` | POST | Giriş ve JWT token |
| `/api/v1/exams/` | POST | Sınav tarihi ekle |
| `/api/v1/exams/daily` | GET | Günlük soru karışımı |
| `/api/v1/questions/{id}/hint` | POST | Akıllı ipucu al |
| `/api/v1/documents/upload` | POST | Doküman yükle |

## 🛠️ Gereksinimler

### Backend
- Python 3.11+
- PostgreSQL 15+ (pgvector eklentisi ile)
- OpenAI API anahtarı

### Frontend
- Flutter 3.5.0+
- Dart 3.5.0+
- Android SDK / Xcode (mobil için)

## 📱 Ekran Görüntüleri

- **Onboarding**: Dönem ve grup seçimi
- **Login/Register**: Kullanıcı kimlik doğrulama
- **Dashboard**: Günlük mix ve sınav geri sayımı
- **Quiz**: Soru çözme ve akıllı ipuçları
- **PDF Viewer**: "Slayda Git" özelliği

## 📄 Lisans

Bu proje eğitim amaçlı geliştirilmiştir.
