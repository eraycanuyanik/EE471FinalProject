# Erişim — ML Servisi

Üç modülün ortak PyTorch + FastAPI servisi.

## Kurulum
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

## Duyar (ses sınıflandırma) — çalışan

```bash
# 1) Eğit (sentetik veri — pipeline testi için)
python -m modules.duyar.train --epochs 8 --synthetic

# 1b) Gerçek veriyle eğit: data/<sınıf>/*.wav koy, sonra:
#     python -m modules.duyar.train --epochs 20 --data data

# 2) Tek dosya tahmini
python -m modules.duyar.infer /yol/ses.wav
```

Sınıflar: `sessizlik, siren, kapi_zili, bebek_aglamasi, alarm, kapi_vurma, isim_cagirma, kopek_havlamasi`

> Gerçek veri önerisi: **ESC-50**, **UrbanSound8K** (siren, bebek, havlama vb.) +
> kendi kaydettiğin Türkçe isim seslenmeleri (`isim_cagirma` sınıfı için).

## Servisi çalıştır
```bash
uvicorn app:app --reload
# Swagger arayüzü: http://127.0.0.1:8000/docs
```

### Uç noktalar
| Method | Yol | Açıklama |
|--------|-----|----------|
| GET  | `/health` | servis + modül durumu |
| POST | `/duyar/predict` | `{audio_b64}` → `{label, confidence, critical, all_scores}` |
| GET  | `/duyar/labels` | sınıf listesi |
| POST | `/sesver/predict` | `{landmarks}` → işaret tahmini (iskelet) |
| POST | `/yanindayim/intent` | `{text}` → niyet (iskelet) |

## Test (geliştirme)
TestClient için: `pip install httpx`

## Notlar
- WAV okuma/yazma standart `wave` modülüyle yapılır (`modules/duyar/wav_io.py`) —
  torchaudio 2.11'in torchcodec/ffmpeg bağımlılığından kaçınmak için.
- Üretimde Duyar modeli ONNX/TFLite olarak telefona gömülür (bkz. `docs/ARCHITECTURE.md`).
