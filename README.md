# Erişim — Erişilebilirlik Asistanı

> EE471 Final Projesi · Engelliler ve yaşlılar için tek çatı altında üç yapay zekâ modülü

**Erişim**, işitme/konuşma engelli bireyler ve yaşlılar için geliştirilen, üç modülden oluşan
bir mobil erişilebilirlik uygulamasıdır. Üç modül de ortak bir ML servis altyapısını ve
tek bir Flutter mobil kabuğunu paylaşır.

## Modüller

| Modül | Ne yapar | Çekirdek teknoloji | Durum |
|-------|----------|--------------------|-------|
| **SesVer** | Kameradan işaret dilini canlı okur, konuşmaya çevirir. Ters mod: konuşmayı ekranda işaret animasyonuna çevirir. | MediaPipe (el+yüz landmark) + PyTorch sınıflandırıcı + Azure TTS | 🟡 Kamera demo + pipeline |
| **Duyar** | Sürekli dinler; siren, kapı zili, bebek ağlaması, alarm gibi kritik sesleri tanıyıp türüne özel titreşimle uyarır. Konuşmayı/ortam sesini ayırt eder. | PANNs (AudioSet, 527 sınıf) + Flutter mikrofon/titreşim | 🟢 Uçtan uca çalışıyor |
| **Yanındayım** | Yaşlılar için tek-buton sesli asistan: konuşma tanıma, ilaç hatırlatma (bildirim), niyet anlama. | STT + flutter_local_notifications + intent | 🟢 STT + ilaç hatırlatma |

> **Kapsam notu:** Bir ders finali için üç ML-ağır ürünü tam çalışır hale getirmek gerçekçi değil.
> **Duyar** uçtan uca çalışır (ESC-50 gerçek veriyle eğitildi, ~%80 doğruluk). **Yanındayım**
> konuşma tanıma + ilaç hatırlatma ile çalışır. **SesVer** kamera + landmark pipeline'ı kurulu;
> gerçek el landmark'ı (ML Kit/MediaPipe) fiziksel cihaz gerektirir (arm64 iOS simülatöründe
> ML Kit desteklenmez). Bkz. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Proje yapısı

```
finalproject/
├── app/             # Flutter mobil kabuk (3 modül tek uygulamada)
├── ml_service/      # Ortak PyTorch + FastAPI servisi
│   ├── app.py       # API giriş noktası
│   └── modules/
│       ├── duyar/       # ses sınıflandırma (çalışan)
│       ├── sesver/      # işaret dili (iskelet)
│       └── yanindayim/  # yaşlı asistanı (iskelet)
└── docs/            # mimari ve tasarım dökümanları
```

## Hızlı başlangıç (ML servisi)

```bash
cd ml_service
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Duyar modelini sentetik veriyle eğit (demo)
python -m modules.duyar.train --epochs 5 --synthetic

# API'yi başlat
uvicorn app:app --reload
# http://127.0.0.1:8000/docs adresinden test et
```

## Lisans
Eğitim amaçlı — EE471 ders projesi.
